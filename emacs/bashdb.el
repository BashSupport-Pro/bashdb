;;; bashdb.el --- BASH Debugger mode via GUD and bashdb
;;; $Id: bashdb.el,v 1.3 2006/01/29 18:40:52 rockyb Exp $

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

    ; If we are invoking using the bashdb command, no need to 
    ; add --debugger
    (if (string-match "bashdb" command-line) 
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
    ;; Format of line looks like this:
    ;;   (/etc/init.d/ntp.init:16):
    ;; but we also allow DOS drive letters
    ;;   (d:/etc/init.d/ntp.init:16):
    (while (string-match "\\(^\\|\n\\)(\\(\\([a-zA-Z]:\\)?[^:\n]*\\):\\([0-9]*\\)):.*\n"
			 gud-marker-acc)
      (setq

       ;; Extract the frame position from the marker.
       gud-last-frame
       (cons (substring gud-marker-acc (match-beginning 2) (match-end 2))
	     (string-to-int (substring gud-marker-acc
				       (match-beginning 4)
				       (match-end 4))))

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

  (gud-def gud-break  "break %l"   "\C-b" "Set breakpoint at current line.")
  (gud-def gud-tbreak "tbreak %f:%l"  "\C-t" "Set temporary breakpoint at current line.")
  (gud-def gud-remove "clear %f:%l"   "\C-d" "Remove breakpoint at current line")
  (gud-def gud-step   "step %p"       "\C-s" "Step one source line with display.")
  (gud-def gud-next   "next %p"       "\C-n" "Step one line (skip functions).")
  (gud-def gud-cont   "continue"   "\C-r" "Continue with display.")
  (gud-def gud-finish "finish"     "\C-f" "Finish executing current function.")
  (gud-def gud-up     "up %p"      "<" "Up N stack frames (numeric arg).")
  (gud-def gud-down   "down %p"    ">" "Down N stack frames (numeric arg).")
  (gud-def gud-print  "p %e"      "\C-p" "Evaluate bash expression at point.")

  ;; Is this right?
  (gud-def gud-statement "eval %e" "\C-e" "Execute Bash statement at point.")

  (local-set-key [menu-bar debug tbreak] '("Temporary Breakpoint" . gud-tbreak))
  (local-set-key [menu-bar debug finish] '("Finish Function" . gud-finish))
  (local-set-key [menu-bar debug up] '("Up Stack" . gud-up))
  (local-set-key [menu-bar debug down] '("Down Stack" . gud-down))

  (setq comint-prompt-regexp "^bashdb<+(*[0-9]*)*>+ ")
  (setq paragraph-start comint-prompt-regexp)
  (run-hooks 'bashdb-mode-hook)
  )

(provide 'bashdb)
;;; bashdb.el ends here
