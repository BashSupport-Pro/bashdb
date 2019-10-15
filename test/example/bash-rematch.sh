#!/bin/bash
readonly REGEX='aa(b{2,3}[xyz])cc'
readonly DEF_VALID_ID='^[0-9]*$'
readonly DEF_REGEX_2='^=\ (.*)'
set -- .123 456 .789 aab aabbxcc aabbcc "= asd"
for ((i=1;i<=$#;i++));do
  if [[ "${!i}" =~ $DEF_VALID_ID || "${!i}" =~ $REGEX || "${!i}" =~ $DEF_REGEX_2 ]];then
    echo "${!i} matches"
    j=1
    n=${#BASH_REMATCH[*]}
    while [[ $j -lt $n ]];do
      echo "  capture[$j]: ${BASH_REMATCH[$j]}"
      ((j++))
    done
  else
    echo "${!i} does not match"
  fi
done
exit 0
