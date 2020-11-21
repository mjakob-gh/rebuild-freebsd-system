#!/bin/sh
set -x
if [ -f "jailpkg.plist" ]; then
    rm jailpkg.plist
fi

PLIST_TMPFILE=$( mktemp /tmp/plist.XXXXXX )
LANG_TMPFILE=$( mktemp /tmp/lang.XXXXXX )

SRC_DIR="/usr/src"
REPO_BASE_DIR="/usr/repo/jailpkg"

LAST_CHANGED_DATE=$(svnlite info --no-newline --show-item last-changed-date ${SRC_DIR} | sed 's/\.[0-9]*Z$//')
SOURCE_DATE_EPOCH=$(date -juf "%FT%T" ${LAST_CHANGED_DATE} "+%s")

FBSD_VERSION=$(uname -r | cut -c 1-4)

ABI_VERSION=$(pkg config abi)
REVISION=$(eval svnliteversion ${SRC_DIR})

WORLDSTAGE_DIR="/usr/obj/usr/src/amd64.amd64/worldstage"
REPO_DIR="${REPO_BASE_DIR}/${ABI_VERSION}/${FBSD_VERSION}.r${REVISION}"

# check requirements
if [ ! -d "${REPO_BASE_DIR}" ]; then
    echo "ERROR: directory \"${REPO_BASE_DIR}\" does not exist!"
    exit 1
fi

case ${FBSD_VERSION} in
  12*)
    # FreeBSD 12
    #PLIST_FILES="runtime.plist clibs.plist libexecinfo.plist libucl.plist libfetch.plist libcasper.plist libarchive.plist   \
    #liblzma.plist libcrypt.plist libbz2.plist libxo.plist libz.plist libutil.plist at.plist dma.plist"
    PLIST_FILES="at.plist casper.plist clibs.plist dma.plist ee.plist jail.plist lib.plist lib80211.plist libalias.plist     \
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
    PLIST_FILES="at.plist clibs.plist dma.plist ee.plist libarchive.plist libbegemot.plist libbsdxml.plist libbsm.plist      \
                 libbz2.plist libdwarf.plist libefivar.plist libevent1.plist libexecinfo.plist libldns.plist                 \
                 liblzma.plist libmagic.plist libopie.plist libregex.plist libsmb.plist libsqlite3.plist libucl.plist        \
                 rc.plist runtime.plist utilities.plist vi.plist"
    ;;
esac

FORMAT="txz"         
#FORMAT="tzst"
LEVEL="best"

# create ucl file from template
sed -e "s/%%FBSD_VERSION%%/${FBSD_VERSION}/g" -e "s/%%REVISION%%/${REVISION}/g" jailpkg.ucl.template > jailpkg.ucl

# create plist file from the source files and filter
# unwanted files out.
for FILE in ${PLIST_FILES}; do
  cat ${WORLDSTAGE_DIR}/${FILE} >> ${PLIST_TMPFILE}
done

# get basic language files
cat ${PLIST_TMPFILE} | grep -E "/usr/share/locale($|/C.UTF-8|/C|/en_US.UTF-8)" >> ${LANG_TMPFILE}
cat ${PLIST_TMPFILE} | grep -E "/usr/share/nls($|/C.UTF-8|/C|/en_US.UTF-8)"    >> ${LANG_TMPFILE}
cat ${PLIST_TMPFILE} | grep -E "/usr/share/vi/catalog($|/C|/POSIX|/english)"   >> ${LANG_TMPFILE}

