#!/bin/bash

# This script creates thread and heap dumps from the JVM to the $XP_HOME/data folder.
#
# Example:
#  dump.sh

set -e # Exit immediately on error

# Setup parameters
DUMP_DIR=$XP_HOME/data
J_PID=$(pidof -s java)
PREFIX="$J_PID-$(date --iso-8601=seconds)"

# Create dumps
jattach $J_PID threaddump > $DUMP_DIR/$PREFIX-threaddump.txt
jattach $J_PID dumpheap $DUMP_DIR/$PREFIX-heapdump.hprof

# List dumps
echo "Created dumps:"
find $DUMP_DIR -maxdepth 1 | grep $PREFIX