%bcond_with tests
%define rversion 4.2-0.92

Name:           bashdb
Summary:        BASH debugger, the BASH symbolic debugger
Version:        4.2_0.92
Release:        1%{?dist}
License:        GPLv2+
Group:          Development/Debuggers
Url:            http://bashdb.sourceforge.net/
Source0:        http://downloads.sourceforge.net/%{name}/%{name}-%{rversion}.tar.bz2
Buildroot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  bash
BuildRequires:  python-pygments
Requires(post): /sbin/install-info
Requires(preun): /sbin/install-info
Requires:       bash
Requires:       python-pygments
BuildArch:      noarch
Obsoletes:      emacs-bashdb, emacs-bashdb-el

%description
The Bash Debugger Project is a source-code debugger for bash,
which follows the gdb command syntax.
The purpose of the BASH debugger is to check
what is going on “inside” a bash script, while it executes:
    * Start a script, specifying conditions that might affect its behavior.
    * Stop a script at certain conditions (break points).
    * Examine the state of a script.
    * Experiment, by changing variable values on the fly.
The 4.0 series is a complete rewrite of the previous series.

%prep
%setup -q -n %{name}-%{rversion}

%build
/bin/bash ./configure --with-bash=/bin/bash --prefix=/usr --datadir=/usr/share --mandir=/usr/share/man --infodir=/usr/share/info
sed -i 's:@BASHDB_MAIN@:/usr/share/bashdb/bashdb-main.inc:' bashdb-main.inc
make

%install
rm -rf ${RPM_BUILD_ROOT}
make DESTDIR=$RPM_BUILD_ROOT install
rm -f ${RPM_BUILD_ROOT}/%{_infodir}/dir


%check
echo ============TESTING===============
/usr/bin/env LANG=C make check
echo ============END TESTING===========

%post
if [ -f %{_infodir}/bashdb.info.gz ]; then # for --excludedocs
   /sbin/install-info %{_infodir}/remake.info.gz %{_infodir}/dir --entry="* Make: (bashdb).                 Bash Debugger." || :
fi

%preun
if [ "$1" = 0 ]; then
   if [ -f %{_infodir}/make.info.gz ]; then # for --excludedocs
      /sbin/install-info --deleete %{_infodir}/remake.info.gz %{_infodir}/dir --entry="* Make: (bashdb).                 Bash Debugger." || :
   fi
fi

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root,-)
%doc doc/*.html AUTHORS ChangeLog COPYING INSTALL NEWS README THANKS TODO
/usr/bin/bashdb
/usr/share/bashdb
/usr/share/info/bashdb.info.gz
/usr/share/man/man1/bashdb.1.gz


%changelog
* Sun Apr 30 2017 Rocky Bernstein <rb@dustyfeet.com> 4.2_0.9-1
- backport bashdb changes for CentOS7 for bash 4.2

* Sat Nov 9 2013 Rocky Bernstein <rb@dustyfeet.com> 4.2_0.9-1
- Make it work on RHEL5 for bash4

* Tue Sep 27 2011 Rocky Bernstein <rb@dustyfeet.com> 4.2_0.9-1
- Updated to 4.2-0.9

* Tue Mar 29 2011 Paulo Roma <roma@lcg.ufrj.br> 4.2_0.8-1
- Updated to 4.2-0.7

* Sun Mar 06 2011 Paulo Roma <roma@lcg.ufrj.br> 4.2_0.6-1
- Updated to 4.2-0.6
- Emacs lisp code has been removed upstream.

* Mon Feb 07 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 4.1_0.4-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Thu Jul 22 2010 Paulo Roma <roma@lcg.ufrj.br> 4.1_0.4-1
- Updated to 4.1-0.4

* Sun Mar 14 2010 Jonathan G. Underwood <jonathan.underwood@gmail.com> - 4.0_0.4-3
- Update package to comply with emacs add-on packaging guidelines
- Split out separate Elisp source file package

* Sun Dec 27 2009 Paulo Roma <roma@lcg.ufrj.br> 4.0_0.4-2
- Updated to 4.0-0.4

* Fri Apr 10 2009 Paulo Roma <roma@lcg.ufrj.br> 4.0_0.3-2
- Updated to 4.0-0.3 for supporting bash 4.0
- Added building option "with tests".

* Wed Feb 25 2009 Paulo Roma <roma@lcg.ufrj.br> 4.0_0.2-1
- Completely rewritten for Fedora.

* Tue Nov 18 2008 Manfred Tremmel <Manfred.Tremmel@iiv.de>
- update to 4.0-0.2
