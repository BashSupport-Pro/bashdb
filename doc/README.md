Here we have a *gdb*-like debugger for Bash.

## Selecting which version of bashdb to use ##

The version of *bashdb* to use has to be compatible with the version
of bash used. Run `bash --version` to see what version of *bash* you
are using.

* If your version of bash is 3.0 or higher but less than 3.1, use the folder [3.00-0.05](https://sourceforge.net/projects/bashdb/files/bashdb/3.00-0.05/).
* If your version of bash is 3.1 or higher and less than 4.0, use folder [3.1-0.09](https://sourceforge.net/projects/bashdb/files/bashdb/3.1-0.09/).
* If your version of bash is 4.0 or higher but less than 4.1 use folder [4.0-0.4](https://sourceforge.net/projects/bashdb/files/bashdb/3.1-0.09/)
* If your version of bash is 4.1 or higher but less than 4.2 use folder [4.1-0.5](https://sourceforge.net/projects/bashdb/files/bashdb/4.1-0.5/)
* If your version of bash is 4.2 or higher, use folder [4.2-0.8](https://sourceforge.net/projects/bashdb/files/bashdb/4.1-0.5/)

As seen from the above, the first part of the version in the *bashdb* version name matches the major version number of *bash*. This is intentional.

See file file *INSTALL* in the distribution for detailed installation
instructions.

## Using the bashdb debugger ##

There are 3 ways to get into the debugger. If

* bash (with debugger support enabled which is the default) is installed, and
* the debugger is installed properly so that bash can find it

Then run:

    bash --debugger -- bash-script-name script-arg1 script-arg2...

If bash isn't installed in a way that will find bashdb, then:

    bashdb [bashdb-opts] -- bash-script-name script-arg1 script-arg2...

The downside here is that $0 will be "bashdb" not
bash-script-name. Also call stack will show the invocation to bashdb.

Finally, to invoke the debugger from the script

    # my script
    # work, work, work, ...

    # Load debugger support
	BASHDB_INSTALL=/usr/share/bashdb # ADJUST THIS!
    source ${BASHDB_INSTALL}/bashdb-trace -L $BASHDB_INSTALL
    # work, work, work or not...
    _Dbg_debugger; :   # Calls the debugger at the line below
    stop_before_running_this_statement

An advantage of the above is that there is no overhead up until you
invoke the debugger. Typically for large bash programs like
configuration scripts, this is a big win.

## Important Note if you use the above to debug configure scripts... ##

*stdin* is closed by configure early on. This causes the debugger to quit.
You can get around this invoking a command script that sets debugger
up input and output. Run tty to figure out what the terminal tty is set to.

    $ tty
    /dev/pts/3
    $

Above it came out to */dev/pts/3*. Let's go with that. Put the folliwng
in a file say */tmp/bashdb-configure*:

    source /dev/pts/3
    tty /dev/pts/3

Now arrange to read that configuration file using the *-x* (or *--eval-command*)
switch:

    BASHDB_INSTALLATION=/usr/share/bashdb # ADJUST THIS!
    source ${BASHDB_INSTALL}/bashdb-trace -L $BASHDB_INSTALL -x /tmp/bashdb-configure

[![endorse](https://api.coderwall.com/rocky/endorsecount.png)](https://coderwall.com/rocky)
