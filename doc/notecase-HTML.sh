#
#  Ed-based script to convert notecase.ncd tree structure -> HTML active web-based tree
#
#  This is a shell script for a linux or Cygwin operating system
#   Select the script (ONLY the script, if copying this from the HTML tree) and 
#     save it as your shell script, perhaps notecase-HTML.sh
#   It will check there's an 'ed' on your system when it runs.
#   Help available with the --help switch.
#   
#     Feedback etc to the rod<at>rodericksmith<dot>plus<dot>com , please
#
# By: Rod Smith    rod<at>rodericksmith<dot>plus<dot>com
#   Integration licensed under the GNU / MIT licences.
#
versionNumber="0.01, February 2010"
#
helpmsg="
 Help on notecase-HTML $version 
 
 Usage - notecase-HTML [-dbg] [-noframes] [sourceFile] [destinationFile] 

The script converts Notecase .ncd files to an active HTML tree
If sourceFile is missing, assume m.ncd
	if m.ncd doesn\'t exist, print this message
If destinationFile is missing, assume: \n sourcefile[less .ncd extension, plus .html extension] 

Any additional HTML in the Notecase must start with a line containing < [ html ] > with the spaces removed
  and end with a line containing </[html]>.  It's case sensitive.
"
#  First check the host operating system has ED installed
#
 if [ ! ed <<<Q ] ; then echo The ' ed ' editor isn\'t installed.  Please download and install it. ; quit;  fi
#
# Configure the command line options for the debug option
#
if   [ x$1 == x-dbg ] ; then shift ; a=dbg ; fi
#
if   [ x$1 == x-noframes ] ; then shift ; b=noframes ; fi
#
# Any other flag in the first paramter location triggers online help
echo $1;
if   [ x$1 == x--help ] ; then echo "$helpmsg" ; exit; fi
#
# Action on missing source file parameter -- (a) assume m.mcd  - if not found, give help message and quit
#
sourceFile=$1 ; destFile=$2
if   [ x$sourceFile == x ] ; then 
	if [ -e m.ncd ] ; then 
		sourceFile=m.ncd ; echo No start file specified -- using $sourceFile ; 
	else  echo -e $"helpmsg" ; exit ; fi ;
