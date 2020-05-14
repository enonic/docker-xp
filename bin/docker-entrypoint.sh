#!/bin/bash

# This script is the entrypoint for the docker image. By default it steps down from
# root when running the XP server.
#
# Environment variables:
#  TAKE_FILE_OWNERSHIP=0     Tells the script to set ownership of $XP_HOME/* to non root user
#
# Example:
#  docker-entrypoint.sh server.sh

set -e     # Exit immediately on error
umask 0002 # Files created by XP should always be group writable too

get_non_root_user() {
	if [[ "$(id -u)" == "0" ]]; then
		# If running as root, return standard XP user
		echo "$XP_UID"
	else
		# Not running as root, return current user
		echo $(id -u)
	fi
}

run_cmd_as_non_root() {
	if [[ "$(id -u)" == "0" ]]; then
		# Running as root, step down and exec the command
		exec chroot --userspec=$(get_non_root_user) / "$@"
	else
		# Not running as root, exec the command
		exec "$@"
	fi
}

setup_xp_home_directory() {
	# Is there a custom setenv.sh ?
	if [[ -f $XP_HOME/setenv.sh ]]; then
		echo "Found custom setenv.sh file in XP_HOME folder, copying it into runtime..."
		rm $XP_ROOT/bin/setenv.sh
		cp -p $XP_HOME/setenv.sh $XP_ROOT/bin/setenv.sh
	fi
}

setup_xp_home_permissions() {
	# If requested and running as root, mutate the ownership of $XP_HOME recursively
	if [[ "$(id -u)" == "0" ]]; then
		if [[ -n "$TAKE_FILE_OWNERSHIP" ]]; then
			echo "Taking file ownership of $XP_HOME"
			chown -R $(get_non_root_user):0 $XP_HOME
		fi
	fi
}

# If user is not found, create associated entry in /etc/passwd 
if ! whoami &> /dev/null; then
	if [ -w /etc/passwd ]; then
		echo "${USER_NAME:-$XP_USER}:x:$(id -u):0:${USER_NAME:-$XP_USER} user:${XP_ROOT}:/sbin/nologin" >> /etc/passwd
	fi
fi

if [[ "$1" == "server.sh" ]]; then
	# Let's setup and run XP
	setup_xp_home_directory
	setup_xp_home_permissions
	run_cmd_as_non_root "$@"
else
	# User probably wants to run something else, like bash
	exec "$@"
fi