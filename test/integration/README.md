# A Guide to writing test cases

This directory has the more coarse-grain integration tests which work
by running the full debugger. You might also want to check out the
unit tests which handle smaller components of the debugger.

Here is a guide for writing a new test case.

## How integration tests are set up to get run

In general, each integration test case in this directory starts with a file that ends in `.in` like `test-delete.in`.

This is a _bash_ program however with some text to be substituted based on information in configuration. The text to be substituted is delimited with `@`.

For example, the first shbang or `#!` line looks like this:

```
    #!@SH_PROG@ -f
```

You will see this file listed in `configure.ac`, as a file that is to be used as a template to create the actual shell program that gets run in integration testing.

In `configure` (produced via `configure.ac`) `@SH_PROG@` is substituted with the full path of _bash_ that is to be run. For example `@SH_PROG@` could be `/bin/bash` or `/usr/local/bin/bash`.

The line in `configure.ac` that cause this to happen when `configure` is run looks like this:

```
AC_CONFIG_FILES([test/integration/test-delete],
                [chmod +x test/integration/test-delete])
```

## Anatomy of integration tests.

At a high level, an integration test does these things:

* Unless the test is to be skipped, the test is run under _bashdb_ with some _bashdb_ flags
* the output, possibly filtered, is compared with expected results
* the scripts exits with an exit code based on the results from above:
   - 0 means the test passed
   - 77 indicates a test was skipped
   - anything else is a failure

Let's describe this in more detail. Here is `test-delete.in`:

```
1: #!@SH_PROG@ -f
2: # -*- shell-script -*-
3: t=${0##*/}; TEST_NAME=${t:5}   # basename $0 with 'test-' stripped off
4:
5: [ -z "$builddir" ] && builddir=$PWD
6: . ${builddir}/check-common.sh
7:. run_test_check stepping
```

Line 1: this gets changed into a valid shbang line, like `#!/bin/bash -f`

Line 2: this is for GNU Emacs to indicate the program is a shell script.

Line 3: pulls out the name of the test so that this can be used to figure out (by default) what bash script to run a debugger under and what output to compare results with. Here the extracted value is `delete`.

Line 5: get where we are so that we can reference the script to run and the expected results files

Line 6: source in library routines based on the directory set in line 5.

Line 7: runs _bashdb_. The parameter `stepping` the variable portion is the name of the _bash_ script in `test/example` to run. Here it is `test/example/stepping.sh`. If this parameter were not given we would have used `test/example/delete.sh` because this is was the extracted value in line 3.

Lets look at an example that is slightly (but only slightly) more complicated,
`test-file-with-spaces.in`:

```
 1: #!@SH_PROG@
 2: # -*- shell-script -*-
 3: TEST_NAME='file with spaces'
 4:
 5: [ -z "$builddir" ] && builddir=$PWD
 6: . ${builddir}/check-common.sh
 7:
 8: if [[ -f "$top_srcdir/test/example/file with spaces.sh" ]] ; then
 9:    run_test_check
10: else
11:    echo "Skipping test due to autoconf problems"
12:    exit 77
13: fi
```

Notice that in line 9 here we do not pass the name of an script to be debugged so the script to be debugged is `test/example/test-file-with-spaces`. In this respect this is simpler than the first test case.

Line 8 has an `if` statement that is testing whether we should run this script on not. The way we indicate the test was skipped is line 12.

Finally, let's look at part of a more complicated test case that involves filtering output. This is from `test-misc.in`:

```
. ${builddir}/check-common.sh
...
# Different OS's handle ARGV differently, and "info args" may come out
# differently depending on that.
cat ${TEST_FILE} | @SED@ -e "s:1 = .*/dbg-test2.sh:1 = ./example/dbg-test2.sh:" \
| @SED@ -e 's:record the command history is .*:record the command history is: ' \
| @SED@ -e 's:step-:step+:' \
| @GREP@ -v '^set dollar0' > ${TEST_FILTERED_FILE}

if (( BASH_VERSINFO[0] == 5 )) ; then
    RIGHT_FILE="${top_srcdir}/test/data/${TEST_NAME}-output-50.right"
elif (( (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 1) )) ; then
    RIGHT_FILE="${top_srcdir}/test/data/${TEST_NAME}-output-41.right"
fi

check_output $TEST_FILTERED_FILE $RIGHT_FILE
```

Notice we use `@SED@` and `@GREP@` which are replaced the specific `sed` and `grep` path that the `configure` finds.

The expected output changes from bash 4._x_ to bash 5._x_ and that is set using the `if` statement. Finally the `check_output` call then gives the name of a filtered file to compare from rather that . The variable `TEST_FILTERED_FILE` is automatically generated when we source `check_common.sh`.
