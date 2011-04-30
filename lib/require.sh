if [[ -z $_Dbg_requires ]] ; then 
    function _Dbg_expand_filename {
	typeset -r filename="$1"
	
	# Break out basename and dirname
	typeset basename="${filename##*/}"
	typeset -x dirname="${filename%/*}"
	
	# No slash given in filename? Then use . for dirname
	[[ $dirname == $basename ]] && [[ $filename != '/' ]] && dirname='.'
	
	# Dirname is ''? Then use / for dirname
	dirname=${dirname:-/}
	
	# Handle tilde expansion in dirname
	dirname=$(echo $dirname)
	
	typeset long_path
	
	[[ $basename == '.' ]] && basename=''
	if long_path=$( (cd "$dirname" ; pwd) 2>/dev/null ) ; then
	    if [[ "$long_path" == '/' ]] ; then
		echo "/$basename"
	    else
		echo "$long_path/$basename"
	    fi
	    return 0
	else
	    echo $filename
	    return 1
	fi
    }

    typeset -A _Dbg_requires
    require() {
	typeset file 
	typeset expanded_file
	for file in "$@" ; do
	    expanded_file=$(_Dbg_expand_filename "$file")
	    if [[ -z ${_Dbg_requires[$file]} \
		&& -z ${_Dbg_requires[$expanded_file]} ]] ; then
		source $expanded_file
		_Dbg_requires[$file]=$expanded_file
		_Dbg_requires[$expanded_file]=$expanded_file
	    fi
	done
    }
fi

