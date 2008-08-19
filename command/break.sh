# Add breakpoint(s) at given line number of the current file.  $1 is
# the line number or _curline if omitted.  $2 is a condition to test
# for whether to stop.

_Dbg_help_add break \
'break [LOCSPEC]	-- Set a breakpoint on LOCSPEC. 
If no location specification is given, use the current line.'

_Dbg_do_break() {

  local -i is_temp=$1
  shift

  local n=${1:-$_curline}
  shift

  local condition=${1:-''};
  if [[ "$n" == 'if' ]]; then
    n=$_curline
  elif [[ -z $condition ]] ; then
    condition=1
  elif [[ $condition == 'if' ]] ; then
    shift
  fi
  if [[ -z $condition ]] ; then
    condition=1
  else 
    condition="$*"
  fi

  local filename
  local -i line_number
  local full_filename

  _Dbg_linespec_setup $n

  if [[ -n $full_filename ]]  ; then 
    if (( $line_number ==  0 )) ; then 
      _Dbg_msg "There is no line 0 to break at."
    else 
      _Dbg_check_line $line_number "$full_filename"
      (( $? == 0 )) && \
	_Dbg_set_brkpt "$full_filename" "$line_number" $is_temp "$condition"
    fi
  else
    _Dbg_file_not_read_in $filename
  fi
}

_Dbg_alias_add b break
