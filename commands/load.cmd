_Dbg_do_load() {

  local filename=$1
  if [[ -z "$filename" ]] ; then
    _Dbg_msg "Need to give a filename for the file command"
    return
  fi
  local  full_filename=$(_Dbg_resolve_expand_filename "$filename")
  if [ -n $full_filename ] && [ -r $full_filename ] ; then 
    # Have we already loaded in this file?
    for file in ${_Dbg_filenames[@]} ; do  
       if [[ $file = $full_filename ]] ; then
         _Dbg_msg "File $full_filename already loaded."
	 return
       fi
    done

    _Dbg_readin "$full_filename"
    _Dbg_msg "File $full_filename loaded."
  else
      _Dbg_msg "Couldn't resolve or read $filename"
  fi
}
