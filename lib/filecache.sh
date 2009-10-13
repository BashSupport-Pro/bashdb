# -*- shell-script -*-
# filecache.sh - cache file information
#
#   Copyright (C) 2009 Rocky Bernstein rocky@gnu.org
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
# Check that line $2 is not greater than the number of lines in 
# file $1

_Dbg_check_line() {
  typeset -ir line_number=$1
  typeset filename=$2
  typeset -i max_line=$(_Dbg_get_maxline "$filename")
  if (( $line_number >  max_line )) ; then 
    (( _Dbg_basename_only )) && filename=${filename##*/}
    _Dbg_msg "Line $line_number is too large." \
      "File $filename has only $max_line lines."
    return 1
  fi
  return 0
}

# Error message for file not read in
_Dbg_file_not_read_in() {
    typeset -r filename=$(_Dbg_adjust_filename "$filename")
    _Dbg_errmsg "File \"$filename\" not found in read-in files."
    _Dbg_errmsg "See 'info files' for a list of known files and"
    _Dbg_errmsg "'load' to read in a file."
}

# Return the maximum line in $1
_Dbg_get_maxline() {
  typeset -r filename="$1"
  typeset -r filevar=$(_Dbg_file2var "$filename")
  typeset is_read=$(_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar)
  [ $is_read ] || _Dbg_readin "$filename "
  echo $(_Dbg_get_assoc_scalar_entry "_Dbg_maxline_" $filevar)
}

# Return text for source line for line $1 of filename $2 in variable
# $source_line. The hope is that this has been declared "typeset" in the 
# caller.

# If $2 is omitted, # use _Dbg_frame_last_filename, if $1 is omitted use _curline.
function _Dbg_get_source_line {
  typeset lineno=${1:-$_curline}
  typeset filename=${2:-$_Dbg_frame_last_filename}
  typeset filevar=$(_Dbg_file2var "$filename")
  typeset is_read=$(_Dbg_get_assoc_scalar_entry "_Dbg_read_" $filevar)
  [[ $is_read ]] || _Dbg_readin "$filename"
  
  source_line=$(_Dbg_get_assoc_array_entry _Dbg_source_${filevar} $lineno)
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
      full_find_file=$(_Dbg_resolve_expand_filename "$find_file")
      typeset -i i
      for (( i=0 ; i<${#_Dbg_filenames[@]}; i++)) ; do 
	  if [[ ${_Dbg_filenames[i]} == $full_find_file ]] ; then
	      echo "$full_find_file"
	      return 0
	  fi
      done
  elif [[ ${find_file:0:1} == '.' ]] ; then
    # Relative file name
    find_file=$(_Dbg_expand_filename "${_Dbg_init_cwd}/$find_file")
    for (( i=0 ; i<${#_Dbg_filenames[@]}; i++)) ; do 
	if [[ ${_Dbg_filenames[i]} == $find_file ]] ; then
	    full_find_file=$(_Dbg_resolve_expand_filename "$find_file")
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
    typeset fullname=$(_Dbg_resolve_expand_filename "$filename")
    filevar=$(_Dbg_file2var "$filename")
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
	  $source_array < "$fullname"
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
	done  < "$fullname"
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
