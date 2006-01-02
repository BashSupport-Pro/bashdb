# Test break, watch, watche, step, next, continue and stack handling
# $Id: display.cmd,v 1.1 2006/01/02 23:34:26 rockyb Exp $
#
p "*** Try a simple display..."
display echo $x
break 23
break 25
cont
cont
p "*** Try disabling display ..."
disable display 0
info display
step
cont
p "*** Try enabling display ..."
enable display 0
info display
p "*** Try display to show again status ..."
display
cont 28
info display
cont
p "*** Try undisplay to delete ..."
undisplay 0
info display
step
step
p "*** quitting..."
quit
