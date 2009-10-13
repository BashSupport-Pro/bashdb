# -*- shell-script -*-
# Things related to file handling.
#
#   Copyright (C) 2002, 2003, 2004, 2006, 2008, 2009 Rocky Bernstein 
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

if ra=$(type -p readarray) && [ -z "$ra" ] ; then
    _Dbg_have_readarray=1
elif [[ -r $_Dbg_libdir/builtin/readarray ]] ; then
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
  typeset -r filevar=$(_Dbg_file2var "$find_file")
  typeset file_cmd_file=$(_Dbg_get_assoc_scalar_entry "_Dbg_file_cmd_" $filevar)
  if [[ -n "$file_cmd_file" ]] ; then
    echo "$file_cmd_file"
    return 0
  fi

  if [[ ${find_file:0:1} == '/' ]] ; then 
    # Absolute file name
    full_find_file=$(_Dbg_expand_filename "$find_file")
    echo "$full_find_file"
    return 0
  elif [[ ${find_file:0:1} == '.' ]] ; then
    # Relative file name
    full_find_file=$(_Dbg_expand_filename "${_Dbg_init_cwd}/$find_file")
    if [[ -z $full_find_file ]] || [[ ! -r $full_find_file ]]; then
      # Try using cwd rather that Dbg_init_cwd
      full_find_file=$(_Dbg_expand_filename "$find_file")
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

# Turn filename $1 into something that is safe to use as a variable name
_Dbg_file2var() {
  typeset filename=$(_Dbg_expand_filename "$1")
  typeset varname=$(builtin echo $filename | tr '=~+%* .?/"[]<>-' 'ETPpABDQSqLRlGM')
  builtin echo $varname
}

# $1 contains the name you want to glob. return 1 if exists and is
# readible or 0 if not. 
# The result will be in variable $filename which is assumed to be 
# local'd by the caller
_Dbg_glob_filename() {
  printf -v filename "%q" "$1"
  typeset cmd="filename=$filename"
  eval $cmd
  [[ -r $filename ]]
}

# Either fill out or strip filename as determined by "basename_only"
# and annotate settings
_Dbg_adjust_filename() {
  typeset -r filename=$1
  if (( _Dbg_annotate == 1 )) ; then
    echo $(_Dbg_resolve_expand_filename $filename)
  elif ((_Dbg_basename_only)) ; then
    echo ${filename##*/}
  else
    echo $filename
  fi
}
