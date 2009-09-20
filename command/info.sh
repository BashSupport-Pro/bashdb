# -*- shell-script -*-
# info.sh - gdb-like "info" debugger commands
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2009 Rocky Bernstein
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

# Print info args. Like GDB's "info args"
# $1 is an additional offset correction - this routine is called from two
# different places and one routine has one more additional call on top.
# This code assumes the's debugger version of
# bash where FUNCNAME is an array, not a variable.

_Dbg_help_add info ''

typeset -ar _Dbg_info_subcmds=( args breakpoints display files functions program source \
    sources stack terminal variables watchpoints )
  
_Dbg_do_info() {
      
  if (($# > 0)) ; then
      typeset info_cmd=$1
      shift
      case $info_cmd in 
	  a | ar | arg | args )
              _Dbg_do_info_args 3  # located in dbg-stack.sh
	      return 0
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
	      typeset -i i
	      for i in ${!_Dbg_filenames[@]} ; do
		  typeset file=${_Dbg_filenames[i]}
		  typeset filevar=$(_Dbg_file2var "$file")
		  typeset -i maxline=$(_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar)
		  (( maxline++ )) 
		  (( _Dbg_basename_only )) && file=${file##*/}
		  _Dbg_msg "$file ($maxline lines)" ; 
	      done        
              return
	      ;;

	  fu | fun| func | funct | functi | functio | function | functions )
              _Dbg_do_list_functions $*
              return
	      ;;

	  h | ha | han | hand | handl | handle | \
              si | sig | sign | signa | signal | signals )
              _Dbg_info_signals
              return
	      ;;

	  l | li | lin | line )
              if (( ! _Dbg_running )) ; then
		  _Dbg_errmsg "No line number information available."
		  return $?
	      fi

              _Dbg_msg "Line $_Dbg_listline of \"$_Dbg_frame_last_filename\""
	      return
	      ;;
	  
	  p | pr | pro | prog | progr | progra | program )
	      if (( _Dbg_running )) ; then
		  _Dbg_msg "Program stopped."
		  if [[ -n $_Dbg_stop_reason ]] ; then
		      _Dbg_msg "It stopped ${_Dbg_stop_reason}."
		  fi
	      else
		  _Dbg_errmsg "The program being debugged is not being run."
	      fi
	      return $?
	      ;;
	  
	  so | sou | sourc | source )
              _Dbg_msg "Current script file is $_Dbg_frame_last_filename" 
	      typeset -i max_line=$(_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $_cur_filevar)
	      _Dbg_msg "Contains $max_line lines." ; 
              return
	      ;;
	  
	  st | sta | stac | stack )
	      _Dbg_do_backtrace 1 $*
	      return $?
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
	      return 0
	      ;;
	  *)
	      _Dbg_errmsg "Unknown info subcommand: $info_cmd"
	      msg=_Dbg_errmsg
      esac
  else
      msg=_Dbg_msg
  fi
  typeset -a list
  list=(${_Dbg_info_subcmds[@]})
  typeset columnized=''
  typeset -i width; ((width=_Dbg_linewidth-5))
  typeset -a columnized; columnize $width
  typeset -i i
  $msg "Info subcommands are:"
  for ((i=0; i<${#columnized[@]}; i++)) ; do 
      $msg "  ${columnized[i]}"
  done
  return 1
}

_Dbg_do_info_args() {

  typeset -i n=${#FUNCNAME[@]}-1  # remove us (_Dbg_do_info_args) from count

  eval "$_seteglob"
  if [[ $1 != $int_pat ]] ; then 
    _Dbg_msg "Bad integer parameter: $1"
    eval "$_resteglob"
    return 1
  fi

  typeset -i i=_Dbg_stack_pos+$1

  (( i > n )) && return 1

  # Figure out which index in BASH_ARGV is position "i" (the place where
  # we start our stack trace from). variable "r" will be that place.

  typeset -i q
  typeset -i r=0
  for (( q=0 ; q<i ; q++ )) ; do 
    (( r = r + ${BASH_ARGC[$q]} ))
  done

  # Print out parameter list.
  if (( 0 != ${#BASH_ARGC[@]} )) ; then

    typeset -i arg_count=${BASH_ARGC[$i]}

    ((r += arg_count - 1))

    typeset -i s
    for (( s=1; s <= arg_count ; s++ )) ; do 
      _Dbg_printf "$%d = %s" $s "${BASH_ARGV[$r]}"
      ((r--))
    done
  fi
  return 0
}

_Dbg_alias_add 'i' info
