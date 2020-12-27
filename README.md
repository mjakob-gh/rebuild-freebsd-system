# rebuild-freebsd-system.sh

A script to automate the steps to build of a freebsd system

* make update
* make buildworld
* make installworld
* make buildkernel
* make installkernel
* make packages
* make delete-old
* make delete-old-libs

all steps are logged to a file, for review at a later time.

The "make package" step can be somewhat configured in `/etc/make.conf`:
```shell
# Path to repository
# the subdirectories "FreeBSD:12:amd64" and "FreeBSD:13:amd64"
# will be automaticaly created.
REPODIR=/usr/repo/pkgbase

# in the default configuration, the packages get the
# timestamp added to the packagename.
# To embedd the revision to the package name add this line:
PKG_VERSION=${_REVISION}.r$$(eval svnliteversion ${SRCDIR})
```
