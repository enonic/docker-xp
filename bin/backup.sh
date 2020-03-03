#!/bin/bash

# This script exits with code 0 if there are a snapshot that is newer
# than XP_SNAPSHOT_MAX_AGE minutes.
#
# Environment variables:
#  XP_SNAPSHOT_MAX_AGE=1440     Maximum age of snapshots, defaults to 24h.
#
# Example:
#  backup.sh

echo "Found the following snapshots:"
eval find $XP_HOME/snapshots/ -maxdepth 1 -cmin -${XP_SNAPSHOT_MAX_AGE:-1440} -iname 'snap*' -type f | egrep '.*'