fi 
#
#		See http://tldp.org/LDP/abs/html/refcards.html#AEN22098 for the fancy string operations
# Verify the extension of the sourcefile is .ncd
#
if [ XX${sourceFile##*\.} != XXncd ] && [ XX${sourceFile##*\.} != XXNCD ] ; then
	echo notecase-HTML: Source file \($sourceFile\) extension must be ncd or NCD ;
  echo "$helpmsg" exit;
fi
#
# Check the source file exists, quit if not
#
if [ -e $sourceFile ] ; then echo $sourceFile : $a ; else echo notecase-HTML: $sourceFile - file not Found ; exit ; fi
#
# Extract the base filename without the extension, add HTML suffix
#
if [ x$2 == x ] ; then 
	destFile=`echo ${sourceFile%\.*}.HTML` ;
else 
	destFile=$2 ;
fi ;
#
echo Destination=$destFile ;
#
# Check for rogue strings. £ used since Notecase escapes it, so ncd string differs
#  since Notecase escapes it, and the ncd string would be \&pound
#
if   `grep £NOT $sourceFile >/dev/null`   ; then
	echo ------------- ;
	echo Rogue string £NOT lies in the file $sourceFile; echo
	grep -Hn £NOT $sourceFile ;
	echo ------------- ;echo; echo Run aborted -- unpredictable results.
	exit
 fi
#
if [ -f tmp_notecase.html ] ; then
	echo notecase-HTML: A temporary file tmp_notecase.html exists ;
	echo probably from a previous run of this  command.  ;
	echo Please delete it and re-run me. ;
	exit ;
fi
#
#
# Create the editing script, to be fed as commands to ED
#

  editingCommands=`cat -v <<"!endscript"
#
#enable debug messages
#
H
# Replace the .ncd source text prior to <TITLE>
# (the dummy command prevents printing line)
/TITLE/s/^//
1,.-1d
#
# Insert new header to include the javascript files needed from in-line text (terminates witha solitary . on a line)
#
i
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.0//EN"
                      "http://www.wapforum.org/DTD/xhtml-mobile10.dtd">
<html>
<head>
<!-- First try the local URL/file system -->
<script type="text/javascript">
      /* only load locally if not already present locally */
      var jQueryLoadedFrom="";
      if(typeof jQuery == 'function') jQueryLoadedFrom="already loaded";
      else
      document.write("<script type=\"text/javascript\" src=\"jquery-1.4.1.min.js\"></"+"script>");
</script>
<script type="text/javascript">                                  
      /* only load jQuery from Google if not present locally */
      var jQueryLoadedFrom="";
      if(typeof jQuery == 'function' && jQueryLoadedFrom == "") jQueryLoadedFrom="local url";
      else
      document.write("<script type=\"text/javascript\" src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js\"></"+"script>");
</script>

<script type="text/javascript">        
      /* if Google is down */
      if(typeof jQuery == 'function' && jQueryLoadedFrom == "") jQueryLoadedFrom="Google url";
      else
      document.write("<script type=\"text/javascript\" src=\"/lib/js/jquery.min.js\"></"+"script>");

</script>
<script type="text/javascript">    
 diagnostics="";
if(typeof jQuery == 'function')
 {  if(jQueryLoadedFrom == "") jQueryLoadedFrom="jQuery url";
 }
else  { jQueryLoadedFrom ="nowhere";
       diagnostics=" ++++ jQuery library inaccessible, so only a passive list is visible."
       diagnostics=diagnostics+"<br>For offline use, please download from <br> http://code.jquery.com/jquery-1.4.1.min.js";
       diagnostics=diagnostics+"<br> Then copy it into my local url as file named jquery-1.4.1.min.js";
              diagnostics=diagnostics+"<br>"+diagnostics+"<br>++++<br>"
       }
var plaudits=" Integrated by <a href=\"http://www.rodericksmith.plus.com\">Rod Smith.</a> "
    plaudits=plaudits+"jQuery libs loaded from: "+jQueryLoadedFrom+". " ;
    plaudits=plaudits+"   Version:"+"notecase_HTML_versionNumber";
    document.write(plaudits+diagnostics);

</script>

<script></script>
.
#
# end of inserted header
#
# Insert style sheet
a
<style type="text/css" > ul {
    list-style: none;
    margin: 0;
    padding: 0;
}
li {
    /*background-image: url(page.png);*/
    background-image: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAINSURBVBgZBcG/r55zGAfg6/4+z3va01NHlYgzEfE7MdCIGISFgS4Gk8ViYyM2Mdlsko4GSf8Do0FLRCIkghhYJA3aVBtEz3nP89wf11VJvPDepdd390+8Nso5nESBQoq0pfvXm9fzWf19453LF85vASqJlz748vInb517dIw6EyYBIIG49u+xi9/c9MdvR//99MPPZ7+4cP4IZhhTPbwzT2d+vGoaVRRp1rRliVvHq+cfvM3TD82+7mun0o/ceO7NT+/4/KOXjwZU1ekk0840bAZzMQ2mooqh0A72d5x/6sB9D5zYnff3PoYBoWBgFKPKqDKqjCpjKr//dcu9p489dra88cydps30KswACfNEKanSaxhlntjJ8Mv12Paie+vZ+0+oeSwwQ0Iw1xAR1CiFNJkGO4wu3ZMY1AAzBI0qSgmCNJsJUEOtJSMaCTBDLyQ0CknAGOgyTyFFiLI2awMzdEcSQgSAAKVUmAeNkxvWJWCGtVlDmgYQ0GFtgg4pNtOwbBcwQy/Rife/2yrRRVI0qYCEBly8Z+P4qMEMy7JaVw72N568e+iwhrXoECQkfH91kY7jwwXMsBx1L93ZruqrK6uuiAIdSnTIKKPLPFcvay8ww/Hh+ufeznTXu49v95IMoQG3784gYXdTqvRmqn/Wpa/ADFX58MW3L71SVU9ETgEIQQQIOOzub+fhIvwPRDgeVjWDahIAAAAASUVORK5CYII=");
        background-position: 0 1px;
    background-repeat: no-repeat;
    padding-left: 20px;
}
li.folder {
    /*background-image: url(folder.png); */
    background-image:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGrSURBVDjLxZO7ihRBFIa/6u0ZW7GHBUV0UQQTZzd3QdhMQxOfwMRXEANBMNQX0MzAzFAwEzHwARbNFDdwEd31Mj3X7a6uOr9BtzNjYjKBJ6nicP7v3KqcJFaxhBVtZUAK8OHlld2st7Xl3DJPVONP+zEUV4HqL5UDYHr5xvuQAjgl/Qs7TzvOOVAjxjlC+ePSwe6DfbVegLVuT4r14eTr6zvA8xSAoBLzx6pvj4l+DZIezuVkG9fY2H7YRQIMZIBwycmzH1/s3F8AapfIPNF3kQk7+kw9PWBy+IZOdg5Ug3mkAATy/t0usovzGeCUWTjCz0B+Sj0ekfdvkZ3abBv+U4GaCtJ1iEm6ANQJ6fEzrG/engcKw/wXQvEKxSEKQxRGKE7Izt+DSiwBJMUSm71rguMYhQKrBygOIRStf4TiFFRBvbRGKiQLWP29yRSHKBTtfdBmHs0BUpgvtgF4yRFR+NUKi0XZcYjCeCG2smkzLAHkbRBmP0/Uk26O5YnUActBp1GsAI+S5nRJJJal5K1aAMrq0d6Tm9uI6zjyf75dAe6tx/SsWeD//o2/Ab6IH3/h25pOAAAAAElFTkSuQmCC)
}
a {
    color: #000080;
    cursor: pointer;
    text-decoration: underline;
}
a:hover {
    text-decoration: underline;
}
</style>
.
# Insert the javascript file folding.js (relatively small)
a
<script type="text/javascript">
function activateTree() {

    // Find list items representing folders and
    // style them accordingly.  Also, turn them
    // into links that can expand/collapse the
    // tree leaf.
    $('li > ul').each(function(i) {
        // Find this list's parent list item.
        var parent_li = $(this).parent('li');

        // Style the list item as folder.
        parent_li.addClass('folder');

        // Temporarily remove the list from the
        // parent list item, wrap the remaining
        // text in an anchor, then reattach it.
        var sub_ul = $(this).remove();
        parent_li.wrapInner('<a/>').find('a').click(function() {
            // Make the anchor toggle the leaf display.
            sub_ul.toggle();
        });
        parent_li.append(sub_ul);
    });

    // Hide all lists except the outermost.
    $('ul ul').hide();
}
$(function() activateTree() );
window.onerror="none";
</script>
.
# Replace occurrences of escape character ¬ (a mathematical NOT), in the source
#
# Replace occurrences of escape characters {} ¬ (a maths NOT), in the source
#
g/¬/s/¬/£NOT/g
g/{/s/{/£Lbrace/g
g/}/s/}/£Rbrace/g
#
# Remove comments specific to Notecase -- dates, folder image defs
#
g/<!--/d
# delete all null lines or whitespace
g/^ *$/d
#
# identify (most) blank frames
#	After each title ends, prepend a marker to the following line
#     OR      a title ends </DT> followed immeditely by a list ending </DL>
#
# Put a marker 1 line after each definition title . .
#
g/<\/DT>$/  .+1s/^/¬/
#
# In both cases -- start of another folder title (<DT>) or end of a 
#   definition list (</DL>), prepend the closing actions for:
#    the frame text list item (</li>)
#    the list that defines the frame text (</ul>)
#    the node's own list item (</li>)#    
#
g/^¬/ s/¬<DT>/{|oooo|}<\/li><\/ul><\/li><DT>/
g/^¬/ s/¬<\/DL>/{|oooo|}<\/li><\/ul><\/li><\/DL>/
#
# Extra optional diagnostic to see what's left after titles . . .
#g/^¬/p
#
# END OF TABLE MARKS
##  g/^¬/p  # commented out -- its for a debugging check
#
# End of node description (RHS) marks: 
#  These may end with <\DD> OR with <DL>.  We need to distinguish the two.
#	So, we     
#
# Place ¬ markers after each RHS frame
#
,s/<\/DD>/¬&/
,s/<DL>/¬&/
#
#  Insert end-of-table at end of each RHS frame (each RHS starts with <DD> )
#
#  After every <DD>, look for the single first subsequent ¬ marker, and double that marker
#
g/<DD>/ /¬/s/¬/¬¬/
#
# On those double markers only
#
#
g/¬¬<DL>/ s/¬¬<DL>/<\/td><\/tr><\/table> <\/li>{|+DL|}/
g/¬¬<\/DD>/s/¬¬<\/DD>/<\/td><\/tr><\/table> <\/li>{|-dd|}<\/ul> <\/li> /
#
# clean up -- remove markers
#
,s/¬//g
#
# Definition list maps to unordered list, at the start of any node
#
,s/<DL>/{| +DL |}<ul> /g
#
# Insert start-of-table for RHS frame
#
,s/<DD>/{|+DD|}<table border="1" cellpadding="1" cellspacing="0" bordercolor="#80E0E0" ><tr><td>/g
#
# 
g/<\/DL>/s/<\/DL>/{|-dl|}<\/ul>  /g
g/<\/DD>/s/<\/DD>/{|-dd|}<\/li>  /g
#
# DT   -- always surrounds node title
#       ( HTML title in a definiton list )
#
#         -- generate a list item <li> to hold the node and sub-nodes
#
,s/<DT>/{|+DT|}<li> /g
#
# /DT   -- always ends a node title.  When his occurs, we must:
#         -- start a list ( <ul> ) to contain any subnodes and node's own text
#         -- start a list item ( <li> ) to contain the node text
#         --- we'll only know if its needed by lack of a definition list <DL>
#         -- these are put onto separate lines to ease debugging on a folding editor
#
,s/<\/DT>/{|-dt|}\\
	<ul> \\
	<li> /g
#
# Put all the table (RHS) opening into a single line to improve readability of HTML as text
#   and allow detection of empty table (RHS)
#
g/<table/.,.+1j
#
# Remove any empty tables of RHS text -- otherwise ghosted tables appear in HTML
#
## g/<td><\/td>/.-1,.p
g/<td><\/td>/.-1s/<li>//
g/<td><\/td>/.d
#
# then kill any blank lines
#
g/^$/d
#
# Restore occurrences of escape characters in the source
#
g/£NOT/s/£NOT/¬/g
g/£Lbrace/s/£Lbrace/{/g
g/£Rbrace/s/£Rbrace/}/g
#
# Save the modified text
#
w tmp_notecase.HTML
# (End of inline script)
q
!endscript
`

echo This is Version: $versionNumber
editingCommands=`sed "s/notecase_HTML_versionNumber/  $versionNumber/" <<<"$editingCommands"` ;

# --------------------------------------------------------  
#
# Remove debug tag (enclosed in braces) insertion when not debugging
# End of immediate string MUST BE QUOTED
# see http://tldp.org/LDP/abs/html/here-docs.html
#
if [ x$a != xdbg ] ; then
echo Removing debugging commands;
editingCommands=`sed 's/{|.*|}//g' <<<"$editingCommands"` ;
fi ;
if [ x$b == xnoframes ] ;  then
echo Removing frame commands;

editingCommands=`sed 's/<\/td><\/tr><\/table>//g' <<<"$editingCommands"` ;
editingCommands=`sed 's/<table .*<td>//g' <<<"$editingCommands"` ;
#
# editingCommands=`sed '/td>/d' <<<"$editingCommands"` ;
fi ;
#


# --------------------------------------------------------

ed $sourceFile <<<"$editingCommands"
#
#
# Fix up any HTML that embedded in .ncd's source
#
#
if   grep -n "&lt;\[html\]&gt;" <tmp_notecase.HTML >/dev/null ; then
if   grep -n "&lt;\/\[html\]&gt;" <tmp_notecase.HTML >/dev/null ; then
   echo Processing embedded HTML;
   if [ XX$b == XX ] ; then echo -e \\n You may want to use -noframes to improve the layout \\n\\n ; fi
   (     ed tmp_notecase.HTML <<!
# Fix between start and end on different lines
#
g/&lt;\[html\]&gt;/.,/&lt;\/\[html\]&gt;/s/&lt;/</g
g/<\[html\]&gt;/.,/<\/\[html\]&gt;/ s/&gt;/>/g
g/<\[html\]>/.,/<\/\[html\]>/ s/&quot;/\"/g
#
g/<\[html\]>/ s/<\[html\]>/<html>/g
g/<\[\/html\]>/ s/<\/\[html\]>/<\/html>//g
#
wq
!
#
   ) ;
   else echo  No unusual HTML in file
   fi ;
   fi;

#
#
# Give the destination file to its proper name
mv tmp_notecase.HTML $destFile
#
exit
#
---------------------------------------------------------------------------------------------------------
#  Explanation of the conversion process
#
# DL   ( HTML: defines a list)
#
#
#  DD -- precedes text. /dd OR DL ends the text.  /dd ends list level
#            DL always ends text, OR starts whole body
#       ( HTML description in a definiton list )
#
#
# DT   -- always surrounds node name
#       ( HTML title in a definiton list )
#
