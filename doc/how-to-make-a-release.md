* Let people know of a pending release, e.g. mailto:bashdb-devel@sourceforge.net;
  no major changes before release, please
* test on lots of platforms.
* `make distcheck` should work
- Look for patches and outstanding bugs on sourceforge.net

```
$ git pull
$ make ChangeLog
```

* Go over `Changelog` and add `NEWS.md`. Update date of release.

```
  export BASHDB_MAJOR=5.0   # adjust
  export BASHDB_MINOR=1.1.1 # adjust
  export BASHDB_VERSION=${BASHDB_MAJOR}-${BASHDB_MINOR} # adjust
```

* Update Remove "devel" from configure.ac's release name. E.g.
    define(relstatus, 1.0.0)
                        ^^
* Make sure sources are current and checked in:
    git commit . -m"Get ready for release $BASHDB_VERSION"

* `./autogen.sh && make && make check`
- Tag release in git:

```
   git tag release-$BASHDB_VERSION
   git commit .
   git push --tags
```

* test tarball on other systems.
* Get onto sourceforge:
* merge to master

```
git checkout master
git merge <branch>
```

Use the GUI https://sourceforge.net/projects/bashdb/files/bashdb

create new folder, right click to set place to upload and
hit upload button.
copy `NEWS.md` as `README.md` in $BASHDB_VERSION
Do this via copying `NEWS.md` into tmp


* copy bashdb manual to web page:

```
$ cd doc
$ rm *.html
$ make
$ scp *.html rockyb,bashdb@web.sourceforge.net:htdocs
$ # scp -i ~/.ssh/id_rsa_sourceforge *.html rockyb,bashdb@web.sourceforge.net:/home/groups/b/ba/bashdb/htdocs/
```

* Bump version in configure.ac and add "dev". See place above in
removal
