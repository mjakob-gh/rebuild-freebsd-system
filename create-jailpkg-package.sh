#!/bin/sh

rm jailpkg.plist

SRC_DIR="/usr/src"

LAST_CHANGED_DATE=$(svnlite info --no-newline --show-item last-changed-date ${SRC_DIR} | sed 's/\.[0-9]*Z$//')
SOURCE_DATE_EPOCH=$(date -juf "%FT%T" ${LAST_CHANGED_DATE} "+%s")

FBSD_VERSION=$(uname -r | cut -c 1-4)

ABI_VERSION=$(pkg config abi)
REVISION=$(eval svnliteversion ${SRC_DIR})

WORLDSTAGE_DIR="/usr/obj/usr/src/amd64.amd64/worldstage"
REPO_DIR="/usr/repo/jailpkg/${ABI_VERSION}/${FBSD_VERSION}.r${REVISION}"

case ${FBSD_VERSION} in
  12*)
    # FreeBSD 12
    #PLIST_FILES="runtime.plist clibs.plist libexecinfo.plist libucl.plist libfetch.plist libcasper.plist libarchive.plist \
    #liblzma.plist libcrypt.plist libbz2.plist libxo.plist libz.plist libutil.plist at.plist dma.plist"
    PLIST_FILES="at.plist casper.plist clibs.plist dma.plist jail.plist lib.plist lib80211.plist libalias.plist              \
                 libarchive.plist libauditd.plist libbe.plist libbegemot.plist libbluetooth.plist libbsdxml.plist            \
                 libbsm.plist libbz2.plist libcalendar.plist libcam.plist libcasper.plist libcom_err.plist libcrypt.plist    \
                 libdevctl.plist libdevinfo.plist libdevstat.plist libdpv.plist libdwarf.plist libefivar.plist libelf.plist  \
                 libevent.plist libexecinfo.plist libfetch.plist libfigpar.plist libgeom.plist libgpio.plist libgssapi.plist \
                 libipsec.plist libkiconv.plist libkvm.plist libldns.plist liblzma.plist libmagic.plist libmd.plist          \
                 libmemstat.plist libmp.plist libmt.plist libnetgraph.plist libngatm.plist libnv.plist libopie.plist         \
                 libpcap.plist libpjdlog.plist libpmc.plist libproc.plist libprocstat.plist libradius.plist librpcsvc.plist  \
                 librt.plist librtld_db.plist libsbuf.plist libsdp.plist libsmb.plist libsqlite3.plist libsysdecode.plist    \
                 libtacplus.plist libucl.plist libufs.plist libugidfw.plist libulog.plist libusb.plist libusbhid.plist       \
                 libutil.plist libwrap.plist libxo.plist libypclnt.plist libz.plist runtime.plist vi.plist"
    ;;
  13*)
    # FreeBSD 13
    #PLIST_FILES="utilities.plist rc.plist at.plist clibs.plist dma.plist libexecinfo.plist runtime.plist"
    PLIST_FILES="at.plist clibs.plist dma.plist libarchive.plist libbegemot.plist libbsdxml.plist libbsm.plist libbz2.plist  \
                 libdwarf.plist libefivar.plist libevent1.plist libexecinfo.plist libldns.plist liblzma.plist libmagic.plist \
                 libopie.plist libregex.plist libsmb.plist libsqlite3.plist libucl.plist rc.plist runtime.plist              \
                 utilities.plist vi.plist"
    ;;
esac

#FORMAT="txz"
FORMAT="tzst"
LEVEL="best"

sed -e "s|%%FBSD_VERSION%%|${FBSD_VERSION}|g" -e "s|%%REVISION%%|${REVISION}|g" jailpkg.ucl.template > jailpkg.ucl

for FILE in ${PLIST_FILES}; do
  cat ${WORLDSTAGE_DIR}/${FILE} | sed         \
      -e 's|.*/boot/.*||g'                    \
      -e 's|.*/atf/.*||g'                     \
      -e 's|.*/examples/.*||g'                \
      -e 's|.*/tests/.*||g'                   \
      -e 's|.*/firmware/.*||g'                \
      -e 's|.*/pc-sysinstall/.*||g'           \
      -e 's|.*/doc/.*||g'                     \
      -e 's|.*/man/.*||g'                     \
      -e 's|.*/mk/.*||g'                      \
      -e 's|.*/[a-z][a-z]_[A-Z][A-Z]\..*||g'  \
      -e 's|.*bsdinstall.*||g'                \
      -e 's|.*dwatch.*||g'                    \
      -e 's|.*geom.*||g'                      \
      -e 's|.*debug.*||g'                     \
      -e 's|.*lib32.*||g'                     \
      -e 's|.*cxgbetool$||g'                  \
      -e 's|.*libclang_rt\.asan-i386\.so$||g' \
      -e 's|.*\.a$||g'                        \
      -e 's|.*\.h$||g'                        \
      -e 's|.*/kld.*||g'                      \
      -e 's|.*/nvmecontrol.*||g'              \
      -e 's|.*/sbin/fsck.*||g'                \
      -e 's|.*/usr/share/vt/.*||g'            \
      -e 's|.*/usr/share/syscons/.*||g'       \
      -e '/^$/d'                              \
  >> _temp.plist
done

# remove duplicate lines without sorting the file
awk '! visited[$0]++' _temp.plist > jailpkg.plist

rm _temp.plist

pkg --option ABI_FILE=${WORLDSTAGE_DIR}/usr/bin/uname --option ALLOW_BASE_SHLIBS=yes create --verbose --timestamp ${SOURCE_DATE_EPOCH} --format ${FORMAT} --level ${LEVEL} --manifest jailpkg.ucl --plist jailpkg.plist --root-dir ${WORLDSTAGE_DIR} --out-dir ${REPO_DIR}

cd ${WORLDSTAGE_DIR}
pkg repo --list-files ${REPO_DIR}

# create "latest" symlink
cd ${REPO_DIR}/..
rm latest
ln -s "${FBSD_VERSION}.r${REVISION}" latest
