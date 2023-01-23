#!/bin/bash

# This script updates Clamav definitions with data from URLhaus (https://urlhaus.abuse.ch/api/#clamav)
#
# !!! To receive best protection, you should setup a cronjob that executes this script every minute !!!
#
# Please set up the following variables to fit your system

CLAMDIR="/var/lib/clamav"
CLAMUSER="clamav"
CLAMGROUP="clamav"

# Don't change anything below this line

RELOAD=0

TMPDIR=$(mktemp -d /tmp/urlhaus.XXXXXX) || exit 1
touch $TMPDIR/local.the.lock 2>/dev/null || exit 1

curl -s https://urlhaus.abuse.ch/downloads/urlhaus.ndb -o $TMPDIR/urlhaus.ndb

if [[ $? -eq 0 ]]; then
  clamscan --quiet -d $TMPDIR $TMPDIR 2>&1 >/dev/null
  if [[ $? -ne 0 ]]; then
    echo "downloaded file is not sane" >&2
    exit 1
  else
    if [[ -f "$CLAMDIR"/urlhaus.ndb ]]; then
      MD5old=$(md5sum "$CLAMDIR"/urlhaus.ndb)
      MD5new=$(md5sum $TMPDIR/urlhaus.ndb)
      if [[ "$MD5old" != "$MD5new" ]]; then
        # Updated file
        cp $TMPDIR/urlhaus.ndb $CLAMDIR
        chown $CLAMUSER.$CLAMGROUP "$CLAMDIR"/urlhaus.ndb
        RELOAD=1
      fi
    else
      # Looks like it's the first run
      cp $TMPDIR/urlhaus.ndb $CLAMDIR
      chown $CLAMUSER.$CLAMGROUP "$CLAMDIR"/urlhaus.ndb
      RELOAD=1
    fi
  fi
 fi

rm -rf /$TMPDIR 

if [[ $RELOAD -eq 1 ]]; then
  if type -a clamdscan >/dev/null 2>&1; then
     clamdscan --reload
  fi
fi
