# To install from the sourceforge git repository

## Prerequisites

You'll need autotools

* autoconf
* automake
* autohheader

You'll also need packages

* textinfo

## Get sources

Sources are in git.

```
   $ git clone git://git.code.sf.net/p/bashdb/code bashdb-code
   $ cd bashdb-code
```

## Build configure

```
   $ bash ./autogen.sh
```

## Make code

```
   $ bash ./configure
```

## Make and test code

```
   $ make # but I prefer remake better
   $ make check
```

## Install
   $ make install # may need sudo
