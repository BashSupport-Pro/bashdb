#!/bin/sh
echo "Start"
sub () {
   echo $@
   echo "1"
   echo "2"
   echo "3"
}

sub arg
echo "Stop!"
