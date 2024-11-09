#!/bin/bash

# This script updates Clamav definitions with data from URLhaus (https://urlhaus.abuse.ch/api/#clamav)
#
# !!! To receive best protection, you should setup a cronjob that executes this script every minute !!!
#
# Please set up the following variables to fit your system

# Notes about changes:
# * It is recommended that you execute this script as "clamav" user which should have write access to
#   /var/lib/clamav. 
# * Instead of downloading the signatures every minute, we check against its SHA256 sum before downloading 
#   (which reduces load on the server).
# * Using random temporally directory
# * As it should be executed at least every minute, we remove the need of a lock file for simplicity and 
#   compatibility
# * Instead of testing with clamdscan we assume that if the downloaded file matches the original hash, it 
#   should work fine (speed up process)

CLAMDIR="/var/lib/clamav"

# ----------------------------------------------------------------------------------------

RELOAD=0

# Check current SHA256 sum:
NEWHASH=$(curl -m 10 -s https://urlhaus.abuse.ch/downloads/urlhaus.ndb.sha256)

function download {
    TMPDIR=$(mktemp -d)
    TMPNDB="$TMPDIR/urlhaus.ndb"
    curl -m 30 -s https://urlhaus.abuse.ch/downloads/urlhaus.ndb -o "$TMPNDB"
    DOWNHASH=$(sha256sum "$TMPNDB" | awk '{ print $1 }')
    # Test that the file is not corrupt (replaced with a fastest way)
    if [[ "$DOWNHASH" == "$NEWHASH" ]]; then
        mv "$TMPNDB" "$CLAMDIR/"
        RELOAD=1
    fi
    rm -rf $TMPDIR
}

# Check that the response is correctly:
if [[ $NEWHASH != "" && $(echo -n "$NEWHASH" | wc -c) == 64 ]]; then

    if [[ -e "$CLAMDIR/urlhaus.ndb" ]]; then
        CURRHASH=$(sha256sum "$CLAMDIR/urlhaus.ndb" | awk '{ print $1 }');
        if [[ "$CURRHASH" != "$NEWHASH" ]]; then
            download
        fi
    else
        # Looks like it's the first run
        download
    fi

    if [[ $RELOAD == 1 ]]; then
      clamdscan --reload
    fi

fi
