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

echo $(dirname $(dirname $bashdb_main))
exit 0
