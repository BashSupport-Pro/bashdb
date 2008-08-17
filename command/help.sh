# -*- shell-script -*-
# help.sh - gdb-like "help" debugger command
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008 Rocky Bernstein
#   rocky@gnu.org
#
#   bashdb is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   bashdb is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with bashdb; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

# Print a stack backtrace.  
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# $2 is the maximum number of entries to include.
# $3 is which entry we start from; the "up", "down" and the "frame"
# commands may shift this.

_Dbg_help_add help \
'help	- Print list of commands.'

# print help command 
function _Dbg_do_help {

  if ((0 == $#)) ; then
      _Dbg_help_sort_command_names
      _Dbg_msg 'Available commands:'
      typeset commands="${_Dbg_sorted_command_names[@]}"
      typeset columnized=''; 
      columnize "$commands" 60
      typeset -i i
      for ((i=0; i<${#columnized[@]}; i++)) ; do 
	  _Dbg_msg "  ${columnized[i]}"
      done
      _Dbg_msg ''
      _Dbg_msg 'Readline command line editing (emacs/vi mode) is available.'
      _Dbg_msg 'Type "help" followed by command name for full documentation.'
      return
  else
    typeset -r db_cmd=$1
  
    case $db_cmd in 
            !! | sh | she | shell ) 
	_Dbg_msg \
"!! cmd [args]   Execute shell \"cmd\" \"args\". Alias: shell."
		return ;;
            '#' ) 
		_Dbg_msg \
"#               Comment - ignore line. Maybe useful in command scripts."
		return ;;
            . ) 
		_Dbg_msg \
".               List current window of lines."
		return ;;
            / ) 
		_Dbg_msg \
"/pat/           Search forward for pat. Trailing / is optional.
                 Long command name: search or forward."
		return ;;
            '?'/ ) 
		_Dbg_msg \
"?pat?           Search backward for pat. Trailing ? is optional.
                 Long command name: rev or reverse"
		return ;;
	    - ) 
		_Dbg_msg \
"-               List previous window of lines."
		return ;;
	    A  )
		_Dbg_msg \
"A               Delete all actions"
		return ;;
	    D | deleteall )
		_Dbg_msg \
"D               Delete all breakpoints"
		return ;;
	    H )
		_Dbg_msg \
"H [from [to]]   List debugger history. If no arguments given list all history.
H -count        If a single postive integer is given, then list starting from 
![-]num:p       that number. If a single negative integer is given list that
                many history items. If second argument is given then list down 
                to that history number. 
                An alternate form is !n:p or !-n:p where n is an 
                integer. If a minus sign is used, you go back num from the end
                rather than specify an absolute history number"
                return ;;
	    L  )
		_Dbg_msg \
"L               List all breakpoints."
		return ;;
	    R | re | res | rest | resta | restar | restart | ru | run ) 
		_Dbg_msg \
"R [args]        Attempt to restart the program. 
                The source code is reread and breakpoint information is lost. 
                The command arguments used on the last invocation are used if 
                args is empty. If arguments were given, they are passed to the
                program. If running via the bashdb script and you want to
                change arguments you also need to include those arguments 
                to the bashdb script. Long command name: restart. Alias: run."
		return ;;
	    S )
		_Dbg_msg \
"S [[!]pattern]  List subroutine names [not] matching bash pattern. If no
                pattern is given, all subroutines are listed. (The pattern 
                is *)."
		return ;;
	    T | wh | whe | wher | where | bt| back | backtrace ) 
		_Dbg_msg \
"T [n]           Stack trace of calling functions or sourced files,
                line numbers, and files. If n is given, list only n lines.
                Long command name: where or backtrace."
		return ;;
            a )
		_Dbg_msg \
"a [linespec] stmt  Perform stmt on reaching linespec."
                return ;;
            b | br | bre | brea | break )
		_Dbg_msg \
"b [linespec]    Break on linespec. If no argument is given, us the current
                line. Long command name: break."
                return ;;
	    c | cont | conti |contin |continu | continue )
	        _Dbg_help_continue
                return ;;
	    cd  )
		_Dbg_msg \
"cd [DIR]       Set working directory to DIR for debugger and program
being debugged.  Tilde expansion, variable and filename expansion is
performed on DIR. If no directory is given, we print out the
current directory which is really the same things as running 'pwd'.

Note that gdb is a little different in that it peforms tilde expansion
but not filename or variable expansion and the directory argument is
not optional as it is here."
                return ;;
            cond | condi |condit |conditi | conditio | condition )
		_Dbg_msg \
"cond N COND     Specify breakpoint number N to break only if COND is true.
N is an integer and COND is an expression to be evaluated whenever 
breakpoint N is reached. Long command name: condition."
                return ;;
            d | cl | cle | clea | clea | clear )
		_Dbg_msg \
