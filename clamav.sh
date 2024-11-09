#!/bin/sh

# This script updates Clamav definitions with data from URLhaus (https://urlhaus.abuse.ch/api/#clamav)
#
# !!! To receive best protection, you should setup a cronjob that executes this script every minute !!!
#
# Please set up the following variables to fit your system

### HEADER ###
LOCKDIR="/var/lock"
cd `dirname $0`
SCRIPTPATH="`pwd`"
# check if lock directory exists:
if [ ! -d $LOCKDIR ]
then
	LOCKDIR="$SCRIPTPATH"
fi

LOCKFILE="$LOCKDIR/`basename $0`.lock"
LOCKFD=9


# check OS:
echo "1 of 7. Checking OS."
PLATFORM="unknown"
UNAMESTR="`uname`"
if [ $UNAMESTR = "FreeBSD" ]
then
	PLATFORM="freebsd"
elif [ $UNAMESTR = "Linux" ]
then
	PLATFORM="linux"
fi


# PRIVATE
LOCKCMD="flock"
FBSD_FLOCK="sysutils/flock"
if [ `command -v $LOCKCMD > /dev/null 2> /dev/null` ]
then
	if [ $PLATFORM = "freebsd" ]
	then 
		echo "Missing required package: sysutils/flock"
		echo "Please, execute manually: su -c pkg install $FBSD_FLOCK"
		exit
	fi
fi
echo "Step 1 completed"

_lock()             { $LOCKCMD -$1 $LOCKFD; }
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
echo "2 of 7. Checking ClamAV user and group."
CLAMDIR="/var/lib/clamav"
CLAMUSER="clamupdate"
CLAMGROUP="clamupdate"

# check if user exists, if not then set alternative:
if [ ! `/usr/bin/id -u $CLAMUSER > /dev/null 2> /dev/null` ]
then
	CLAMUSER="clamav"
	CLAMGROUP="clamav"
fi
echo "Step 2 completed"
# Don't change anything below this line

RELOAD=0

# Create TEMP directory:
TMPDIR="`mktemp`"

# check what binary provides MD5 function:
echo "3 of 7. Checking required tools"
MD5BIN="md5sum"
if [ `command -v $MD5BIN > /dev/null 2> /dev/null`]
then
	MD5BIN="md5"
fi
echo "Step 3 completed"

# download databases:
echo "4 of 7. Downloading available update"
curl -s https://urlhaus.abuse.ch/downloads/urlhaus.ndb -o $TMPDIR/urlhaus.ndb
echo "Step 4 completed"

echo "5 of 7. Update verification"
if [ $? -eq 0 ]; then
	clamscan --quiet -d $TMPDIR $TMPDIR 2> /dev/null >/dev/null
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
echo "Step 5 completed"

echo "6 of 7. Reloading ClamAV"
if [ $RELOAD -eq 1 ]; then
	clamdscan --reload
fi
echo "Step 6 completed"

echo "7 of 7. Removing temporary files"
unlock 
rm -rf $TMPDIR
echo "Step 7 completed"

