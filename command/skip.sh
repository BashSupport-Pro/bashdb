# -*- shell-script -*-
# gdb-like "skip" (step over) commmand.
#
#   Copyright (C) 2010, 2011, 2017 Rocky Bernstein <rocky@gnu.org>
#
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation; either version 2, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; see the file COPYING.  If not, write to
#   the Free Software Foundation, 59 Temple Place, Suite 330, Boston,
#   MA 02111 USA.

_Dbg_help_add skip \
"**skip** [*count*]

Skip (don't run) the next *count* command(s).

If *count* is given, stepping occurs that many times before
stopping. Otherwise *count* is one. *count* can be an arithmetic
expression.

Note that skipping doesn't change the value of $? which may
cause some confusion.
See http://lists.gnu.org/archive/html/bug-bash/2017-04/msg00004.html

See also:
---------

**next** and **step**.
"

_Dbg_do_skip() {
    _Dbg_last_cmd='skip'
    _Dbg_next_skip_common 1 $*
    return $?
}
