#!/bin/bash

version="0.01";

fibonacci() {
    n=${1:?If you want the nth fibonacci number, you must supply n as the first parameter.}
    if [ $n -le 1 ]; then
    echo $n
    else
    l=`fibonacci $((n-1))`
    r=`fibonacci $((n-2))`
    echo $((l + r))
    fi
}

for i in 1 2
do
  result=$(fibonacci $i)
  echo "i=$i result=$result"
done
