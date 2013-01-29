##############################################################################
# $Id: Makefile.am,v 1.5 2009/06/22 22:41:10 rockyb Exp $
#  Copyright (C) 2003, 2009 Rocky Bernstein
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##############################################################################

EXT=1
man1_MANS = @PACKAGE@.$(EXT)

# bashdb.texi and bashdb.info are derived but are included to
# make "make distcheck" work.
EXTRA_DIST = $(man1_MANS) macros.texi \
	@PACKAGE@.info @PACKAGE@-man.pod @PACKAGE@-man.html

info_TEXINFOS =  bashdb.texi 
bashdb_TEXINFOS = fdl.texi gpl.texi copyright.texi

all: $(INFO_DEPS) $(man1_MANS) html 

man: $(man1_MANS)

html: @PACKAGE@.html @PACKAGE@-man.html

@PACKAGE@.html: @PACKAGE@.texi
	texi2html $(srcdir)/@PACKAGE@.texi || true

@PACKAGE@-man.html: @PACKAGE@-man.pod
	pod2html --infile=$(srcdir)/@PACKAGE@-man.pod --outfile=$@

$(man1_MANS): @PACKAGE@-man.pod
	pod2man --release=$(PACKAGE_VERSION) --name=@PACKAGE@ --center="GNU Tools" --section=$(EXT) $(srcdir)/@PACKAGE@-man.pod >$@

#%.ps.gz: %.ps
#	gzip -9c $< > $@

.texi.pdf:
	$(TEXI2PDF) -I $(srcdir) $< || true

.texi.dvi:
	$(TEXI2DVI) -I $(srcdir) $< || true

.dvi.ps:
	test -d $(docdir) || mkdir $(docdir)
	$(DVIPS) $< -o $@

.texi.html:
	texi2html $< || true

.texi.txt:
	makeinfo --no-headers $< > $@

all-formats: pdf dvi txt ps html

MOSTLYCLEANFILES = @PACKAGE@.tgs @PACKAGE@.ps.gz @PACKAGE@.pdf @PACKAGE@.html @PACKAGE@_toc.html @PACKAGE@_foot.html $(man1_MANS) @PACKAGE@-man.html pod2htm?.tmp @PACKAGE@.info
