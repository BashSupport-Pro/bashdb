/* $Id: readarray.c,v 1.15 2006/08/23 23:56:54 rockyb Exp $
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

#if defined (HAVE_UNISTD_H)
#  include <unistd.h>
#endif

#include "bashansi.h"

#include <stdio.h>
#include <errno.h>

#include "bashintl.h"
#include "shell.h"
#include "common.h"
#include "bashgetopt.h"


#if !defined (errno)
extern int errno;
#endif

/* The value specifying how frequently `readarray' 
   calls the callback. */
#define DEFAULT_PROGRESS_QUANTUM 5000

/* Initial memory allocation for automatic growing buffer in zreadlinec */
#define ZREADLINE_INITIAL_ALLOCATION 16

/* Derived from GNU libc's getline.
   The behavior is almost the same as getline. See man getline.
   The differences are (1) using file descriptor instead of FILE* and
   (2) the order of arguments; the file descriptor comes the first. 

   zreadlinec uses zreadc internally. This means you cannot use 
   zreadlinec on fd which doesn't support lseek. Also you may have
   to call zsyncfd on the fd after you will not call zreadlinec
   on the fd anymore. */
static ssize_t
zreadlinec (int fd, char **lineptr, size_t *n)
{
  int n_read;
  char *line;

  if (lineptr == NULL)
    {
      builtin_error ("internal error zreadlinec#1; lineptr is NULL");
      return -1;
    }
  if (n == NULL)
    {
      builtin_error ("internal error zreadlinec#2; n is NULL");
      return -1;
    }
  if (*lineptr == NULL && *n != 0)
    {
      builtin_error ("internal error zreadlinec#3; lineptr and n are not consistent");
      return -1;
    }

  n_read = 0;
  line 	 = *lineptr;
  
  while (1)
    {
      char c;
      int  retval;
      
      retval = zreadc(fd, &c);

      if (retval <= 0)
        {
          if (n_read > 0)
           line[n_read] = '\0';
          break;
        }

      if (n_read + 2 >= *n)
        {
         size_t new_size;

         if (*n == 0)
           new_size = ZREADLINE_INITIAL_ALLOCATION;
         else
           new_size = *n * 2;

         if (*n >= new_size)    /* Overflowed size_t */
           line = NULL;
         else
           line = *lineptr ? xrealloc (*lineptr, new_size) : xmalloc (new_size);

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
  return n_read - 1;
}

static int
run_callback(const char * callback, unsigned int current_index)
{
  unsigned int execlen;
  char  *execstr;

  /* #  define INT_MAX	"2147483647" */
  execlen = strlen(callback)+ 10;
  /* A `1' is for space between %s and %d,
     another `1' is for the last nul char for C string. */
  execlen += (1 + 1);
  execstr = xmalloc(execlen);

  snprintf(execstr, execlen, "%s %d", callback, current_index);
  return parse_and_execute(execstr, NULL, 0);
}

static void
do_chop(char * line)
{
  int length;


  length = strlen(line);
  if (length && '\n' == line[length-1]) 
    line[length-1] = '\0';
}

static int
read_array (int fd, long int line_count_goal, long int origin, long int chop,
	    long int callback_quantum, char *callback, char *array_name)
{
  char *line;
  size_t line_length;
  unsigned int array_index;
  unsigned int line_count;
  SHELL_VAR *entry;


  line 	      = NULL;
  line_length = 0;

  /* Following check is also done in `bind_array_variable'.
     However, it should be done before reading lines. */
  entry = var_lookup (array_name, shell_variables);
  if (entry && (readonly_p (entry) || noassign_p (entry)))
    {
      if (readonly_p (entry))
	err_readonly (array_name);
      return (EX_USAGE);
    }


  /* Reset the buffer for bash own stream */
  for (array_index = origin, line_count = 0; 
       -1 != zreadlinec(fd, &line, &line_length); 
       array_index++, line_count++) 
    {

      /* Have we Exceded # of lines to store/ */
      if (line_count_goal != 0 && line_count >= line_count_goal) 
	break;

      /* Remove trailing newlines? */
      if (chop)
	do_chop(line);
	  
      /* Has a callback been registered and if so is it time to call it? */
      if (callback && 0 == (line_count % callback_quantum)) 
	{
	  run_callback(callback, array_index);

	  /* Reset the buffer for bash own stream. */
	  zsyncfd (fd);
	}

      bind_array_variable(array_name, array_index, line, 0);
    }
  xfree(line);
  zsyncfd (fd);

  return EXECUTION_SUCCESS;
}

int
readarray_builtin (WORD_LIST *list)
{
  int opt;
  int code;
  intmax_t intval;

  long int lines;
  long int origin;
  long int chop;
  long int callback_quantum;
  char    *callback;
  int      fd;
  char *array_name;

#ifdef __CYGWIN__
  builtin_error (_("readarray doesn't work on CYGWIN platform"));
  return (EXECUTION_FAILURE);
#endif /* Def: __CYGWIN__ */

  fd = lines = origin = chop = 0;
  callback_quantum = DEFAULT_PROGRESS_QUANTUM;
  callback 	   = NULL;

  reset_internal_getopt ();
  while ((opt = internal_getopt (list, "u:n:O:tC:c:")) != -1)
    {
      switch (opt)
	{
	case 'u':
	  code = legal_number (list_optarg, &intval);
	  if (code == 0 || intval < 0 || intval != (int)intval)
	    {
	      builtin_error (_("%s: invalid file descriptor specification"), list_optarg);
	      return (EXECUTION_FAILURE);
	    }
	  else
	    fd = intval;

	  if (sh_validfd (fd) == 0)
	    {
	      builtin_error (_("%d: invalid file descriptor: %s"), fd, strerror (errno));
	      return (EXECUTION_FAILURE);
	    }
	  if ((lseek (fd, 0L, SEEK_CUR) < 0) && (errno == ESPIPE))
	    {
	      builtin_error (_("%d: not seek-able file descriptor"), fd);
	      return (EXECUTION_FAILURE);
	    }
	  break;	  
	case 'n':
	  code = legal_number (list_optarg, &intval);
	  if (code == 0 || intval < 0 || intval != (unsigned)intval)
	    {
	      builtin_error (_("%s: bad line count specification"), list_optarg);
	      return (EXECUTION_FAILURE);
	    }
	  else
	    lines = intval;
	  break;
	case 'O':
	  code = legal_number (list_optarg, &intval);
	  if (code == 0 || intval < 0 || intval != (unsigned)intval)
	    {
	      builtin_error (_("%s: bad array origin"), list_optarg);
	      return (EXECUTION_FAILURE);
	    }
	  else
	    origin = intval;
	  break;
	case 't':
	  chop = 1;
	  break;
	case 'C':
	  callback = list_optarg;
	  break;
	case 'c':
	  code = legal_number (list_optarg, &intval);
	  if (code == 0 || intval < 0 || intval != (unsigned)intval)
	    {
	      builtin_error (_("%s: bad callback quantum"), list_optarg);
	      return (EXECUTION_FAILURE);
	    }
	  else
	    callback_quantum = intval;
	  break;
	default:
	  builtin_usage ();
	  return (EX_USAGE);
	}
    }
  list = loptend;

  if (!list) 
    {
      builtin_error (_("missing array variable name"));
      return (EX_USAGE);
    } 
  else if (!list->word) 
    {
      builtin_error ("internal error readarray_builtin#1 in getting variable name");
      return (EXECUTION_FAILURE);
    } 
  else if (!list->word->word) 
    {
      builtin_error ("internal error readarray_builtin#2 in getting variable name");
      return (EXECUTION_FAILURE);
    } 
  else if (list->word->word[0] == '\0')
    {
      builtin_error (_("array variable name is empty"));
      return (EX_USAGE);
    } 
  else
    array_name = list->word->word;
  
  if (legal_identifier (array_name) == 0 && valid_array_reference (array_name) == 0)
    {
      sh_invalidid (array_name);
      return (EXECUTION_FAILURE);
    }

  return read_array (fd, lines, origin, chop, callback_quantum, callback, array_name);
}

char *readarray_doc[] = {
  "Multiple lines are read from the standard input into ARRAY_VARIABLE,",
  "or from file descriptor FD if the -u option is supplied. In either case,",
  "the file descriptor must be seek-able because readarray buffers",
  "the file descriptor.",
  "",
  "Use the `-n' option to specify COUNT number of lines to copy.",
  "If -n is missing or 0 is given as the number all lines are copied.",
  "",
  "Use the `-O' option to specify an index ORIGIN to start the array.",
  "If -O is missing the origin will be 0.",
  "",
  "Use -t to chop trailing newlines (\\n) from lines.",
  "",
  "Use the `-C' option to specify CALLBACK which is evaluated according to ",
  "progression of reading lines. The evaluation is done each time",
  "QUANTUM number of lines are read as specified via the -c option;",
  "5000 is the default.",
  "",
  "The -C and -c options may be useful in implementing a progress bar.",
  "",
  "Note: this routine does not clear any previously existing array values.",
  "      It will however overwrite existing indices.",
  "      readarray doesn't work on cygwin platform.",
  NULL
};

struct builtin readarray_struct = {
  "readarray",		/* builtin name */
  readarray_builtin,	/* function implementing the builtin */
  BUILTIN_ENABLED,	/* initial flags for builtin */
  readarray_doc,		/* array of long documentation strings. */
  "readarray [-u fd] [-n count] [-O origin] [-t] [-C callback] [-c quantum] array_variable", 
  /* usage synopsis; becomes short_doc */
  0			/* reserved for internal use */
};
