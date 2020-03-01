#!/bin/sh

# Load filemon module needed for
# META_MODE
kldload filemon

# Check if META_MODE is enabled
printf "META_MODE: "
grep "^WITH_META_MODE=YES" /etc/src-env.conf > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "enabled"
else
    echo "disabled"
fi

# parallel builds
NUM_CPUS=3
SRC_DIR=/usr/src

# ANSI Color Codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
COLOR_END="\033[0m"

LOG_FILE="/tmp/buildsystem_$(date "+%Y%m%d%H%M").log"

checkResult ()
{
    if [ $1 -eq 0 ]; then
        printf "${GREEN}[OK]${COLOR_END}\n"
    else
        printf "${RED}[ERROR]${COLOR_END}\n"
        echo "Check Buildlog ${LOG_FILE}"
        echo ""
        exit 1
    fi
}

TIME_START=$(date +%s)

clear
echo "Start building system"
echo "---------------------"
echo "* cd ${SRC_DIR}"

cd ${SRC_DIR}

printf "* make update.........."
make update > ${LOG_FILE}
checkResult $?

LAST_CHANGED_REVISION=$(svnlite info --no-newline --show-item last-changed-revision ${SRC_DIR})
LAST_CHANGED_DATE=$(svnlite info --no-newline --show-item last-changed-date ${SRC_DIR} | sed 's/\.[0-9]*Z$//')

SOURCE_DATE_EPOCH=$(date -juf "%FT%T" ${LAST_CHANGED_DATE} "+%s")
export SOURCE_DATE_EPOCH

echo "---------------------------------------"
echo "Logfile:               ${LOG_FILE}"
echo "last-changed-revision: r${LAST_CHANGED_REVISION}"
echo "last-changed-date:     ${LAST_CHANGED_DATE}"
echo "SOURCE_DATE_EPOCH:     ${SOURCE_DATE_EPOCH}"
echo "---------------------------------------"

printf "* make buildworld......"
make -j${NUM_CPUS} buildworld >> ${LOG_FILE} 2>&1
checkResult $?

printf "* make installworld...."
make installworld >> ${LOG_FILE} 2>&1
checkResult $?

printf "* make buildkernel....."
make -j${NUM_CPUS} buildkernel >> ${LOG_FILE} 2>&1
checkResult $?

printf "* make installkernel..."
make installkernel >> ${LOG_FILE} 2>&1
checkResult $?

printf "* make packages........"
make -j${NUM_CPUS} packages >> ${LOG_FILE} 2>&1
checkResult $?

printf "* compressing logfile.."
xz ${LOG_FILE}
checkResult $?

TIME_END=$(date +%s)
TIME_DIFF=$((${TIME_END} - ${TIME_START}))
echo "---------------------------------------"
echo "Duration: $((${TIME_DIFF} / 3600))h $(((${TIME_DIFF} / 60) % 60))m $((${TIME_DIFF} % 60))s"

echo ""
echo "* please run \"mergemaster -iFU\" and read ${SRC_DIR}/UPDATING"
