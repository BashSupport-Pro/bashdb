# dbg-info.inc - Bourne Again Shell Debugger Help Routines

#   Copyright (C) 2002, 2003, 2004, 2005, 2006 
#   Rocky Bernstein rockyb@users.sourceforge.net
#
#   Bash is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   Bash is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#   
#   You should have received a copy of the GNU General Public License along
#   with Bash; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.

typeset -r _Dbg_info_cmds="args breakpoints display files functions line program signals source stack terminal variables warranty"

_Dbg_info_help() {
  local -r info_cmd=$1
  local label=$2

  if [[ -z $info_cmd ]] ; then 
      local thing
		_Dbg_msg \
"List of info subcommands:
"
      for thing in $_Dbg_info_cmds ; do 
	_Dbg_info_help $thing 1
      done
      return
  fi

  case $info_cmd in 
    ar | arg | args )
      _Dbg_msg \
"info args -- Argument variables (e.g. \$1, \$2, ...) of the current stack frame."
      return 0
      ;;
    b | br | bre | brea | 'break' | breakp | breakpo | breakpoints | \
    w | wa | wat | watc | 'watch' | watchp | watchpo | watchpoints )
      _Dbg_msg \
"info breakpoints -- Status of user-settable breakpoints"
      return 0
      ;;
    disp | displ | displa | display ) 
      _Dbg_msg \
"info display -- Show all display expressions"
      return 0
      ;;
    fi | file| files | sources )
      _Dbg_msg \
"info files -- Source files in the program"
      return 0
      ;;
    fu | fun| func | funct | functi | functio | function | functions )
      _Dbg_msg \
"info functions -- All function names"
      return 0
      ;;
    l | li| lin | line )
      _Dbg_msg \
"info line -- list current line number and and file name"
      return 0
      ;;
    p | pr | pro | prog | progr | progra | program )
      _Dbg_msg \
"info program -- Execution status of the program."
      return 0
      ;;
    h | ha | han | hand | handl | handle | \
    si | sig | sign | signa | signal | signals )
      _Dbg_msg \
"info signals -- What debugger does when program gets various signals"
      return 0
      ;;
    so | sou | sourc | source )
      _Dbg_msg \
"info source -- Information about the current source file"
      return 0
      ;;
    st | sta | stac | stack )
      _Dbg_msg \
"info stack -- Backtrace of the stack"
      return 0
      ;;
    te | ter | term | termi | termin | termina | terminal | tt | tty )
      _Dbg_msg \
"info terminal -- Print terminal device"
      return 0
      ;;
    tr|tra|trac|trace|tracep | tracepo | tracepoi | tracepoint | tracepoints )
      _Dbg_msg \
"info tracepoints -- Status of tracepoints"
      return 0
      ;;
    v | va | var | vari | varia | variab | variabl | variable | variables )
      _Dbg_msg \
"info variables -- All global and static variable names"
      return 0
      ;;
    w | wa | war | warr | warra | warran | warrant | warranty )
      _Dbg_msg \
"info warranty -- Various kinds of warranty you do not have"
      return 0
      ;;
    * )
      _Dbg_msg \
    "Undefined info command: \"$info_cmd\".  Try \"help info\"."
  esac
}

_Dbg_do_info() {
  local -r info_cmd=$1
  local -ar subcmds=( args breakpoints display files functions program source \
                      sources stack terminal variables watchpoints )
  
  if [[ $info_cmd != '' ]] ; then
    shift
    case $info_cmd in 
      a | ar | arg | args )
        _Dbg_do_info_args 3  # located in dbg-stack.inc
	return
	;;
      b | br | bre | brea | 'break' | breakp | breakpo | breakpoints | \
      w | wa | wat | watc | 'watch' | watchp | watchpo | watchpoints )
	_Dbg_do_list_brkpt $*
	_Dbg_list_watch $*
	return
	;;

      d | di | dis| disp | displ | displa | display )
	_Dbg_do_list_display $*
	return
	;;

      fi | file| files | sources )
        _Dbg_msg "Source files for which have been read in:
