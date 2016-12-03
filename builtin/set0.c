/*
# set0.c - Set $0, the program name.
#
#   Copyright (C) 2008, 2016 Rocky Bernstein  rocky@gnu.org
#
#   Bash is free software; you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any later
#   version.
#
#   Bash is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with Bash; see the file COPYING.  If not, write to the Free Software
#   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.
#

  To install after compiling:
     cd *this directory*
     enable -f ./set0 set0
*/

#include "builtins.h"
#include "shell.h"
#include <stdio.h>

char *set0_doc[] = {
  "Set $0, the program name.",
  NULL
};

/* See defined_doc string above for what this does. */
static int set0_builtin (WORD_LIST *list)
{
  SHELL_VAR *v;

  /* Check parameters: there should be exactly one. */
  if (list == 0) {
    builtin_error ("An argument (a variable name) is required.");
    builtin_usage ();
    return (EX_USAGE);
  } else if (list->next) {
    builtin_error ("More than one argument passed; we want exactly one.");
    builtin_usage ();
    return (EX_USAGE);
  }

  if (dollar_vars[0]) free (dollar_vars[0]);
  dollar_vars[0] = savestring(list->word->word);
  return EXECUTION_SUCCESS;
}

struct builtin set0_struct = {
  "set0",		/* builtin name */
  set0_builtin,	        /* function implementing the builtin */
  BUILTIN_ENABLED,	/* initial flags for builtin */
  set0_doc,		/* array of long documentation strings. */
  "set0 STRING",        /* usage synopsis; becomes short_doc */
  0			/* reserved for internal use */
};
