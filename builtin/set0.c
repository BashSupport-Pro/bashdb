/*   
  Extends bash with a builtin function to test if a name is defined or not.

  To install after compiling:
     cd *this directory* 
     enable -f ./set0 set0
*/

#include "builtins.h"
#include "shell.h"
#include <stdio.h>

char *set0_doc[] = {
  "Set $0.",
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

  dollar_vars[0] = savestring(list->word->word);
  return EXECUTION_FAILURE;
}

struct builtin set0_struct = {
  "set0",		/* builtin name */
  set0_builtin,	       /* function implementing the builtin */
  BUILTIN_ENABLED,	/* initial flags for builtin */
  set0_doc,		/* array of long documentation strings. */
  "set0 STRING",        /* usage synopsis; becomes short_doc */
  0			/* reserved for internal use */
};
