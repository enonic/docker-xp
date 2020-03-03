#!/bin/bash

# This script creates thread and heap dumps from the JVM to the $XP_HOME/data/dumps folder.
#
# Example:
#  dump.sh

set -e # Exit immediately on error

DUMP_DIR=$XP_HOME/data/dumps
J_PID=$(pidof -s java)

mkdir -p $DUMP_DIR
jattach $J_PID threaddump > $DUMP_DIR/$J_PID-$(date --iso-8601=seconds)-threaddump.txt
jattach $J_PID dumpheap $DUMP_DIR/$J_PID-$(date --iso-8601=seconds)-heapdump.hprof