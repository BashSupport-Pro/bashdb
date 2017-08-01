#!/bin/bash
x=1

set -e

echo hi
(( 1 / 0))
exit 0
