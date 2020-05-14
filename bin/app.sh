#!/bin/bash

# Is to add/remove jars from XP deploy folder.
#
# Example:
#  app.sh OP URL [NAME]
#  app.sh add https://repo.enonic.com/public/com/enonic/app/alive/2.0.0/alive-2.0.0.jar
#  app.sh remove https://repo.enonic.com/public/com/enonic/app/alive/2.0.0/alive-2.0.0.jar
#  app.sh add https://repo.enonic.com/public/com/enonic/app/alive/2.0.0/alive-2.0.0.jar alive.jar
#  app.sh remove alive.jar

set -e

DEPLOY_DIR=$XP_HOME/deploy

app_name () {
    name=""
    if [ "$2" != "" ]
    then
        name="$2"
    else
        name=$(echo "$1" | tr "/" "\n" | tail -n 1)
    fi
    if [[ "$name" =~ ^.*\.jar$ ]]; then
        echo $name
    else
        echo "App name has to end with '.jar'" >>/dev/stderr
        exit 111
    fi
}

add () {
    name=$(app_name $@)
    echo -n "Adding $name ... "
    fail=$(curl --silent --show-error --fail $1 -o $DEPLOY_DIR/$name 2>&1) || (echo -n "failed! "; echo "$fail"; exit 111)
    echo "success!"
}

remove () {
    name=$(app_name $@)
    echo -n "Removing $name ... "
    fail=$(rm $DEPLOY_DIR/$name 2>&1) || (echo -n "failed! "; echo "$fail"; exit 111)
    echo "success!"
}

$@