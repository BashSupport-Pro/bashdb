#!/bin/bash
typeset -i rc=0
if (( $# > 0 )); then
    bash_loc="$1"
elif [[ -n $SH_PROG ]] ; then
    bash_loc=$SH_PROG
else
    SH_PROG=${SHELL:-bash}
    bash_loc=$($SH_PROG -c 'echo ${SHELL}')
fi
rc=$?
if (( rc != 0 )) ; then
    echo  >&2 "Something went wrong in getting \$SHELL for $SH_PROG"
    exit $rc
fi
if [[ -z $bash_loc ]] ; then
    echo  >&2 "Something went wrong in setting bash location from \$SHELL for $SH_PROG"
    exit 3
fi
# export PATH=/usr/bin:/bin:/sbin
bashdb_main=$(strings $bash_loc | grep bashdb)
if (( $? != 0 )); then
    echo  >&2 "Something went wrong in finding bashdb location from \$SHELL for $SH_PROG"
    exit 4
fi

main_loc=$(dirname $bashdb_main)

# Strip expected suffixes we would find in main_loc:
# In particular <prefix>/share/bashdb/ -> <prefix>
bashdb_loc=${main_loc%/bashdb}
prefix_loc=${bashdb_loc%/share}
echo $prefix_loc
exit 0
