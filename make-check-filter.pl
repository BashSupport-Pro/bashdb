#!/usr/bin/env perl
# Use this to cut out the crud from make check.
# Use like this:
#   make check 2>&1  | perl ./make-check-filter.pl
# See Makefile.am
my @pats = (
    '^make',
    '^remake[',
    '^(re)?make\s+',
    "^Reading ",
    "^Making check in",
    '\(cd \.\.',
    "make -C",
    '^\s*$',
    '##[<>]+$'
    );

# puts pats
my $skip_re = join('|', @pats);

while (<>) {
    next if $_ =~ /${skip_re}/;
    print "$_";
}
