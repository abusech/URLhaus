#!/bin/bash

# This script updates Clamav definitions with data from URLhaus (https://urlhaus.abuse.ch/api/#clamav)
#
# !!! To receive best protection, you should setup a cronjob that executes this script every minute !!!
#
# Please set up the following variables to fit your system

### HEADER ###
 
LOCKFILE="/var/lock/`basename $0`"
LOCKFD=99

# PRIVATE
_lock()             { flock -$1 $LOCKFD; }
_no_more_locking()  { _lock u; _lock xn && rm -f $LOCKFILE; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }

# ON START
_prepare_locking

# PUBLIC
exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

# Simplest example is avoiding running multiple instances of script.
exlock_now || exit 1

### BEGIN OF SCRIPT ###

CLAMDIR="/var/lib/clamav"
CLAMUSER="clamupdate"
CLAMGROUP="clamupdate"

# Don't change anything below this line

RELOAD=0

rm -rf /tmp/urlhaus
mkdir /tmp/urlhaus

curl -s https://urlhaus.abuse.ch/downloads/urlhaus.ndb -o /tmp/urlhaus/urlhaus.ndb

if [ $? -eq 0 ]; then
  clamscan --quiet -d /tmp/urlhaus /tmp/urlhaus 2>&1 >/dev/null
  if [ $? -eq 0 ]; then
    if [ -f "$CLAMDIR"/urlhaus.ndb ]; then
      MD5old=`md5sum "$CLAMDIR"/urlhaus.ndb`
      MD5new=`md5sum /tmp/urlhaus/urlhaus.ndb`
      if ! [ "$MD5old" = "$MD5new" ]; then
        # Updated file
        cp /tmp/urlhaus/urlhaus.ndb $CLAMDIR
        chown $CLAMUSER.$CLAMGROUP "$CLAMDIR"/urlhaus.ndb
        RELOAD=1
      fi
    else
      # Looks like it's the first run
      cp /tmp/urlhaus/urlhaus.ndb $CLAMDIR
      chown $CLAMUSER.$CLAMGROUP "$CLAMDIR"/urlhaus.ndb
      RELOAD=1
    fi
  fi
fi

if [ $RELOAD -eq 1 ]; then
  clamdscan --reload
fi

rm -rf /tmp/urlhaus
