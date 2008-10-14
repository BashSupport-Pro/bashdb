# -*- shell-script -*-
# Things related to file handling.
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2008 Rocky Bernstein 
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

# Directory search patch for unqualified file names
typeset -a _Dbg_dir=('\$cdir' '\$cwd' )

# Directory in which the script is located
[[ -z ${_Dbg_cdir} ]] && [[ -n ${_Dbg_cdir} ]] && typeset -r _Dbg_cdir=${_Dbg_source_file%/*}

# See if we have compiled the readarray builtin. This speeds up reading
# files into a bash array.
typeset -i _Dbg_have_readarray=0

if [[ -r $_Dbg_libdir/builtin/readarray ]] ; then
  if enable -f $_Dbg_libdir/builtin/readarray  readarray >/dev/null 2>&1 ; then
    _Dbg_have_readarray=1
  fi
fi

#
# Resolve $1 to a full file name which exists. First see if filename has been
# mentioned in a debugger "file" command. If not and the file name
# is a relative name use _Dbg_dir to substitute a relative directory name.
#
function _Dbg_resolve_expand_filename {

  if (( $# == 0 )) ; then
    _Dbg_errmsg "Internal debug error: null file to find"
    echo ''
    return 1
  fi
  typeset find_file="$1"

  # Is this one of the files we've that has been specified in a debugger
  # "FILE" command?
  typeset -r filevar=$(_Dbg_file2var $find_file)
  typeset file_cmd_file=$(_Dbg_get_assoc_scalar_entry "_Dbg_file_cmd_" $filevar)
  if [[ -n "$file_cmd_file" ]] ; then
    echo "$file_cmd_file"
    return 0
  fi

  if [[ ${find_file:0:1} == '/' ]] ; then 
    # Absolute file name
    full_find_file=$(_Dbg_expand_filename $find_file)
    echo "$full_find_file"
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
    typeset -i n=${#_Dbg_dir[@]}
    typeset -i i
    for (( i=0 ; i < n; i++ )) ; do
      typeset basename="${_Dbg_dir[i]}"
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
  echo ''
  return 1
}

# _Dbg_is_file echoes the full filename if $1 is a filename found in files
# '' is echo'd if no file found.
function _Dbg_is_file {
  typeset find_file=$1

  if [[ -z $find_file ]] ; then
    _Dbg_errmsg "Internal debug error: null file to find"
    echo ''
    return
  fi

  if [[ ${find_file:0:1} == '/' ]] ; then 
    # Absolute file name
      full_find_file=$(_Dbg_resolve_expand_filename $find_file)
      for try_file in ${_Dbg_filenames[@]} ; do 
	  if [[ $try_file == $full_find_file ]] ; then
	      echo "$full_find_file"
	      return 0
	  fi
      done
  elif [[ ${find_file:0:1} == '.' ]] ; then
    # Relative file name
    find_file=$(_Dbg_expand_filename ${_Dbg_init_cwd}/$find_file)
    for try_file in ${_Dbg_filenames[@]} ; do 
      if [[ $try_file == $find_file ]] ; then
	  full_find_file=$(_Dbg_resolve_expand_filename $find_file)
	  echo "$full_find_file"
	  return 0
      fi
    done
  else
    # Resolve file using _Dbg_dir
    for try_file in ${_Dbg_filenames[@]} ; do 
      typeset pathname
      typeset -i n=${#_Dbg_dir[@]}
      typeset -i i
      for (( i=0 ; i < n; i++ )) ; do
	typeset basename="${_Dbg_dir[i]}"
	if [[  $basename = '\$cdir' ]] ; then
	  basename=$_Dbg_cdir
	elif [[ $basename = '\$cwd' ]] ; then
	  basename=$(pwd)
	fi
	if [[ "$basename/$find_file" == $try_file ]] ; then
	  echo "$try_file"
	  return 0
	fi
      done
    done
  fi
  echo ""
  return 1
}

# Turn filename $1 into something that is safe to use as a variable name
_Dbg_file2var() {
  typeset filename=$(_Dbg_expand_filename $1)
  typeset varname=`builtin echo $filename | tr '=~+%* .?/"[]<>-' 'ETPpABDQSqLRlGM'`
  builtin echo $varname
}

# $1 contains the name you want to glob. return 1 if exists and is
# readible or 0 if not. 
# The result will be in variable $filename which is assumed to be 
# local'd by the caller
_Dbg_glob_filename() {
  typeset cmd="filename=$(expr $1)"
  eval $cmd
  [[ -r $filename ]]
}

# Either fill out or strip filename as determined by "basename_only"
# and annotate settings
_Dbg_adjust_filename() {
  typeset -r filename="$1"
  if (( _Dbg_annotate == 1 )) ; then
    echo $(_Dbg_resolve_expand_filename $filename)
  elif ((_Dbg_basename_only)) ; then
    echo ${filename##*/}
  else
    echo $filename
  fi
}

