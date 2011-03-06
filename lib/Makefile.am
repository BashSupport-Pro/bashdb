pkgdatadir        = ${datadir}/@PACKAGE@/lib
pkgdata_DATA =      	\
	action.sh    	\
	alias.sh    	\
	break.sh    	\
	columnize.sh  	\
	commands.sh  	\
	complete.sh  	\
	display.sh  	\
	dbg-call.sh  	\
	file.sh  	\
	filecache.sh  	\
	fns.sh  	\
	frame.sh        \
	help.sh    	\
	hook.sh    	\
	hist.sh    	\
	info.sh    	\
	journal.sh    	\
	list.sh    	\
	sort.sh    	\
	msg.sh    	\
	processor.sh  	\
	run.sh  	\
	save-restore.sh \
	setshow.sh      \
	shell.sh	\
	sig.sh	        \
	stepping.sh     \
	term-highlight.py \
	validate.sh

install-data-hook: 
	chmod +x $(DESTDIR)$(pkgdatadir)/term-highlight.py

EXTRA_DIST = $(pkgdata_DATA)
MOSTLYCLEANFILES = *.orig *.rej
