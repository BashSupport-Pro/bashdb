pkgdatadir        = ${datadir}/@PACKAGE@/builtin
bindir            = ${datadir}/@PACKAGE@/builtin
if BUILD_BUILTINS
pkgdata_DATA      = set0
bin_PROGRAMS      = set0
noinst_PROGRAMS   = set0

set0_SOURCES =  set0.c
set0_CFLAGS  =  -I @BASH_SRC@ -I @BASH_SRC@/include -I@BASH_SRC@/builtins @PIC@
set0_LDFLAGS =  -shared
set0_builtin =  set0

set0$(EXEEXT): $(set0_OBJECTS) $(set0_DEPENDENCIES) 
	@rm -f $@
	$(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@ \
	    $(set0_LDFLAGS) $(set0_OBJECTS) $(set0_LDADD) $(LIBS)

endif
