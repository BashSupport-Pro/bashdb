# dbg-io.inc - Bourne Again Shell Debugger Input/Output routines
#
#   Copyright (C) 2002, 2003, 2004, 2006 Rocky Bernstein 
#   rockyb@users.sourceforge.net
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

# ==================== VARIABLES =======================================

# _Dbg_source_mungedfilename is an array which contains source_lines for
#  filename
# _Dbg_read_mungedfilename is array which contains the value '1' if the
#  filename has been read in.

# Filename that's used when no source file is around. In particular
# if bash --debugger -c 'string' was used to invoke us.
typeset -r _Dbg_bogus_file='*BOGUS*'

typeset -a _Dbg_filenames          # names of all source files read
typeset -a _Dbg_override_filenames # name translations given via the debugger
                                   # "file" command.
typeset _cur_source_file  # current source file of debugged program
typeset _cur_filevar      # source file mangled so it can be used in a variable
typeset -i _curline       # current line number of debugged program

# See if we have compiled the readarray builtin. This speeds up reading
# files into a bash array.
typeset -i _Dbg_have_readarray=0

if [[ -r $_Dbg_libdir/readarray ]] ; then
  if enable -f $_Dbg_libdir/readarray  readarray >/dev/null 2>&1 ; then
    _Dbg_have_readarray=1
  fi
fi

# ===================== FUNCTIONS =======================================

# print message to output device
_Dbg_msg() {
  if (( $_Dbg_logging != 0 )) ; then
    builtin echo -e "$@" >>$_Dbg_logfid
  fi
  if (( $_Dbg_logging_redirect == 0 )) ; then
    if [[ -n $_Dbg_tty  ]] ; then
      builtin echo -e "$@" >>$_Dbg_tty
    else
      builtin echo -e "$@"
    fi
  fi
}

# print message to output device without a carriage return at the end
_Dbg_msg_nocr() {
  if (( $_Dbg_logging != 0 )) ; then
    builtin echo -n -e "$@" >>$_Dbg_logfid
  fi
  if (( $_Dbg_logging_redirect == 0 )) ; then
    if [[ -n $_Dbg_tty  ]] ; then
      builtin echo -n -e "$@" >>$_Dbg_tty
    else
      builtin echo -n -e "$@"
    fi
  fi
}

# print message to output device
_Dbg_printf() {
  local format=$1
  shift
  if (( $_Dbg_logging != 0 )) ; then
    builtin printf "$format" "$@" >>$_Dbg_logfid
  fi
  if (( $_Dbg_logging_redirect == 0 )) ; then
    if [[ -n $_Dbg_tty ]] ; then
      builtin printf "$format" "$@" >>$_Dbg_tty
    else
      builtin printf "$format" "$@"
    fi
  fi
  _Dbg_msg ""
}

# print message to output device without a carriage return at the end
_Dbg_printf_nocr() {
  local format=$1
  shift 
  if (( $_Dbg_logging != 0 )) ; then
    builtin printf "$format" "$@" >>$_Dbg_logfid
  fi
  if (( $_Dbg_logging_redirect == 0 )) ; then
    if [[ -n $_Dbg_tty ]] ; then 
      builtin printf "$format" "$@" >>$_Dbg_tty
    else
      builtin printf "$format" "$@"
    fi
  fi
}

# Common funnel for "Undefined command" message
_Dbg_undefined_cmd() {
  _Dbg_msg "Undefined $1 command \"$2\""
}

# _Dbg_progess_show --- print the progress bar
# $1: prefix string
# $2: max value
# $3: current value
_Dbg_progess_show() {
    local title=$1
    local -i max_value=$2
    local -i current_value=$3
    local -i max_length=40
    local -i current_length

    
    if (( max_value == 0 )) ; then
	# Avoid dividing by 0.
	current_length=${max_length}
    else
	current_length=$(( ${max_length} * ${current_value} / ${max_value} ))
    fi
    
    _Dbg_progess_show_internal "$1" ${max_length} ${current_length}
    _Dbg_printf_nocr " %3d%%" "$(( 100 * ${current_value} / ${max_value} ))"
}
# _Dbg_progess_show_internal --- internal function for _Dbg_progess_show
# $1: prefix string
# $2: max length
# $3: current length
_Dbg_progess_show_internal() {
    local -i i=0

    # Erase line
    if test "x$EMACS" = xt; then
	_Dbg_msg_nocr "\r\b\n"	
    else
	_Dbg_msg_nocr "\r\b"
    fi
    
    _Dbg_msg_nocr "$1: ["
    for (( i=0; i < $3 ; i++ )); do
	_Dbg_msg_nocr "="
    done
    _Dbg_msg_nocr ">"

    for (( i=0; i < $2 - $3 ; i++ )); do
	_Dbg_msg_nocr " "
    done
    _Dbg_msg_nocr "]"
}