"
        for file in ${_Dbg_filenames[@]} ; do  
	  local filevar=`_Dbg_file2var $file`
	  local -i maxline=`_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar`
	  (( maxline++ )) 
	  (( _Dbg_basename_only )) && file=${file##*/}
	  _Dbg_msg "$file ($maxline lines)" ; 
	done        
        return
	;;

      fu | fun| func | funct | functi | functio | function | functions )
        _Dbg_do_list_subroutines $*
        return
	;;

      h | ha | han | hand | handl | handle | \
          si | sig | sign | signa | signal | signals )
        _Dbg_info_signals
        return
	;;

      l | li | lin | line )
        if (( ! _Dbg_running )) ; then
	    _Dbg_msg "No line number information available."
	    return
	fi

        _Dbg_msg "Line $_Dbg_listline of \"$_cur_source_file\""
	return
	;;

      p | pr | pro | prog | progr | progra | program )
      if (( _Dbg_running )) ; then
	  _Dbg_msg "Program stopped."
	  if (( _Dbg_currentbp )) ; then
	      _Dbg_msg "It stopped at breakpoint ${_Dbg_currentbp}."
	  elif [[ -n $_Dbg_stop_reason ]] ; then
	      _Dbg_msg "It stopped ${_Dbg_stop_reason}."
	  fi
      else
	  _Dbg_msg "The program being debugged is not being run."
      fi
      return
      ;;
      so | sou | sourc | source )
        _Dbg_msg "Current script file is $_cur_source_file" 
	local -i max_line=`_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $_cur_filevar`
	_Dbg_msg "Contains $max_line lines." ; 
        return
	;;

      st | sta | stac | stack )
	_Dbg_do_stack_trace 1 $*
	return
	;;
      te | ter | term | termi | termin | termina | terminal | tt | tty )
	_Dbg_msg "tty: $_Dbg_tty"
	return;
	;;
      v | va | var | vari | varia | variab | variabl | variable | variables )
	_Dbg_do_list_variables "$1"
	return
        ;;
      w | wa | war | warr | warra | warran | warrant | warranty )
        _Dbg_msg "
			    NO WARRANTY

  11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

  12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.
"
	return
	;;
      *)
	_Dbg_msg "Unknown subcommand: $info_cmd"
    esac
  fi
  _Dbg_msg "Info subcommands are: ${subcmds[@]}"
}

# List signal handlers in effect.
_Dbg_info_signals() {
  local -i i=0
  local signal_name
  local handler
  local stop_flag
  local print_flag

  _Dbg_msg "Signal       Stop   Print   Stack     Value"
  _Dbg_printf_nocr "%-12s %-6s %-7s %-9s " EXIT \
    ${_Dbg_sig_stop[0]:-nostop} ${_Dbg_sig_print[0]:-noprint} \
    ${_Dbg_sig_show_stack[0]:-nostack}

  # This is a horrible hack, but I can't figure out how to get
  # trap -p 0 into a variable; handler=`trap -p 0` doesn't work.
  if [[ -n $_Dbg_tty  ]] ; then
    builtin trap -p 0 >>$_Dbg_tty
  else
    builtin trap -p 0
  fi

  while [ 1 ] ; do
    signal_name=`builtin kill -l $i 2>/dev/null`
    if (( $? != 0 )) ; then
      break
    fi
    handler=`builtin trap -p $i`
    if [[ -n $handler ]] ; then
      _Dbg_printf "%-12s %-6s %-7s %-9s %-6s" $signal_name \
	${_Dbg_sig_stop[$i]:-nostop} ${_Dbg_sig_print[$i]:-noprint} \
        ${_Dbg_sig_show_stack[$i]:-nostack} "$handler"
    fi
    ((i++))
  done
}

# This is put at the so we have something at the end to stop at 
# when we debug this. By stopping at the end all of the above functions
# and variables can be tested.
typeset -r _Dbg_info_ver=\
'$Id: dbg-info.inc,v 1.9 2006/07/16 14:04:38 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
