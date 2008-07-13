pkgdatadir        = ${prefix}/share/bashdb/builtin
bindir            = ${prefix}/share/bashdb/builtin
if BUILD_BUILTINS
pkgdata_DATA      = readarray set0
bin_PROGRAMS      =  readarray set0
noinst_PROGRAMS   =  readarray set0
readarray_SOURCES =  readarray.c
readarray_CFLAGS  =  -I @BASH_SRC@ -I @BASH_SRC@/include -I@BASH_SRC@/builtins @PIC@
readarray_LDFLAGS =  -shared

readarray$(EXEEXT): $(readarray_OBJECTS) $(readarray_DEPENDENCIES) 
	@rm -f readarray$(EXEEXT)
	$(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@ \
	    $(readarray_LDFLAGS) $(readarray_OBJECTS) $(readarray_LDADD) $(LIBS)

set0_SOURCES =  set0.c
set0_CFLAGS  =  -I @BASH_SRC@ -I @BASH_SRC@/include -I@BASH_SRC@/builtins @PIC@
set0_LDFLAGS =  -shared
set0_builtin =  set0

set0$(EXEEXT): $(set0_OBJECTS) $(set0_DEPENDENCIES) 
	@rm -f readarray$(EXEEXT)
	$(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@ \
	    $(set0_LDFLAGS) $(set0_OBJECTS) $(set0_LDADD) $(LIBS)

endif