# clean up progress bar
_Dbg_progess_done() {
    # Erase line
    if test "x$EMACS" = xt; then
	_Dbg_msg_nocr "\r\b\n"	
    else
	_Dbg_msg_nocr "\r\b"
    fi
    _Dbg_msg $1
}


# Return text for source line for line $1 of filename $2 in variable
# $source_line. The hope is that this has been declared "local" in the 
# caller.

# If $2 is omitted, # use _cur_source_file, if $1 is omitted use _curline.
_Dbg_get_source_line() {
  local lineno=${1:-$_curline}
  local filename=${2:-$_cur_source_file}
  local filevar=`_Dbg_file2var $filename`
  local is_read=`_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar`
  [ $is_read ] || _Dbg_readin $filename 
  
  source_line=`_Dbg_get_assoc_array_entry _Dbg_source_${filevar} $lineno`
}

# Read $1 into _source_$1 array.  Variable _Dbg_read_$1 will be set
# to 1 to note that the file has been read and the filename will be saved
# in array _Dbg_filenames

_Dbg_readin() {
  # set -xv
  local filename=${1:-$_cur_source_file}

  local -i line_count=0
  local filevar
  local source_array
  local -ir NOT_SMALLFILE=1000

  if [[ -z $filename ]] || [[ $filename == $_Dbg_bogus_file ]] ; then 
    filevar='ABOGUSA'
    source_array="_Dbg_source_${filevar}"
    local cmd="${source_array}[0]=\"$BASH_EXECUTION_STRING\""
    eval $cmd

  else 
    local fullname=$(_Dbg_resolve_expand_filename $filename)
    filevar=`_Dbg_file2var $filename`
    if [[ -r $fullname ]] ; then
      local -r progress_prefix="Reading $filename"
      source_array="_Dbg_source_${filevar}"
      if (( 0 != $_Dbg_have_readarray )); then
	# If we have readarray that speeds up reading greatly. Use it.
	local -ir BIGFILE=30000
	if wc -l < /dev/null >/dev/null 2>&1 ; then 
	  line_count=`wc -l < "${fullname}"`
	  if (( $line_count >= $NOT_SMALLFILE )) ; then 
	    _Dbg_msg_nocr "${progress_prefix} "
	  fi
	fi
	readarray -t -O 1 -c $BIGFILE \
	  -C "_Dbg_progess_show \"${progress_prefix}\" ${line_count}" \
	  $source_array < $fullname 
	(( line_count > BIGFILE)) && _Dbg_progess_done
	
      else
	# No readarray. Do things the long way.
	local -i i
	for (( i=1; 1 ; i++ )) ; do 
	  local source_entry="${source_array}[$i]"
	  local readline_cmd="read -r $source_entry; rc=\$?";
	  local -i rc=1
	  if (( i % 1000 == 0 )) ; then
	    if (( i==NOT_SMALLFILE )) ; then
	      if wc -l < /dev/null >/dev/null 2>&1 ; then 
		line_count=`wc -l < "${fullname}"`
	      else
		_Dbg_msg_nocr "${progress_prefix} "
	      fi
	    fi
	    if (( line_count == 0 )) ; then
	      _Dbg_msg_nocr "${i}... "
	    else
	      _Dbg_progess_show "${progress_prefix}" ${line_count} ${i}
	    fi
	  fi
	  eval $readline_cmd
	  if [[ $rc != 0 ]]  ; then 
	    break;
	  fi
	done  < $fullname
	# The last read in the loop above failed. So we've actually 
	# read one more than the number of lines.
	local -r remove_last_index_cmd="unset $source_array[$i]"
	eval $remove_last_index_cmd
	(( line_count != 0 )) && _Dbg_progess_done
      fi
    else
	return
    fi
  fi

  local -r line_count_cmd="line_count=\${#$source_array[@]}"
  eval $line_count_cmd

  (( line_count >= NOT_SMALLFILE )) && _Dbg_msg "done."

  _Dbg_set_assoc_scalar_entry "_Dbg_read_" $filevar 1
  _Dbg_set_assoc_scalar_entry "_Dbg_maxline_" $filevar $line_count
  
  # Add $filename to list of all filenames
  _Dbg_filenames[${#_Dbg_filenames[@]}]=$fullname;
  # set +xv
}

# This is put at the so we have something at the end when we debug this.
typeset -r _Dbg_io_ver=\
'$Id: dbg-io.inc,v 1.12 2006/12/19 04:41:05 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
