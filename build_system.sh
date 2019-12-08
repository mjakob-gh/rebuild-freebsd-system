#!/bin/sh

# ANSI Color Codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
COLOR_END="\033[0m"

LOG_FILE="/tmp/buildworld_$(date "+%Y%m%d%H%M").log"

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

echo "---------------------------------------"
echo "Logfile: $LOG_FILE"

cd /usr/src
make update >> $LOG_FILE

SOURCE_DATE_EPOCH=$(date -juf "%FT%T" `svnlite info --no-newline --show-item last-changed-date /usr/src | sed 's/\.[0-9]*Z$//'` "+%s")
export SOURCE_DATE_EPOCH

echo "SOURCE_DATE_EPOCH: $SOURCE_DATE_EPOCH"
echo "---------------------------------------"

printf "1. buildworld......"
make -j4 buildworld >> $LOG_FILE 2>&1
checkResult $?

printf "2. installworld...."
make installworld >> $LOG_FILE 2>&1
checkResult $?

printf "3. buildkernel....."
make -j4 buildkernel >> $LOG_FILE 2>&1
checkResult $?

printf "4. installkernel..."
make installkernel >> $LOG_FILE 2>&1
checkResult $?

printf "5. packages........"
make -j4 packages >> $LOG_FILE 2>&1
checkResult $?

echo ""
echo "6. please run \"mergemaster -iFU\""
