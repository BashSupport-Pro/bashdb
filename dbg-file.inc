# Things related to file handling.
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

# Directory search patch for unqualified file names
typeset -a _Dbg_dir=('\$cdir' '\$cwd' )

# Directory in which the script is located
typeset -r _Dbg_cdir=${_Dbg_source_file%/*}

#
# Resolve $1 to a full file name which exists. First see if filename has been
# mentioned in a debugger "file" command. If not and the file name
# is a relative name use _Dbg_dir to substitute a relative directory name.
#
_Dbg_resolve_expand_filename() {
  local find_file=$1

  if [[ -z "$find_file" ]] ; then
    _Dbg_msg "Internal debug error: null file to find"
    echo ''
    return 1
  fi

  # Is this one of the files we've that has been specified in a debugger
  # "FILE" command?
  local -r filevar=`_Dbg_file2var $find_file`
  local file_cmd_file=`_Dbg_get_assoc_scalar_entry "_Dbg_file_cmd_" $filevar`
  if [[ -n "$file_cmd_file" ]] ; then
    echo "$file_cmd_file"
    return 0
  fi

  if [[ ${find_file:0:1} == '/' ]] ; then 
    # Absolute file name
    echo "$find_file"
    return 0
  elif [[ ${find_file:0:1} == '.' ]] ; then
    # Relative file name
    full_find_file=$(_Dbg_expand_filename ${_Dbg_init_cwd}/$find_file)
    if [[ -z "$full_find_file" ]] || [[ ! -r $full_find_file ]]; then
      # Try using cwd rather that Dbg_init_cwd
      full_find_file=$(_Dbg_expand_filename $find_file)
    fi
    echo "$full_find_file"
    return 0
  else
    # Resolve file using _Dbg_dir
    local -i n=${#_Dbg_dir[@]}
    local -i i
    for (( i=0 ; i < n; i++ )) ; do
      local basename="${_Dbg_dir[i]}"
      if [[  $basename == '\$cdir' ]] ; then
	basename=$_Dbg_cdir
      elif [[ $basename == '\$cwd' ]] ; then
	basename=$(pwd)
      fi
      if [[ -f "$basename/$find_file" ]] ; then
	echo "$basename/$find_file"
	return 0
      fi
    done
  fi
  echo ""
  return 1
}

# _Dbg_is_file echoes the full filename if $1 is a filename found in files
# '' is echo'd if no file found.
_Dbg_is_file() {
  local find_file=$1

  if [[ -z "$find_file" ]] ; then
    _Dbg_msg "Internal debug error: null file to find"
    echo ''
    return
  fi

  if [[ ${find_file:0:1} == '/' ]] ; then 
    # Absolute file name
    for try_file in ${_Dbg_filenames[@]} ; do 
      if [[ $try_file == $find_file ]] ; then
	echo "$try_file"
	return
      fi
    done
  elif [[ ${find_file:0:1} == '.' ]] ; then
    # Relative file name
    find_file=$(_Dbg_expand_filename ${_Dbg_init_cwd}/$find_file)
    for try_file in ${_Dbg_filenames[@]} ; do 
      if [[ $try_file == $find_file ]] ; then
	echo "$try_file"
	return
      fi
    done
  else
    # Resolve file using _Dbg_dir
    for try_file in ${_Dbg_filenames[@]} ; do 
      local pathname
      local -i n=${#_Dbg_dir[@]}
      local -i i
      for (( i=0 ; i < n; i++ )) ; do
	local basename="${_Dbg_dir[i]}"
	if [[  $basename = '\$cdir' ]] ; then
	  basename=$_Dbg_cdir
	elif [[ $basename = '\$cwd' ]] ; then
	  basename=$(pwd)
	fi
	if [[ "$basename/$find_file" == $try_file ]] ; then
	  echo "$try_file"
	  return
	fi
      done
    done
  fi
  echo ""
}

# Turn filename $1 into something that is safe to use as a variable name
_Dbg_file2var() {
  local filename=$(_Dbg_expand_filename $1)
  local varname=`builtin echo $filename | tr '=~+%* .?/"[]<>-' 'ETPpABDQSqLRlGM'`
  builtin echo $varname
}

# $1 contains the name you want to glob. return 1 if exists and is
# readible or 0 if not. 
# The result will be in variable $filename which is assumed to be 
# local'd by the caller
_Dbg_glob_filename() {
  local cmd="filename=`expr $1`"
  eval $cmd
}

# Either fill out or strip filename as determined by "basename_only"
# and annotate settings
_Dbg_adjust_filename() {
  local -r filename="$1"
  if (( _Dbg_annotate == 1 )) ; then
    echo `_Dbg_resolve_expand_filename $filename`
  elif ((_Dbg_basename_only)) ; then
    echo ${filename##*/}
  else
    echo $filename
  fi
}

# Return the maximum line in $1
_Dbg_get_maxline() {
  # set -x
  local -r filename=$1
  local -r filevar=`_Dbg_file2var $filename`
  local is_read=`_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar`
  [ $is_read ] || _Dbg_readin $filename 
  echo `_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar`
  # set +x
}

# Check that line $2 is not greater than the number of lines in 
# file $1
_Dbg_check_line() {
  local -ir line_number=$1
  local filename=$2
  local -i max_line=`_Dbg_get_maxline $filename`
  if (( $line_number >  max_line )) ; then 
    (( _Dbg_basename_only )) && filename=${filename##*/}
    _Dbg_msg "Line $line_number is too large." \
      "File $filename has only $max_line lines."
    return 1
  fi
  return 0
}

# Create temporary file based on $1
# file $1
_Dbg_tempname() {
  echo "$_Dbg_tmpdir/bashdb$1$$"
}

# append a command into journal file and then run the command.
_Dbg_write_journal_eval() {
  _Dbg_write_journal "$*" 
  eval "$*"
}

# append a command into journal file and then run the command.
_Dbg_write_journal_var() {
  local var_name=$1
  local val
  local val_cmd="$val=\${$var_name}"
  eval $val_cmd
  _Dbg_write_journal "${var_name}=${val}" 
}

_Dbg_write_journal_avar() {
  local decl_str=$(declare -p $1)
  local -a decl_a
  decl_a=($decl_str)
  local -a decl_a2
  decl_a2=${decl_a[@]:2}
  _Dbg_write_journal ${decl_a2[@]}
}

# Append a command into journal file. But we only need to do
# if we are in a subshell.
_Dbg_write_journal() {
  if (( $BASH_SUBSHELL != 0 )) ; then
    echo "$@" >> ${_Dbg_journal} 2>/dev/null
  fi
  # return $?
}

# Remove all journal files.
_Dbg_erase_journals() {
  rm ${_Dbg_journal} 2>/dev/null
}

# read in or "source" in journal file which will set variables.
_Dbg_source_journal() {

  if [ -r $_Dbg_journal ] ; then 
    . $_Dbg_journal
    (( BASH_SUBSHELL == 0 )) && _Dbg_erase_journals
  fi
}

# This is put at the so we have something at the end when we debug this.
typeset -r _Dbg_file_ver=\
'$Id: dbg-file.inc,v 1.5 2006/12/19 20:06:46 rockyb Exp $'

#;;; Local Variables: ***
#;;; mode:shell-script ***
#;;; eval: (sh-set-shell "bash") ***
#;;; End: ***
