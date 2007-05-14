##############################################################################
# $Id: Makefile.am,v 1.4 2007/05/14 00:37:49 rockyb Exp $
#  Copyright (C) 2003 Rocky Bernstein
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
man1_MANS = bashdb.$(EXT)

# bashdb.texi and bashdb.info are derived but are included to
# make "make distcheck" work.
EXTRA_DIST = $(man1_MANS) macros.texi \
	bashdb.info bashdb-man.pod bashdb-man.html

info_TEXINFOS = bashdb.texi 
bashdb_TEXINFOS = fdl.texi gpl.texi copyright.texi

all: $(INFO_DEPS) $(man1_MANS) html 

man: $(man1_MANS)

html: bashdb.html bashdb-man.html

bashdb.html: bashdb.texi
	texi2html $(srcdir)/bashdb.texi || true

bashdb-man.html: bashdb-man.pod
	pod2html --infile=$(srcdir)/bashdb-man.pod --outfile=$@

$(man1_MANS): bashdb-man.pod
	pod2man --release=$(PACKAGE_VERSION) --center="GNU Tools" --section=$(EXT) $(srcdir)/bashdb-man.pod >$@

%.ps.gz: %.ps
	gzip -9c $< > $@

.texi.pdf:
	$(TEXI2PDF) -I $(srcdir) $<

.texi.dvi:
	$(TEXI2DVI) -I $(srcdir) $<

.dvi.ps:
	test -d $(docdir) || mkdir $(docdir)
	$(DVIPS) $< -o $@

.texi.html:
	texi2html $< || true

.texi.txt:
	makeinfo --no-headers $< > $@

all-formats: pdf dvi txt ps html

MOSTLYCLEANFILES = bashdb.tgs bashdb.ps.gz bashdb.pdf bashdb.html bashdb_toc.html bashdb_foot.html $(man1_MANS) bashdb-man.html