# Return the maximum line in $1
_Dbg_get_maxline() {
  typeset -r filename=$1
  typeset -r filevar=$(_Dbg_file2var $filename)
  typeset is_read=$(_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar)
  [ $is_read ] || _Dbg_readin $filename 
  echo $(_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar)
}

# Check that line $2 is not greater than the number of lines in 
# file $1
_Dbg_check_line() {
  typeset -ir line_number=$1
  typeset filename=$2
  typeset -i max_line=$(_Dbg_get_maxline $filename)
  if (( $line_number >  max_line )) ; then 
    (( _Dbg_basename_only )) && filename=${filename##*/}
    _Dbg_msg "Line $line_number is too large." \
      "File $filename has only $max_line lines."
    return 1
  fi
  return 0
}

# Read $1 into _source_$1 array.  Variable _Dbg_read_$1 will be set
# to 1 to note that the file has been read and the filename will be saved
# in array _Dbg_filenames

function _Dbg_readin {
  typeset filename=${1:-$_Dbg_frame_last_filename}

  typeset -i line_count=0
  typeset filevar
  typeset source_array
  typeset -ir NOT_SMALLFILE=1000

  if [[ -z filename ]] || [[ filename == _Dbg_bogus_file ]] ; then 
    filevar='ABOGUSA'
    source_array="_Dbg_source_${filevar}"
    typeset cmd="${source_array}[0]=\"$_Dbg_EXECUTION_STRING\""
    eval $cmd

  else 
    typeset fullname=$(_Dbg_resolve_expand_filename $filename)
    filevar=`_Dbg_file2var $filename`
    if [[ -r $fullname ]] ; then
      typeset -r progress_prefix="Reading $filename"
      source_array="_Dbg_source_${filevar}"
      if (( 0 != $_Dbg_have_readarray )); then
	# If we have readarray that speeds up reading greatly. Use it.
	typeset -ir BIGFILE=30000
	if wc -l < /dev/null >/dev/null 2>&1 ; then 
	  line_count=`wc -l < "${fullname}"`
	  if (( $line_count >= $NOT_SMALLFILE )) ; then 
	    _Dbg_msg_nocr "${progress_prefix} "
	  fi
	fi
	builtin readarray -t -O 1 -c $BIGFILE \
	  -C "_Dbg_progess_show \"${progress_prefix}\" ${line_count}" \
	  $source_array < $fullname 
	(( line_count > BIGFILE)) && _Dbg_progess_done
	
      else
	# No readarray. Do things the long way.
	typeset -i i
	for (( i=1; 1 ; i++ )) ; do 
	  typeset source_entry="${source_array}[$i]"
	  typeset readline_cmd="read -r $source_entry; rc=\$?";
	  typeset -i rc=1
	  if (( i % 1000 == 0 )) ; then
	    if (( i==NOT_SMALLFILE )) ; then
	      if wc -l < /dev/null >/dev/null 2>&1 ; then 
		line_count=$(wc -l < "${fullname}")
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
	typeset -r remove_last_index_cmd="unset $source_array[$i]"
	eval $remove_last_index_cmd
	(( line_count != 0 )) && _Dbg_progess_done
      fi
    else
	return
    fi
  fi

  typeset -r line_count_cmd="line_count=\${#$source_array[@]}"
  eval $line_count_cmd

  (( line_count >= NOT_SMALLFILE )) && _Dbg_msg "done."

  _Dbg_set_assoc_scalar_entry "_Dbg_read_" $filevar 1
  _Dbg_set_assoc_scalar_entry "_Dbg_maxline_" $filevar $line_count
  
  # Add $filename to list of all filenames
  _Dbg_filenames[${#_Dbg_filenames[@]}]=$fullname;
}

# This is put at the so we have something at the end when we debug this.
[[ -z _Dbg_file_ver ]] && typeset -r _Dbg_file_ver=\
'$Id: file.sh,v 1.6 2008/10/14 01:16:28 rockyb Exp $'
