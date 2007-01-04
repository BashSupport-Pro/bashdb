;;; bashdb.el --- BASH Debugger mode via GUD and bashdb
;;; $Id: bashdb.el,v 1.18 2007/01/04 04:26:45 rockyb Exp $

;; Copyright (C) 2002, 2006 Rocky Bernstein (rocky@panix.com) 
;;                    and Masatake YAMATO (jet@gyve.org)

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Commentary:
;; 1. Add
;;
;; (autoload 'bashdb "bashdb" "BASH Debugger mode via GUD and bashdb" t)
;;
;; to your .emacs file.
;; 2. Do M-x bashdb

;; Codes:
(require 'gud)
;; ======================================================================
;; bashdb functions

;;; History of argument lists passed to bashdb.
(defvar gud-bashdb-history nil)

;; The debugger outputs program-location lines that look like this:
;;   (/etc/init.d/network:14):
(defconst gud-bashdb-marker-regexp
  "^(\\(\\(?:[a-zA-Z]:\\)?[-a-zA-Z0-9_/.\\\\]+\\):[ \t]?\\(.*\n\\)"
  "Regular expression used to find a file location given by pydb.

Program-location lines look like this:
   (/etc/init.d/network:39):
or MS Windows:
   (c:\\mydirectory\\gcd.sh:10):
")
(defconst gud-bashdb-marker-regexp-file-group 1
  "Group position in gud-pydb-marker-regexp that matches the file name.")
(defconst gud-bashdb-marker-regexp-line-group 2
  "Group position in gud-pydb-marker-regexp that matches the line number.")

;; Convert a command line as would be typed normally to run a script
;; into one that invokes an Emacs-enabled debugging session.
;; "--debugger" in inserted as the first switch, unless the 
;; command is bashdb which doesn't need and can't parse --debugger.
;; Note: bashdb will be fixed up so that it *does* bass --debugger
;; eventually.

(defun gud-bashdb-massage-args (file args)
  (let* ((new-args (list "--debugger"))
	 (seen-e nil)
	 (shift (lambda ()
		  (setq new-args (cons (car args) new-args))
		  (setq args (cdr args)))))

    ; If we are invoking using the bashdb command, no need to add
    ; --debugger. '^\S ' means non-whitespace at the beginning of a
    ; line and '\s ' means "whitespace"
    (if (string-match "^\\S bashdb\\s " command-line) 
	args
    
      ;; Pass all switches and -e scripts through.
      (while (and args
		  (string-match "^-" (car args))
		  (not (equal "-" (car args)))
		  (not (equal "--" (car args))))
	(funcall shift))
      
      (if (or (not args)
	      (string-match "^-" (car args)))
	  (error "Can't use stdin as the script to debug"))
      ;; This is the program name.
      (funcall shift)
      
      (while args
	(funcall shift))
      
      (nreverse new-args))))

;; There's no guarantee that Emacs will hand the filter the entire
;; marker at once; it could be broken up across several strings.  We
;; might even receive a big chunk with several markers in it.  If we
;; receive a chunk of text which looks like it might contain the
;; beginning of a marker, we save it here between calls to the
;; filter.
(defun gud-bashdb-marker-filter (string)
  (setq gud-marker-acc (concat gud-marker-acc string))
  (let ((output ""))

    ;; Process all the complete markers in this chunk.
    (while (string-match gud-bashdb-marker-regexp gud-marker-acc)
      (setq

       ;; Extract the frame position from the marker.
       gud-last-frame
       (cons (substring gud-marker-acc 
			(match-beginning gud-bashdb-marker-regexp-file-group) 
			(match-end gud-bashdb-marker-regexp-file-group))
	     (string-to-int 
	      (substring gud-marker-acc
			 (match-beginning gud-bashdb-marker-regexp-line-group)
			 (match-end gud-bashdb-marker-regexp-line-group))))

       ;; Append any text before the marker to the output we're going
       ;; to return - we don't include the marker in this text.
       output (concat output
		      (substring gud-marker-acc 0 (match-beginning 0)))

       ;; Set the accumulator to the remaining text.
       gud-marker-acc (substring gud-marker-acc (match-end 0))))

    ;; Does the remaining text look like it might end with the
    ;; beginning of another marker?  If it does, then keep it in
    ;; gud-marker-acc until we receive the rest of it.  Since we
    ;; know the full marker regexp above failed, it's pretty simple to
    ;; test for marker starts.
    (if (string-match "\032.*\\'" gud-marker-acc)
	(progn
	  ;; Everything before the potential marker start can be output.
	  (setq output (concat output (substring gud-marker-acc
						 0 (match-beginning 0))))

	  ;; Everything after, we save, to combine with later input.
	  (setq gud-marker-acc
		(substring gud-marker-acc (match-beginning 0))))

      (setq output (concat output gud-marker-acc)
	    gud-marker-acc ""))

    output))

(defun gud-bashdb-find-file (f)
  (save-excursion
    (let ((buf (find-file-noselect f 'nowarn)))
      (set-buffer buf)
      buf)))

(defcustom gud-bashdb-command-name "bash"
  "File name for executing bash debugger."
  :type 'string
  :group 'gud)

;;;###autoload
(defun bashdb (command-line)
  "Run bashdb on program FILE in buffer *gud-FILE*.
The directory containing FILE becomes the initial working directory
and source-file directory for your debugger."
  (interactive
   (list (read-from-minibuffer "Run bashdb (like this): "
			       (if (consp gud-bashdb-history)
				   (car gud-bashdb-history)
				 (concat gud-bashdb-command-name
					 " "))
			       gud-minibuffer-local-map nil
			       '(gud-bashdb-history . 1))))

  (gud-common-init command-line 'gud-bashdb-massage-args
		   'gud-bashdb-marker-filter 'gud-bashdb-find-file)

  (set (make-local-variable 'gud-minor-mode) 'bashdb)

  (gud-def gud-args   "info args"     "a"
	   "Show arguments of the current stack frame.")
  (gud-def gud-break  "break %f:%l" "\C-b"
	   "Set breakpoint at the current line.")
  (gud-def gud-cont   "continue"   "\C-r" 
	   "Continue with display.")
  (gud-def gud-down   "down %p"     ">"
	   "Down N stack frames (numeric arg).")
  (gud-def gud-finish "finish"      "f\C-f"
	   "Finish executing current function.")
  (gud-def gud-linetrace "toggle"    "t"
	   "Toggle line tracing.")
  (gud-def gud-next   "next %p"     "\C-n"
	   "Step one line (skip functions).")
  (gud-def gud-print  "p %e"        "\C-p"
	   "Evaluate bash expression at point.")
  (gud-def gud-remove "clear %f:%l" "\C-d"
	   "Remove breakpoint at current line")
  (gud-def gud-run    "run"       "R"
	   "Restart the Bash script.")
  (gud-def gud-statement "eval %e" "\C-e"
	   "Execute Bash statement at point.")
  (gud-def gud-step   "step %p"       "\C-s"
	   "Step one source line with display.")
  (gud-def gud-tbreak "tbreak %f:%l"  "\C-t"
	   "Set temporary breakpoint at current line.")
  (gud-def gud-up     "up %p"
	   "<" "Up N stack frames (numeric arg).")
  (gud-def gud-where   "where"
	   "T" "Show stack trace.")

  ;; Update GUD menu bar
  (define-key gud-menu-map [args]      '("Show arguments of current stack" . 
					 gud-args))
  (define-key gud-menu-map [down]      '("Down Stack" . gud-down))
  (define-key gud-menu-map [eval]      '("Execute Bash statement at point" 
					 . gud-statement))
  (define-key gud-menu-map [finish]    '("Finish Function" . gud-finish))
  (define-key gud-menu-map [linetrace] '("Toggle line tracing" . 
					 gud-linetrace))
  (define-key gud-menu-map [run]       '("Restart the Bash Script" . 
					 gud-run))
  (define-key gud-menu-map [stepi]     nil)
  (define-key gud-menu-map [tbreak]    nil)
  (define-key gud-menu-map [up]        '("Up Stack" . gud-up))
  (define-key gud-menu-map [where]     '("Show stack trace" . gud-where))

  (local-set-key "\C-i" 'gud-gdb-complete-command)

  (local-set-key [menu-bar debug tbreak] 
		 '("Temporary Breakpoint" . gud-tbreak))
  (local-set-key [menu-bar debug finish] '("Finish Function" . gud-finish))
  (local-set-key [menu-bar debug up] '("Up Stack" . gud-up))
  (local-set-key [menu-bar debug down] '("Down Stack" . gud-down))

  (setq comint-prompt-regexp "^bashdb<+(*[0-9]*)*>+ ")
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'bashdb-mode-hook)
  )

(provide 'bashdb)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; bashdbtrack --- tracking bashdb debugger in an Emacs shell window
;;; Modified from  python-mode in particular the part:
;; pdbtrack support contributed by Ken Manheimer, April 2001.

;;; Code:

(require 'comint)
(require 'custom)
(require 'cl)
(require 'compile)
(require 'shell)

(defgroup bashdbtrack nil
  "Bashdb file tracking by watching the prompt."
  :prefix "bashdb-bashdbtrack-"
  :group 'shell)


;; user definable variables
;; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

(defcustom bashdb-bashdbtrack-do-tracking-p t
  "*Controls whether the bashdbtrack feature is enabled or not.
When non-nil, bashdbtrack is enabled in all comint-based buffers,
e.g. shell buffers and the *Python* buffer.  When using bashdb to debug a
Python program, bashdbtrack notices the bashdb prompt and displays the
source file and line that the program is stopped at, much the same way
as gud-mode does for debugging C programs with gdb."
  :type 'boolean
  :group 'bashdb)
(make-variable-buffer-local 'bashdb-bashdbtrack-do-tracking-p)

(defcustom bashdb-bashdbtrack-minor-mode-string " BASHDB"
  "*String to use in the minor mode list when bashdbtrack is enabled."
  :type 'string
  :group 'bashdb)

(defcustom bashdb-temp-directory
  (let ((ok '(lambda (x)
	       (and x
		    (setq x (expand-file-name x)) ; always true
		    (file-directory-p x)
		    (file-writable-p x)
		    x))))
    (or (funcall ok (getenv "TMPDIR"))
	(funcall ok "/usr/tmp")
	(funcall ok "/tmp")
	(funcall ok "/var/tmp")
	(funcall ok  ".")
	(error
	 "Couldn't find a usable temp directory -- set `bashdb-temp-directory'")))
  "*Directory used for temporary files created by a *Python* process.
By default, the first directory from this list that exists and that you
can write into: the value (if any) of the environment variable TMPDIR,
/usr/tmp, /tmp, /var/tmp, or the current directory."
  :type 'string
  :group 'bashdb)


;; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;; NO USER DEFINABLE VARIABLES BEYOND THIS POINT

;; have to bind bashdb-file-queue before installing the kill-emacs-hook
(defvar bashdb-file-queue nil
  "Queue of Makefile temp files awaiting execution.
Currently-active file is at the head of the list.")

(defvar bashdb-bashdbtrack-is-tracking-p t)


;; Constants

(defconst bashdb-position-re 
  "\\(^\\|\n\\)(\\([^:]+\\):\\([0-9]*\\)).*\n"
  "Regular expression for a bashdb position")

(defconst bashdb-marker-regexp-file-group 2
  "Group position in bashdb-postiion-re that matches the file name.")

(defconst bashdb-marker-regexp-line-group 3
  "Group position in bashdb-position-re that matches the line number.")



(defconst bashdb-traceback-line-re
  "^#[0-9]+[ \t]+\\((\\([a-zA-Z-.]+\\) at (\\(\\([a-zA-Z]:\\)?[^:\n]*\\):\\([0-9]*\\)).*\n"
  "Regular expression that describes tracebacks.")

;; bashdbtrack contants
(defconst bashdb-bashdbtrack-stack-entry-regexp
  "^=>#[0-9]+[ \t]+\\((\\([a-zA-Z-.]+\\) at (\\(\\([a-zA-Z]:\\)?[^:\n]*\\):\\([0-9]*\\)).*\n"
  "Regular expression bashdbtrack uses to find a stack trace entry.")

(defconst bashdb-bashdbtrack-input-prompt "\nbashdb<+.*>+ "
  "Regular expression bashdbtrack uses to recognize a bashdb prompt.")

(defconst bashdb-bashdbtrack-track-range 10000
  "Max number of characters from end of buffer to search for stack entry.")


;; Utilities
(defmacro bashdb-safe (&rest body)
  "Safely execute BODY, return nil if an error occurred."
  (` (condition-case nil
	 (progn (,@ body))
       (error nil))))


;;;###autoload

(defun bashdb-bashdbtrack-overlay-arrow (activation)
  "Activate or de arrow at beginning-of-line in current buffer."
  ;; This was derived/simplified from edebug-overlay-arrow
  (cond (activation
	 (setq overlay-arrow-position (make-marker))
	 (setq overlay-arrow-string "=>")
	 (set-marker overlay-arrow-position (point) (current-buffer))
	 (setq bashdb-bashdbtrack-is-tracking-p t))
	(bashdb-bashdbtrack-is-tracking-p
	 (setq overlay-arrow-position nil)
	 (setq bashdb-bashdbtrack-is-tracking-p nil))
	))

(defun bashdb-bashdbtrack-track-stack-file (text)
  "Show the file indicated by the bashdb stack entry line, in a separate window.
Activity is disabled if the buffer-local variable
`bashdb-bashdbtrack-do-tracking-p' is nil.

We depend on the bashdb input prompt matching `bashdb-bashdbtrack-input-prompt'
at the beginning of the line.
" 
  ;; Instead of trying to piece things together from partial text
  ;; (which can be almost useless depending on Emacs version), we
  ;; monitor to the point where we have the next bashdb prompt, and then
  ;; check all text from comint-last-input-end to process-mark.
  ;;
  ;; Also, we're very conservative about clearing the overlay arrow,
  ;; to minimize residue.  This means, for instance, that executing
  ;; other bashdb commands wipe out the highlight.  You can always do a
  ;; 'where' (aka 'w') command to reveal the overlay arrow.
  (let* ((origbuf (current-buffer))
	 (currproc (get-buffer-process origbuf)))

    (if (not (and currproc bashdb-bashdbtrack-do-tracking-p))
        (bashdb-bashdbtrack-overlay-arrow nil)

      (let* ((procmark (process-mark currproc))
             (block (buffer-substring (max comint-last-input-end
                                           (- procmark
                                              bashdb-bashdbtrack-track-range))
                                      procmark))
             target target_fname target_lineno target_buffer)

        (if (not (string-match (concat bashdb-bashdbtrack-input-prompt "$") block))
            (bashdb-bashdbtrack-overlay-arrow nil)

          (setq target (bashdb-bashdbtrack-get-source-buffer block))

          (if (stringp target)
              (message "bashdbtrack: %s" target)

            (setq target_lineno (car target))
            (setq target_buffer (cadr target))
            (setq target_fname (buffer-file-name target_buffer))
            (switch-to-buffer-other-window target_buffer)
            (goto-line target_lineno)
            (message "bashdbtrack: line %s, file %s" target_lineno target_fname)
            (bashdb-bashdbtrack-overlay-arrow t)
            (pop-to-buffer origbuf t)

            )))))
  )

(defun bashdb-bashdbtrack-get-source-buffer (block)
  "Return line number and buffer of code indicated by block's traceback text.

We look first to visit the file indicated in the trace.

Failing that, we look for the most recently visited python-mode buffer
with the same name or having 
having the named function.

If we're unable find the source code we return a string describing the
problem as best as we can determine."

  (if (not (string-match bashdb-position-re block))

      "line number cue not found"

    (let* ((filename (match-string bashdb-marker-regexp-file-group block))
           (lineno (string-to-int 
		    (match-string bashdb-marker-regexp-line-group block)))
           funcbuffer)

      (cond ((file-exists-p filename)
             (list lineno (find-file-noselect filename)))

            ((= (elt filename 0) ?\<)
             (format "(Non-file source: '%s')" filename))

            (t (format "Not found: %s" filename)))
      )
    )
  )


;;; Subprocess commands



;; bashdbtrack functions
(defun bashdb-bashdbtrack-toggle-stack-tracking (arg)
  (interactive "P")
  (if (not (get-buffer-process (current-buffer)))
      (error "No process associated with buffer '%s'" (current-buffer)))
  ;; missing or 0 is toggle, >0 turn on, <0 turn off
  (if (or (not arg)
	  (zerop (setq arg (prefix-numeric-value arg))))
      (setq bashdb-bashdbtrack-do-tracking-p (not bashdb-bashdbtrack-do-tracking-p))
    (setq bashdb-bashdbtrack-do-tracking-p (> arg 0)))
  (message "%sabled bashdb's bashdbtrack"
           (if bashdb-bashdbtrack-do-tracking-p "En" "Dis")))

(defun turn-on-bashdbtrack ()
  (interactive)
  (add-hook 'comint-output-filter-functions 
	    'bashdb-bashdbtrack-track-stack-file)
  (setq bashdb-bashdbtrack-is-tracking-p t)
  (bashdb-bashdbtrack-toggle-stack-tracking 1))

(defun turn-off-bashdbtrack ()
  (interactive)
  (remove-hook 'comint-output-filter-functions 
	       'bashdb-bashdbtrack-track-stack-file)
  (setq bashdb-bashdbtrack-is-tracking-p nil)
  (bashdb-bashdbtrack-toggle-stack-tracking 0))

;; Add a designator to the minor mode strings
(or (assq 'bashdb-bashdbtrack-minor-mode-string minor-mode-alist)
    (push '(bashdb-bashdbtrack-is-tracking-p
	    bashdb-bashdbtrack-minor-mode-string)
	  minor-mode-alist))



;;; bashdbtrack.el ends here

;;; bashdb.el ends here