sed -i '' \
  -e 's#.*/atf$##g'                          \
  -e 's#.*/atf/.*##g'                        \
  -e 's#.*/boot$##g'                         \
  -e 's#.*/boot/.*##g'                       \
  -e 's#.*/doc$##g'                          \
  -e 's#.*/doc/.*##g'                        \
  -e 's#.*/examples$##g'                     \
  -e 's#.*/examples/.*##g'                   \
  -e 's#.*/firmware$##g'                     \
  -e 's#.*/firmware/.*##g'                   \
  -e 's#.*/kld.*##g'                         \
  -e 's#.*/lib/nvmecontrol$##g'              \
  -e 's#.*/lib/nvmecontrol/.*##g'            \
  -e 's#.*/man$##g'                          \
  -e 's#.*/man/.*##g'                        \
  -e 's#.*/mk$##g'                           \
  -e 's#.*/mk/.*##g'                         \
  -e 's#.*ntp.*##g'                          \
  -e 's#.*/pc-sysinstall$##g'                \
  -e 's#.*/pc-sysinstall/.*##g'              \
  -e 's#.*/etc/kyua$##g'                     \
  -e 's#.*/etc/kyua/.*##g'                   \
  -e 's#.*/sbin/bectl$##g'                   \
  -e 's#.*/sbin/bsdlabel$##g'                \
  -e 's#.*/sbin/camcontrol$##g'              \
  -e 's#.*/sbin/clri$##g'                    \
  -e 's#.*/sbin/comcontrol$##g'              \
  -e 's#.*/sbin/conscontrol$##g'             \
  -e 's#.*/sbin/disklabel$##g'               \
  -e 's#.*/sbin/etherswitchcfg$##g'          \
  -e 's#.*/sbin/ffsinfo$##g'                 \
  -e 's#.*/sbin/fsck.*##g'                   \
  -e 's#.*/sbin/fsirand$##g'                 \
  -e 's#.*/sbin/gbde$##g'                    \
  -e 's#.*/sbin/gcache$##g'                  \
  -e 's#.*/sbin/gconcat$##g'                 \
  -e 's#.*/sbin/geli$##g'                    \
  -e 's#.*/sbin/ggatec$##g'                  \
  -e 's#.*/sbin/ggated$##g'                  \
  -e 's#.*/sbin/ggatel$##g'                  \
  -e 's#.*/sbin/gjournal$##g'                \
  -e 's#.*/sbin/glabel$##g'                  \
  -e 's#.*/sbin/gmirror$##g'                 \
  -e 's#.*/sbin/gmountver$##g'               \
  -e 's#.*/sbin/gmultipath$##g'              \
  -e 's#.*/sbin/gnop$##g'                    \
  -e 's#.*/sbin/gpart$##g'                   \
  -e 's#.*/sbin/graid$##g'                   \
  -e 's#.*/sbin/graid3$##g'                  \
  -e 's#.*/sbin/gsched$##g'                  \
  -e 's#.*/sbin/gshsec$##g'                  \
  -e 's#.*/sbin/gstripe$##g'                 \
  -e 's#.*/sbin/gvinum$##g'                  \
  -e 's#.*/sbin/gvirstor$##g'                \
  -e 's#.*/sbin/mount_cd9660$##g'            \
  -e 's#.*/sbin/mount_msdosfs$##g'           \
  -e 's#.*/sbin/mount_udf$##g'               \
  -e 's#.*/sbin/nvmecontrol$##g'             \
  -e 's#.*/sbin/swapctl$##g'                 \
  -e 's#.*/sbin/swapoff$##g'                 \
  -e 's#.*/sbin/swapon$##g'                  \
  -e 's#.*/usr/bin/ar$##g'                   \
  -e 's#.*/usr/bin/ib.*##g'                  \
  -e 's#.*/usr/bin/bthost$##g'               \
  -e 's#.*/usr/bin/btsockstat$##g'           \
  -e 's#.*/usr/bin/byacc$##g'                \
  -e 's#.*/usr/bin/c++filt$##g'              \
  -e 's#.*/usr/bin/c89$##g'                  \
  -e 's#.*/usr/bin/c99$##g'                  \
  -e 's#.*/usr/bin/colldef$##g'              \
  -e 's#.*/usr/bin/compile_et$##g'           \
  -e 's#.*/usr/bin/ctags$##g'                \
  -e 's#.*/usr/bin/ctfconvert$##g'           \
  -e 's#.*/usr/bin/ctfdump$##g'              \
  -e 's#.*/usr/bin/ctfmerge$##g'             \
  -e 's#.*/usr/bin/dtc$##g'                  \
  -e 's#.*/usr/bin/elf2aout$##g'             \
  -e 's#.*/usr/bin/file2c$##g'               \
  -e 's#.*/usr/bin/flex$##g'                 \
  -e 's#.*/usr/bin/flex++$##g'               \
  -e 's#.*/usr/bin/lex$##g'                  \
  -e 's#.*/usr/bin/lex++$##g'                \
  -e 's#.*/usr/bin/pmcstudy$##g'             \
  -e 's#.*/usr/bin/ranlib$##g'               \
  -e 's#.*/usr/bin/sscop$##g'                \
  -e 's#.*/usr/bin/ucmatose$##g'             \
  -e 's#.*/usr/bin/udaddy$##g'               \
  -e 's#.*/usr/bin/yacc$##g'                 \
  -e 's#.*/usr/lib/dtrace.*##g'              \
  -e 's#.*/usr/lib/libngatm.so.*##g'         \
  -e 's#.*/usr/lib/libpmc.so.*##g'           \
  -e 's#.*/usr/libexec/atf-check$##g'        \
  -e 's#.*/usr/libexec/atf-sh$##g'           \
  -e 's#.*/usr/libexec/hyperv/.*##g'         \
  -e 's#.*/usr/libexec/hyperv$##g'           \
  -e 's#.*/usr/sbin/bootpef$##g'             \
  -e 's#.*/usr/sbin/bthidcontrol$##g'        \
  -e 's#.*/usr/sbin/bthidd$##g'              \
  -e 's#.*/usr/sbin/camdd$##g'               \
  -e 's#.*/usr/sbin/ctladm$##g'              \
  -e 's#.*/usr/sbin/ctld$##g'                \
  -e 's#.*/usr/sbin/editmap$##g'             \
  -e 's#.*/usr/sbin/gpioctl$##g'             \
  -e 's#.*/usr/sbin/gpioctl$##g'             \
  -e 's#.*/usr/sbin/hccontrol$##g'           \
  -e 's#.*/usr/sbin/hostapd$##g'             \
  -e 's#.*/usr/sbin/hostapd_cli$##g'         \
  -e 's#.*/usr/sbin/kbdcontrol$##g'          \
  -e 's#.*/usr/sbin/makemap$##g'             \
  -e 's#.*/usr/sbin/mfiutil$##g'             \
  -e 's#.*/usr/sbin/moused$##g'              \
  -e 's#.*/usr/sbin/mprutil$##g'             \
  -e 's#.*/usr/sbin/mpsutil$##g'             \
  -e 's#.*/usr/sbin/mptutil$##g'             \
  -e 's#.*/usr/sbin/ndiscvt$##g'             \
  -e 's#.*/usr/sbin/pmc.*##g'                \
  -e 's#.*/usr/sbin/ppp$##g'                 \
  -e 's#.*/usr/sbin/praliases$##g'           \
  -e 's#.*/usr/sbin/sesutil$##g'             \
  -e 's#.*/usr/sbin/uathload$##g'            \
  -e 's#.*/usr/sbin/uhsoctl$##g'             \
  -e 's#.*/usr/sbin/valectl$##g'             \
  -e 's#.*/usr/sbin/vidcontrol$##g'          \
  -e 's#.*/usr/sbin/vidfont$##g'             \
  -e 's#.*/usr/sbin/wpa_cli$##g'             \
  -e 's#.*/usr/sbin/wpa_passphrase$##g'      \
  -e 's#.*/usr/sbin/wpa_supplicant$##g'      \
  -e 's#.*/usr/sbin/zonectl$##g'             \
  -e 's#.*/usr/share/atf$##g'                \
  -e 's#.*/usr/share/atf/.*##g'              \
  -e 's#.*/usr/share/calendar$##g'           \
  -e 's#.*/usr/share/calendar/.*##g'         \
  -e 's#.*/usr/share/dict$##g'               \
  -e 's#.*/usr/share/dict/.*##g'             \
  -e 's#.*/usr/share/dtrace$##g'             \
  -e 's#.*/usr/share/dtrace/.*##g'           \
  -e 's#.*/usr/share/firmware$##g'           \
  -e 's#.*/usr/share/firmware/.*##g'         \
  -e 's#.*/usr/share/games$##g'              \
  -e 's#.*/usr/share/games/.*##g'            \
  -e 's#.*/usr/share/kyua$##g'               \
  -e 's#.*/usr/share/kyua/.*##g'             \
  -e 's#.*/usr/share/locale/.*##g'           \
  -e 's#.*/usr/share/locale$##g'             \
  -e 's#.*/usr/share/misc/[a-l].*##g'        \
  -e 's#.*/usr/share/misc/[n-s].*##g'        \
  -e 's#.*/usr/share/misc/[u-z].*##g'        \
  -e 's#.*/usr/share/misc/mail.*##g'         \
  -e 's#.*/usr/share/misc/mdoc.template##g'  \
  -e 's#.*/usr/share/nls/.*##g'              \
  -e 's#.*/usr/share/nls$##g'                \
  -e 's#.*/usr/share/syscons/.*##g'          \
  -e 's#.*/usr/share/syscons$##g'            \
  -e 's#.*/usr/share/vi/catalog/.*##g'       \
  -e 's#.*/usr/share/vt$##g'                 \
  -e 's#.*/usr/share/vt/.*##g'               \
  -e 's#.*/usr/tests$##g'                    \
  -e 's#.*/usr/tests/.*##g'                  \
  -e 's#.*\.a$##g'                           \
  -e 's#.*\.h$##g'                           \
  -e 's#.*bsdinstall.*##g'                   \
  -e 's#.*cxgbetool$##g'                     \
  -e 's#.*debug.*##g'                        \
  -e 's#.*dwatch.*##g'                       \
  -e 's#.*lib32.*##g'                        \
  -e 's#.*libclang_rt\.asan.*\.so$##g'       \
  -e 's#.*libbe\.so.*##g'                    \
  -e '/^$/d'                                 \
${PLIST_TMPFILE}

# add language files back
cat ${LANG_TMPFILE} >> ${PLIST_TMPFILE}

# remove duplicate lines without sorting the file
awk '! visited[$0]++' ${PLIST_TMPFILE} > jailpkg.plist

# cleanup temp files
rm ${PLIST_TMPFILE}
rm ${LANG_TMPFILE}

# create the minijail package
pkg --option ABI_FILE=${WORLDSTAGE_DIR}/usr/bin/uname --option ALLOW_BASE_SHLIBS=yes create --verbose --timestamp ${SOURCE_DATE_EPOCH} --format ${FORMAT} --level ${LEVEL} --manifest jailpkg.ucl --plist jailpkg.plist --root-dir ${WORLDSTAGE_DIR} --out-dir ${REPO_DIR}

# create the minijail repository
cd ${WORLDSTAGE_DIR}
pkg repo --list-files ${REPO_DIR}

# create "latest" symlink in repository
echo "Creating symlink latest -> ${FBSD_VERSION}.r${REVISION}"
cd ${REPO_DIR}/..
rm latest
ln -s "${FBSD_VERSION}.r${REVISION}" latest
