#!/bin/bash
# $Id: bug-args.sh,v 1.1 2006/11/29 23:12:51 rockyb Exp $
set a b c d e
shift 2
# At this point we shouldn't have a $5 or a $4
exit 0
