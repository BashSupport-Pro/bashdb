_Dbg_do_file() {

  typeset filename
  if [[ -z "$1" ]] ; then
    _Dbg_msg "Need to give a filename for the file command"
    return
  fi
  _Dbg_glob_filename $1
  if [[ ! -f "$filename" ]] && [[ ! -x "$filename" ]] ; then
    _Dbg_msg "Source file $filename does not exist as a readable regular file."
    return
  fi
  typeset filevar=$(_Dbg_file2var ${BASH_SOURCE[3]})
  _Dbg_set_assoc_scalar_entry "_Dbg_file_cmd_" $filevar "$filename"
  typeset source_file="${BASH_SOURCE[3]}"
  (( _Dbg_basename_only )) && source_file=${source_file##*/}
  _Dbg_msg "File $filename will be used when $source_file is referenced."
}
