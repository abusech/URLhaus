#!/bin/bash

# This script updates Clamav definitions with data from URLhaus (https://urlhaus.abuse.ch/api/#clamav)
#
# !!! To receive best protection, you should setup a cronjob that executes this script every minute !!!
#
# Please set up the following variables to fit your system

### HEADER ###
LOCKDIR="/var/lock/" 

# check if lock directory exists:
if [! -d $LOCKDIR ]
then
	LOCKDIR="`dirname $0`"
fi

LOCKFILE="$LOCKDIR/`basename $0`.lock"
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

# check if user exists, if not then set alternative:
if [! `/usr/bin/id -u $CLAMUSER >/dev/null 2>&1` ]
then
	CLAMUSER="clamav"
	CLAMGROUP="clamav"
fi

# Don't change anything below this line

RELOAD=0

# Create TEMP directory:
TMPDIR="`mktemp`"
mkdir -p $TMPDIR

# check what binary provides MD5 function:
MD5BIN="md5sum"
if [! `command -v $MD5BIN >/dev/null 2>&1`]
then
	MD5BIN="md5"
fi

# download databases:
curl -s https://urlhaus.abuse.ch/downloads/urlhaus.ndb -o $TMPDIR/urlhaus.ndb

if [ $? -eq 0 ]; then
  clamscan --quiet -d $TMPDIR $TMPDIR 2>&1 >/dev/null
  if [ $? -eq 0 ]; then
    if [ -f "$CLAMDIR"/urlhaus.ndb ]; then
      MD5old=`md5 "$CLAMDIR"/urlhaus.ndb`
      MD5new=`md5 $TMPDIR/urlhaus.ndb`
      if ! [ "$MD5old" = "$MD5new" ]; then
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

if [ $RELOAD -eq 1 ]; then
  clamdscan --reload
fi

rm -rf $TMPDIR