"cl [linespec]   Clear breakpoint at specified line-spec. If no line given, use
                the current line. All breakpoints in that line are cleared. 
                Long command name: clear."
                return ;;
	    de | del | dele | delet | delete ) 
		_Dbg_msg \
"d {num}..       Delete the breakpoint entry or entries.
                Long command name: delete."
                return ;;
	    deb | debu | debug ) 
		_Dbg_msg \
"deb [script]    Set up [script] for debugging. If no script is given, take
                the script name from the command to be executed.
                Long command name: debug."
                return ;;
            di | dis | disa | disab | disabl | disable ) 
		_Dbg_msg \
"di {n}...       Disable breakpoint entry/entries. Long command name: disable."
                return ;;
            disp | displ | displa | display ) 
		_Dbg_msg \
"disp {n}        Set display expression or list all display expressions. 
                Long command name: display."
                return ;;
	    do | dow | down ) 
		_Dbg_msg \
"down [count]    Set file location for printing down the call stack by 
                count. If count is omitted use 1."
                return ;;
	    e | ev | eva ) 
		_Dbg_msg \
"e bash-cmd      Evaluate a bash command by sourcing it in a subshell. Long
                command name: eval."
                return ;;
	    ed | edi | edit ) 
		_Dbg_msg \
"edit [linespec] Edit specified file at location given
                 If no location is given use the current location."
                return ;;
            en | ena | enab | enabl | enable ) 
		_Dbg_msg \
"en {n}...       Enable breakpoint entry/entries. Long command name: enable."
                return ;;
            r  | fin| fini | finis | finish ) 
		_Dbg_msg \
"r               Execute until the current function or source file returns.
                Long command name: finish."
                return ;;
            fil| file ) 
		_Dbg_msg \
"file filename   Use script file filename whenever the current source file
                is encountered by the debugger."
                return ;;
	    ha | han | hand | handl | handle )
		_Dbg_msg \
"ha sig {stop|nostop|stack|nostack|print|noprint}
               Specify how to handle a signal. Args are signals and
               actions to apply to those signals. Symbolic signals
               (e.g. SIGSEGV) are recommended but numeric signals are
               allowed too. Recognized actions include \"stop\",
               \"nostop\", \"print\", and \"noprint\". Stop means
               reenter debugger if this signal happens. Print means
               print a message if this signal happens.  Long command
               name: handle."  
	       return ;;

	    hi | his | hist | histo | histor | history ) 
		_Dbg_msg \
"hi n            Rerun a debugger command from the debugger history. See also
![-]n           H to list the history. An alternname form is !n or !-n. If 
                the minus sign is used you going back n from the end rather 
                than specifying an absolute history number. 
                Long command name: history."
                return ;;
	    i | in | inf | info ) 
	        _Dbg_info_help $2
                return ;;
	    k | ki | kil | kill )
		_Dbg_msg \
"kill      	Kill execution of program being debugged."
                return ;;
	    l | li | lis | list )
		_Dbg_msg \
"l linespec      List window lines starting at linespec.
l min incr      List incr lines starting at 'min' linespec.
l               List next window of lines.
l .             Same as above.
                Long command name: list."
                return ;;
	    lo | loa | load )
		_Dbg_msg \
"load file      Load in a Bash source file so it can be used in 
                breakpoints and listing."
                return ;;
	    n | ne | nex | next )
		_Dbg_msg \
"n [count]       Single steps possibly skipping execution into subroutine calls
                and sourced files. Performed [count] times default is 1 time.
                Long command name: next."
                return ;;
	    p | pr | pri | prin | print )
		_Dbg_msg \
"p string        Print value of a substituted string via \`echo'. A variable
                should have leading $ if its value is to be substituted.
                Long command name: print."
                return ;;
	    q | qu | qui | quit )
		_Dbg_msg \
"q [expr] [n]    Terminate execution of the program with return code expr. If
                expr is missing, use 0. If n is given then we terminate only 
                that many subshells or nested shells. Long name: quit."
                return ;;
	    ret | retu | retur | return )
		_Dbg_msg \
"ret             Skip completion of this function or sourced file. 
                Long name: return."
                return ;;
	    se | set  )
	        _Dbg_help_set $2
                return ;;
	    s | st | ste | step )
		_Dbg_msg \
"s [count]       Single steps possibly executing into subroutine calls 
                and sourced files. Performed [count] times default is 1 time."
                return ;;
	    sh | sho | show )
		_Dbg_help_show $2
                return ;;
	    si | sig | sign | signa | signal )
		_Dbg_msg \
"signal {signam|signum}   
                Send the specified signal to the program."
                return ;;
  	    sk | ski | skip ) 
		_Dbg_msg \
