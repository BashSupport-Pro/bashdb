#!/usr/bin/env ruby
# Use this to cut out the crud from make check.
# Use like this:
#   make check 2>&1  | ruby ../make-check-filter.rb
# See Makefile.am
pats = '(' +
  [
   '^(re)?make\[',
   "^(re)?make ",
   "Making check in",
   '^m4/',              # doesn't work always
   '^configure.ac',     # doesn't work always
   '^ cd \.\.',         # doesn't work always
   '^config.status',    # doesn't work always
   'config\.status:',    # doesn't work always
   '^shunit2: ',
   '^##<<+$',
   '^##>>+$',
   '`.+\' is up to date.$',
   '^\s*$',
  ].join('|') + ')'
# puts pats
skip_re = /#{pats}/

while gets()
  next if $_.encode!('UTF-8', 'binary',
                     invalid: :replace, undef: :replace, replace: '') =~ skip_re
  puts $_
end
