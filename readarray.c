/* $Id: readarray.c,v 1.10 2006/08/21 11:10:52 myamato Exp $
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

/* The value specifying how frequently `readarray' 
   calls the callback. */
#define DEFAULT_PROGRESS_QUANTUM 5000

#ifndef HAVE_GETLINE
#define g_return_val_if_fail(test, val) \
   if (!(test)) return val;

/* The interface here is that of GNU libc's getline */
static ssize_t
getline (char **lineptr, size_t *n, FILE *stream)
{
#define EXPAND_CHUNK 16

  int n_read = 0;
  char *line = *lineptr;

  g_return_val_if_fail (lineptr != NULL, -1);
  g_return_val_if_fail (n != NULL, -1);
  g_return_val_if_fail (stream != NULL, -1);
  g_return_val_if_fail (*lineptr != NULL || *n == 0, -1);
  
#ifdef HAVE_FLOCKFILE
  flockfile (stream);
#endif  
  
  while (1)
    {
      int c;
      
#ifdef HAVE_FLOCKFILE
      c = getc_unlocked (stream);
#else
      c = getc (stream);
#endif      

      if (c == EOF)
        {
          if (n_read > 0)
           line[n_read] = '\0';
          break;
        }

      if (n_read + 2 >= *n)
        {
         size_t new_size;

         if (*n == 0)
           new_size = 16;
         else
           new_size = *n * 2;

         if (*n >= new_size)    /* Overflowed size_t */
           line = NULL;
         else
           line = *lineptr ? realloc (*lineptr, new_size) : malloc (new_size);

         if (line)
           {
             *lineptr = line;
             *n = new_size;
           }
         else
           {
             if (*n > 0)
               {
                 (*lineptr)[*n - 1] = '\0';
                 n_read = *n - 2;
               }
             break;
           }
        }

      line[n_read] = c;
      n_read++;

      if (c == '\n')
        {
          line[n_read] = '\0';
          break;
        }
    }

#ifdef HAVE_FLOCKFILE
  funlockfile (stream);
#endif

  return n_read - 1;
}
#endif /* ! HAVE_GETLINE */


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
  unsigned int array_index;
  unsigned int line_count;
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

  for (array_index = i_origin, line_count = 0; 
       -1 != getline(&psz_line, &i_len, fp); 
       array_index++, line_count++) {

    /* Have we Exceded # of lines to store/ */
    if (i_count != 0 && line_count >= i_count) 
      break;

    /* Remove trailing newlines? */
    if (i_chop) {
      int length = strlen(psz_line);
      if (length && '\n' == psz_line[length-1]) psz_line[length-1] = '\0';
    }

    /* Has a callback been registered and if so is it time to call it? */
    if (psz_cb && 0 == (line_count % i_cb)) 
      {
	unsigned int execlen;
	char *psz_exec;

        /* #  define INT_MAX	"2147483647" */
	execlen = strlen(psz_cb)+ 10;
	/* A `1' is for space between %s and %d,
	   another `1' is for the last nul char for C string. */
	execlen += (1 + 1);
	psz_exec = calloc(execlen, sizeof(char));

	snprintf(psz_exec, execlen, "%s %d", psz_cb, array_index);
	parse_and_execute(psz_exec, NULL, 0);
      }

    /* ENTRY is an array variable, and ARRAY points to the value. */
    { 
      char *newval;

      newval = make_variable_value (entry, psz_line, 0);
      if (entry->assign_func)
	(*entry->assign_func) (entry, newval, array_index);
      else
	array_insert (array_cell (entry), array_index, newval);
      free (newval);
    }
  }
  free(psz_line);
  return EXECUTION_SUCCESS;
}

int
readarray_builtin (WORD_LIST *list)
{
  int opt;
  int code;
  intmax_t intval;
  int rval;
  
  long int line;
  long int origin;
  long int chop;
  long int callback_quantum;
  char    *callback;
  FILE *fp;
  char *filename;
  char *arrayname;


  line = origin = chop = 0;
  callback_quantum = DEFAULT_PROGRESS_QUANTUM;
  callback 	   = NULL;
  
  munge_list (list);	/* change -num into -n num */

  reset_internal_getopt ();
  while ((opt = internal_getopt (list, "tc:C:n:O:")) != -1)
    {
      switch (opt)
	{
	case 'n':
	  code = legal_number (list_optarg, &intval);
	  if (code == 0 || intval < 0 || intval != (unsigned)intval)
	    {
	      builtin_error ("%s: bad line count specification", list_optarg);
	      return (EXECUTION_FAILURE);
	    }
	  else
	    line = intval;
	  break;
	case 'c':
	  code = legal_number (list_optarg, &intval);
	  if (code == 0 || intval < 0 || intval != (unsigned)intval)
	    {
	      builtin_error ("%s: bad callback quantum", list_optarg);
	      return (EXECUTION_FAILURE);
	    }
	  else
	    callback_quantum = intval;
	  break;
	case 'C':
	  callback = list_optarg;
	  break;
	case 't':
	  chop = 1;
	  break;
	case 'O':
	  code = legal_number (list_optarg, &intval);
	  if (code == 0 || intval < 0 || intval != (unsigned)intval)
	    {
	      builtin_error ("%s: bad array origin", list_optarg);
	      return (EXECUTION_FAILURE);
	    }
	  else
	    origin = intval;
	  break;
	default:
	  builtin_usage ();
	  return (EX_USAGE);
	}
    }
  list = loptend;

  if (!list) 
    {
      builtin_error ("missing file name");
      return (EX_USAGE);
    } 
  else if (!list->word) 
    {
      builtin_error ("internal error #1 in getting file name");
      return (EXECUTION_FAILURE);
    } 
  else if (!list->word->word) 
    {
      builtin_error ("internal error #2 in getting file name");
      return (EXECUTION_FAILURE);
    } 
  else if (list->word->word[0] == '\0') 
    {
      builtin_error ("file name is empty");
      return (EX_USAGE);
    } 
  else 
    {
      filename = list->word->word;
    }
    

  list = list->next;
  if (!list) 
    {
      builtin_error ("missing array variable name");
      return (EX_USAGE);
    } 
  else if (!list->word) 
    {
      builtin_error ("internal error #1 in getting variable name");
      return (EXECUTION_FAILURE);
    } 
  else if (!list->word->word) 
    {
      builtin_error ("internal error #2 in getting variable name");
      return (EXECUTION_FAILURE);
    } 
  else if (list->word->word[0] == '\0')
    {
      builtin_error ("array variable name is empty");
      return (EX_USAGE);
    } 
  else
    {
      arrayname = list->word->word;
    }
  
  if (legal_identifier (arrayname) == 0)
    {
      sh_invalidid (arrayname);
      return (EXECUTION_FAILURE);
    }

  if (0 == strcmp(filename, "-"))
    fp = stdin;
  else 
    fp = fopen (filename, "r");

  if (!fp) 
    {
      builtin_error ("%s: %s", filename, strerror (errno));
      return (EXECUTION_FAILURE);
    }
  
  rval = read_array (fp, line, origin, chop, callback_quantum, callback, arrayname);
  fclose (fp);
   
  return (rval);

}

char *readarray_doc[] = {
	"Copy the lines from the input file into an array variable.",
	"Use the `-n' option to specify a count of the number of lines to copy.",
	"If -n is missing or 0 is given as the number all lines are copied.",
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
	"readarray [-t] [-c *count*] [-C callback] [-n *lines*] [-O *origin*] *file* *array_variable*", 
	                        /* usage synopsis; becomes short_doc */
	0			/* reserved for internal use */
};
