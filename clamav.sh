#!/bin/bash

# This script updates Clamav definitions with data from URLhaus (https://urlhaus.abuse.ch/api/#clamav)
#
# !!! To receive best protection, you should setup a cronjob that executes this script every minute !!!
#
# This script requires the lockfile command provided by procmail
#
# Please set up the following variables to fit your system

CLAMDIR="/var/lib/clamav"
CLAMUSER="clamav"
CLAMGROUP="clamav"
LOCKFILE="/tmp/urlhaus.lock"
TEMPDIR="/tmp/urlhaus/"

# Don't change anything below this line

RELOAD=0

lockfile -r 0 $LOCKFILE 2>/dev/null || exit 1

rm -rf $TEMPDIR
mkdir $TEMPDIR

curl -s https://urlhaus.abuse.ch/downloads/urlhaus.ndb -o $TEMPDIR/urlhaus.ndb

if [ $? -eq 0 ]; then
  clamscan --quiet -d $TEMPDIR $TEMPDIR 2>&1 >/dev/null
  if [ $? -eq 0 ]; then
    if [ -f "$CLAMDIR"/urlhaus.ndb ]; then
      MD5old=$(md5sum "$CLAMDIR"/urlhaus.ndb | awk '{print $1}')
      MD5new=$(md5sum $TEMPDIR/urlhaus.ndb | awk '{print $1}')
      echo $MD5old
      echo $MD5new
      if [ "$MD5old" != "$MD5new" ]; then
        # Updated file
        cp $TEMPDIR/urlhaus.ndb $CLAMDIR
        chown $CLAMUSER.$CLAMGROUP "$CLAMDIR"/urlhaus.ndb
        RELOAD=1
      fi
    else
      # Looks like it's the first run
      cp $TEMPDIR/urlhaus.ndb $CLAMDIR
      chown $CLAMUSER.$CLAMGROUP "$CLAMDIR"/urlhaus.ndb
      RELOAD=1
    fi
  fi
fi

if [ $RELOAD -eq 1 ]; then
  clamdscan --reload
fi

rm -rf $TEMPDIR
rm -f $LOCKFILE
