#!/bin/bash
typeset -i rc=0
SH_PROG=${SH_PROG:-$SHELL}
SH_PROG=${SH_PROG:-bash}
bash_loc=$($SH_PROG -c 'echo ${SHELL}')
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

main_loc=$(dirname $bashdb_main)

# Strip expected suffixes we would find in main_loc:
# In particular <prefix>/share/bashdb/ -> <prefix>
bashdb_loc=${main_loc%/bashdb}
prefix_loc=${bashdb_loc%/share}
echo $prefix_loc
exit 0