"sk [count]      Skip (don't run) the next [count] command(s) to be executed.
                Long command name: skip."
                return ;;
	    so | sou | sour | sourc | source )
		_Dbg_msg \
'source file     Read in debugger command file.'
                return ;;
	    t | to | tog | togg | toggl | toggle ) 
		_Dbg_msg \
"t | toggle      Toggle line-execution tracing. Long command name: toggle."
                return ;;
            tb | tbr | tbre | tbrea | tbreak )
		_Dbg_msg \
"tb [linespec]    Set a one-time break on linespec. If no argument is given, 
                 us the current line. Long command name: tbreak."
                return ;;
            tt | tty )
		_Dbg_msg \
"tt  tty-name     Set the output device for debugger output
                 Long command name: tty."
                return ;;
	    u | up ) 
		_Dbg_msg \
"u | up [count]  Set file location for printing up the call stack by 
                count. If count is omitted use 1."
                return ;;
	    v | ve | ver | vers | versi | versio | version )
		_Dbg_msg \
"M | version     Show release version-control IDs of debugger scripts."
                return ;;
	    w | window ) 
		_Dbg_msg \
"w [linespec]    List window around line or current linespec. Long command 
                name: window."
                return ;;
	    x | examine ) 
		_Dbg_msg \
"x expr          Print value of an expression via \'declare', \`let' and then
                failing these eval. Single variables and arithmetic expression 
                do not need leading $ for their value is to be substituted. 
                However if neither these, variables need $ to have their value 
                substituted. Long command name: examine"
                return ;;
	    V )
		_Dbg_msg \
"V [!][pat]      List variables and values for whose variables names which 
                match pat. If ! is used, list variables that *don't* match. 
                If pat is omitted, use * (everything) for the pattern."
                return ;;
	    We | watche ) 
		_Dbg_msg \
"We [arith]      Add watchpoint for expression expr. If no expression is given
                all watchpoints are deleted. Long command name: watche."
                return ;;
	    W | wa | wat | watch ) 
		_Dbg_msg \
"W [var]         Add watchpoint for variable var.  If no expression is given
                all watchpoints are deleted. Long command name: watch."
                return ;;
	    * )
	   _Dbg_msg "Undefined command: \"$db_cmd\".  Try \"help\"."
  	   return ;;
	esac
    fi

    _Dbg_msg 'bashdb commands:
List/search source lines:                 Control script execution:
-------------------------                 -------------------------
 l [start|.] [cnt] List cnt lines         T [n]        Stack trace
                   from line start        s [n]        Single step [n times]
 l sub       List source code fn          n [n]        Next, steps over subs
 - or .      List previous/current line   <CR>/<Enter> Repeat last n or s 
 w [line]    List around line             c [linespec] Continue [to linespec]
 f filename  View source in file          L            List all breakpoints
 /pat/       Search forward for pat       b linespec   Set breakpoint
 ?pat?       Search backward for pat      del [n].. or D Delete a/all breaks
                                                         by entry number
Debugger controls:                        skip         skip execution of cmd
-------------------------                 cl linespec  Delete breakpoints by
 H [num]         Show last num commands                line spec
 q [exp] or ^D   Quit returning exp       R [args]     Attempt a restart
 info [cmd]      Get info on cmd.         u [n]        Go up stack by n or 1.
 !n or hi n      Run debugger history n   do [n]       Go down stack by n or 1.
 h or ? [cmd]    Get help on command      W [var]      Add watchpoint. If no
 info [cmd]      Get info on cmd                       no expr, delete all
 show [cmd]      Show settings            We [expr]    Add Watchpoint arith 
                                                       expr
 so file         read in dbg commands     t            Toggle trace
                                          en/di n      enable/disable brkpt,
 set x y         set a debugger variable               watchpoint, or display
 e bash-cmd      evaluate a bash command  tb linespec  Add one-time break
 disp expr       add a display expr       a linespec cmd eval "cmd" at linespec
 M               Show module versions     A            delete all actions
 x expr          evaluate expression      ret          jump out of fn or source
                 (via declare, let, eval) finish       execute until return
 deb             debug into another       cond n exp   set breakpoint condition
                 shell script
 !! cmd [args]   execute shell command "cmd" with "args"
 file filename   Set script filename to read for current source.
 load filename   read in Bash source file use in list and break commands

Data Examination: also see e, t, x
-------------------------                 
 p variable      Print variable 
 V [[!]pat]      List variable(s) matching or not (!) matching pattern pat
 S [[!]pat]      List subroutine names [not] matching pattern pat

Readline command line editing (emacs/vi mode) is available.
For more help, type h <cmd> or consult online-documentation.'

}

