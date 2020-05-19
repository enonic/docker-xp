#!/bin/bash

# This script exits with code 0 if there are a snapshot that is newer
# than AGE minutes. If AGE is not provided, it default to the environmental
# variable XP_SNAPSHOT_MAX_AGE that defaults to 1440.
#
# Environment variables:
#  XP_SNAPSHOT_MAX_AGE=1440     Maximum age of snapshots, defaults to 24h.
#
# Example:
#  backup.sh [AGE]
#  backup.sh
#  backup.sh 60

AGE=${1:-${XP_SNAPSHOT_MAX_AGE:-1440}}

echo "Searching for snapshots with max age of $AGE hours ..."
find $XP_HOME/snapshots/ -maxdepth 1 -cmin -${AGE} -iname 'snap*' -type f | egrep '.*'

if [ "$?" == "0" ]; then
    echo "Success!"
else
    echo "Failure! No snapshots with max age of $AGE hours found!"
    exit 1
fi