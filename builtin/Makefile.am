pkgdatadir        = ${datadir}/@PACKAGE@/builtin
bindir            = ${datadir}/@PACKAGE@/builtin
if BUILD_BUILTINS
pkgdata_DATA      = set0 readc
bin_PROGRAMS      = set0 readc
noinst_PROGRAMS   = set0 readc

set0_SOURCES =  set0.c
set0_CFLAGS  =  -I @BASH_SRC@ -I @BASH_SRC@/include -I@BASH_SRC@/builtins @PIC@
set0_LDFLAGS =  -shared
set0_builtin =  set0

set0$(EXEEXT): $(set0_OBJECTS) $(set0_DEPENDENCIES)
	@rm -f $@
	$(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@ \
	    $(set0_LDFLAGS) $(set0_OBJECTS) $(set0_LDADD) $(LIBS)


readc_SOURCES =  readc.c
readc_CFLAGS  =  -I @BASH_SRC@ -I @BASH_SRC@/include -I@BASH_SRC@/builtins @PIC@
readc_LDFLAGS =  -shared
readc_builtin =  readc

readc$(EXEEXT): $(readc_OBJECTS) $(readc_DEPENDENCIES)
	@rm -f $@
	$(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@ \
	    $(readc_LDFLAGS) $(readc_OBJECTS) $(readc_LDADD) $(LIBS)


endif
