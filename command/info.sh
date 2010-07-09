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

_Dbg_help_add info ''

typeset -a _Dbg_info_subcmds=( args breakpoints display files functions program source \
    sources stack terminal variables watchpoints )
  

# Load in "info" subcommands
for _Dbg_file in ${_Dbg_libdir}/command/info_sub/*.sh ; do 
    source $_Dbg_file
done

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
	      _Dbg_do_info_brkpts $*
	      return $?
	      ;;

	  d | di | dis| disp | displ | displa | display )
	      _Dbg_do_info_display $*
	      return
	      ;;

	  file | files )
	      _Dbg_do_info_files
	      return $?
	      ;;

	  fu | fun| func | funct | functi | functio | function | functions )
              _Dbg_do_info_functions $*
              return $?
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
	      _Dbg_do_info_program
	      return $?
	      ;;
	  
	  so | sou | sourc | source )
              _Dbg_msg "Current script file is $_Dbg_frame_last_filename" 
              _Dbg_msg "Located in ${_Dbg_file2canonic[$_Dbg_frame_last_filename]}" 
	      typeset -i max_line
	      max_line=$(_Dbg_get_maxline $_Dbg_frame_last_filename)
	      _Dbg_msg "Contains $max_line lines."
              return 0
	      ;;
	  
	  st | sta | stac | stack )
	      _Dbg_do_backtrace 1 $*
	      return $?
	      ;;
	  v | va | var | vari | varia | variab | variabl | variable | variables )
	      _Dbg_do_info_variables "$1"
	      return
              ;;
	  w | wa | war | warr | warra | warran | warrant | warranty )
	      _Dbg_do_info_warranty
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
_Dbg_alias_add 'i' info
