/* $Id: readarray.c,v 1.1 2006/01/02 23:34:23 rockyb Exp $
   Copyright (C) 2005 Rocky Bernstein rocky@panix.com

   Bash is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2, or (at your option) any later
   version.

   Bash is distributed in the hope that it will be useful, but WITHOUT ANY
   WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.
   
   You should have received a copy of the GNU General Public License along
   with Bash; see the file COPYING.  If not, write to the Free Software
   Foundation, 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
/*
  readarray - copy file into an array. 
   We need to do this because reading line by line is very slow.
*/

#include "builtins.h"
#include "posixstat.h"
#include "filecntl.h"

#if defined (HAVE_UNISTD_H)
#  include <unistd.h>
#endif

#if defined (HAVE_STRING_H)
#  include <string.h>
#endif

#include "bashansi.h"

#include <stdio.h>
#include <errno.h>
#include "chartypes.h"

#include "shell.h"
#include "bashgetopt.h"

#if !defined (errno)
extern int errno;
#endif

extern int builtin_error ();
extern void builtin_usage (void);
extern int parse_and_execute (char *psz_exec, const char *psz_from_file, int flags);

/* Process options. In this case we're looking for 
   -n *number*.
*/
static void
munge_list (WORD_LIST *list)
{
  WORD_LIST *l, *nl;
  WORD_DESC *wd;
  char *arg;

  for (l = list; l; l = l->next)
    {
      arg = l->word->word;
      if (arg[0] != '-' || arg[1] == '-' || (DIGIT(arg[1]) == 0))
        return;
      /* We have -[0-9]* */
      wd = make_bare_word (arg+1);
      nl = make_word_list (wd, l->next);
      l->word->word[1] = 'n';
      l->word->word[2] = '\0';
      l->next = nl;
      l = nl;	/* skip over new argument */
    }
}

static int
read_array (FILE *fp, long int i_count, long int i_origin, long int i_chop,
	    long int i_cb, char *psz_cb, char *psz_var)
{
  char *psz_line = NULL;
  size_t i_len = 0;
  unsigned int i;
  unsigned int j = 0;
  SHELL_VAR *entry = var_lookup (psz_var, shell_variables);

  if (!entry)
    entry = make_new_array_variable (psz_var);
  else if (readonly_p (entry) || noassign_p (entry))
    {
      if (readonly_p (entry))
	err_readonly (psz_var);
      return (EX_USAGE);
    }
  else if (array_p (entry) == 0)
    entry = convert_var_to_array (entry);

  for (i=i_origin; -1 != getline(&psz_line, &i_len, fp); i++) {
    j++;

    /* Have we Exceded # of lines to store/ */
    if (j >= i_count) break;

    /* Remove trailing newlines? */
    if (i_chop) {
      int j=strlen(psz_line);
      if (j && '\n' == psz_line[j-1]) psz_line[j-1] = '\0';
    }

    /* Has a callback been registered and if so is it time to call it? */
    if (psz_cb && 0 == (j % i_cb)) {
      const unsigned int i_len = strlen(psz_cb)+10;
      char *psz_exec = calloc(i_len, sizeof(char));
      snprintf(psz_exec, i_len, "%s %d", psz_cb, i);
      parse_and_execute(psz_exec, NULL, 0);
    }

    /* ENTRY is an array variable, and ARRAY points to the value. */
    { char *newval;
      newval = make_variable_value (entry, psz_line, 0);
      if (entry->assign_func)
	(*entry->assign_func) (entry, newval, i);
      else
	array_insert (array_cell (entry), i, newval);
      free (newval);
    }
  }
  free(psz_line);
  return EXECUTION_SUCCESS;
}

int
readarray_builtin (WORD_LIST *list)
{
  long int i_line;
  long int i_origin = 0;
  long int i_chop   = 0;
  long int i_cb     = 5000;
  char    *psz_cb   = NULL;
  int i_opt;
  int rval = EXECUTION_SUCCESS;;
  FILE *fp;

  munge_list (list);	/* change -num into -n num */

  reset_internal_getopt ();
  i_line = 100000;
  while ((i_opt = internal_getopt (list, "tc:C:n:O:")) != -1)
    {
      switch (i_opt)
	{
	case 'n':
	  i_line = atoi (list_optarg);
	  if (i_line <= 0)
	    {
	      builtin_error ("bad line count: %s", list_optarg);
	      return (EX_USAGE);
	    }
	  break;
	case 'c':
	  i_cb = atoi (list_optarg);
	  if (i_cb <= 0)
	    {
	      builtin_error ("bad callback count: %s", list_optarg);
	      return (EX_USAGE);
	    }
	  break;
	case 'C':
	  psz_cb = list_optarg;
	  break;
	case 't':
	  i_chop = 1;
	  break;
	case 'O':
	  i_origin = atoi (list_optarg);
	  if (i_origin <= 0)
	    {
	      builtin_error ("bad i_origin: %s", list_optarg);
	      return (EX_USAGE);
	    }
	  break;
	default:
	  builtin_usage ();
	  return (EX_USAGE);
	}
    }
  list = loptend;

  if (!list) {
    builtin_error ("Missing file name");
    return (EX_USAGE);
  } else if (!list->word) {
    builtin_error ("Internal error #1 in getting file name");
    return (EX_USAGE);
  } else if (!list->word->word) {
    builtin_error ("Internal error #2 in getting file name");
    return (EX_USAGE);
  }
    

  if (!list->next) {
    builtin_error ("Missing array variable name");
    return (EX_USAGE);
  } else if (!list->next->word) {
    builtin_error ("Internal error #1 in getting variable name");
    return (EX_USAGE);
  } else if (!list->next->word->word) {
    builtin_error ("Internal error #2 in getting variable name");
    return (EX_USAGE);
  }

  if (0 == strcmp(list->word->word, "-"))
    fp = stdin;
  else 
    fp = fopen (list->word->word, "r");

  if (!fp) {
    builtin_error ("%s: %s", list->word->word, strerror (errno));
    return (EX_USAGE);
  }

  /* FIXME: Should test to see if list->next->word->word is can be a valid
     variable name.
   */

  rval = read_array (fp, i_line, i_origin, i_chop, i_cb, psz_cb, 
		     list->next->word->word);
  fclose (fp);
   
  return (rval);

}

char *readarray_doc[] = {
	"Copy the lines from the input file into an array variable.",
	"Use the `-n' option to specify a count of the number of lines to copy.",
	"If -n is missing all lines are copied.",
	"Use the `-O' option to specify an index orgin to start the array.",
	"If -O is missing the origin will be 0.",
	"Use -t to chop trailing newlines (\\n) from lines.",
	"To read from stdin use '-' as the filename.",
	"Note: this routine does not clear any previously existing array values.",
	"      It will however overwrite existing indices.",
	NULL
};

struct builtin readarray_struct = {
	"readarray",		/* builtin name */
	readarray_builtin,	/* function implementing the builtin */
	BUILTIN_ENABLED,	/* initial flags for builtin */
	readarray_doc,		/* array of long documentation strings. */
	"readarray [-t] [-c *count*] [-C callback] [-n *lines*] [-O *origin)] *file* *array_variable*)", 
	                        /* usage synopsis; becomes short_doc */
	0			/* reserved for internal use */
};
