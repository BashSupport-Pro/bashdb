# -*- shell-script -*-
# info.sh - gdb-like "info" debugger commands
#
#   Copyright (C) 2002, 2003, 2004, 2005, 2006, 2008, 2009,
#   2010, 2011 Rocky Bernstein <rocky@gnu.org>
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

typeset -A _Dbg_debugger_info_commands

_Dbg_help_add info '' 1 

typeset -a _Dbg_info_subcmds
_Dbg_info_subcmds=( args breakpoints display files functions program source \
    sources stack terminal variables watchpoints )
  

# Load in "info" subcommands
for _Dbg_file in ${_Dbg_libdir}/command/info_sub/*.sh ; do 
    source $_Dbg_file
done

# Command completion
_Dbg_complete_info() {
    _Dbg_complete_subcmd info
}

_Dbg_do_info() {
      
  if (($# > 0)) ; then
      typeset subcmd=$1
      shift
      
      if [[ -n ${_Dbg_debugger_info_commands[$subcmd]} ]] ; then
	  ${_Dbg_debugger_info_commands[$subcmd]} $label "$@"
	  return $?
      else
	  # Look for a unique abbreviation
	  typeset -i count=0
	  typeset list; list="${!_Dbg_debugger_info_commands[@]}"
	  for try in $list ; do 
	      if [[ $try =~ ^$subcmd ]] ; then
		  subcmd=$try
		  ((count++))
	      fi
	  done
	  ((found=(count==1)))
      fi
      if ((found)); then
	  ${_Dbg_debugger_info_commands[$subcmd]} $label "$@"
	  return $?
      fi
  
      case $subcmd in 
	  a | ar | arg | args )
              _Dbg_do_info_args 3  # located in dbg-stack.sh
	      return 0
	      ;;
	  fu | fun| func | funct | functi | functio | function | functions )
              _Dbg_do_info_functions $@
              return 0
	      ;;

	  h | ha | han | hand | handl | handle | \
              si | sig | sign | signa | signal | signals )
              _Dbg_info_signals
              return
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
	      _Dbg_do_backtrace 1 $@
	      return 0
	      ;;
	  *)
	      _Dbg_errmsg "Unknown info subcommand: $subcmd"
	      msg=_Dbg_errmsg
      esac
  else
      msg=_Dbg_msg
  fi
  typeset -a list
  list=(${_Dbg_info_subcmds[@]})
  typeset columnized=''
  typeset -i width; ((width=_Dbg_set_linewidth-5))
  typeset -a columnized; columnize $width
  typeset -i i
  $msg "Info subcommands are:"
  for ((i=0; i<${#columnized[@]}; i++)) ; do 
      $msg "  ${columnized[i]}"
  done
  return 1
}

_Dbg_alias_add i info
