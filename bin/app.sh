#!/usr/bin/env bash

# Script to add/remove jars from XP deploy folder.
#
# Example:
#  app.sh OP URL [OPTIONS]
#  app.sh add https://repo.enonic.com/public/com/enonic/app/alive/2.0.0/alive-2.0.0.jar
#  app.sh remove https://repo.enonic.com/public/com/enonic/app/alive/2.0.0/alive-2.0.0.jar
#  app.sh add https://repo.enonic.com/public/com/enonic/app/alive/2.0.0/alive-2.0.0.jar --name=alive.jar --force
#  app.sh remove alive.jar

set -e # Exit immediately on error

DEPLOY_DIR=$XP_HOME/deploy

OP=""
JAR=""
NAME=""
FORCE="0"

usage() {
    echo "Usage: /app.sh [OP] [URL] [OPTIONS]"
    echo "Add/Remove app in the local deploy folder"
    echo ""
    echo "Options:"
    echo -e "\t-h, --help    Display this dialog"
    echo -e "\t--name=[name] Override app filename"
    echo -e "\t--force       Reinstall app even though its present"
}

error() {
    echo "$@"
    echo "Run /app.sh -h for more info"
    exit 1
}

# Parse parameters
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --name)
            NAME="$VALUE"
            ;;
        --force)
            FORCE="1"
            ;;
        *)
            if [ "$OP" == "" ]; then
                OP=$PARAM
            elif [ "$JAR" == "" ]; then
                JAR=$PARAM
            else
                usage
                exit 1
            fi
            ;;
    esac
    shift
done

# Check required parameters
if [ "$OP" == "" ] || [ "$JAR" == "" ]; then
    error "Missing OP or JAR"
    exit 1
fi

# Check OP
case $OP in
    add)
        ;;
    remove)
        ;;
    *)
        error "OP must be add or remove"
        ;;
esac

# Setup name
if [ "$NAME" == "" ]; then
    NAME=$(echo "$JAR" | tr "/" "\n" | tail -n 1)
fi

# Check name
if [[ ! "$NAME" =~ ^.*\.jar$ ]]; then
    echo ""
    error "NAME must end with .jar, got name $NAME"
fi

add () {
    echo -n "Adding $NAME ... "
    if [ -f $DEPLOY_DIR/$NAME ] && [ "$FORCE" == "0" ]; then
        echo "skipped! Already exists!"
        exit
    fi

    if [ "$FORCE" == "1" ]; then
        echo -n "forcing ... "
    fi

    fail=$(curl -L --silent --show-error --fail $JAR -o /tmp/$NAME 2>&1) || (echo -n "failed! "; echo "$fail"; exit 1)
    fail=$(cp -f /tmp/$NAME $DEPLOY_DIR/$NAME 2>&1) || (echo -n "failed! "; echo "$fail"; exit 1)
    echo "success!"
}

remove () {
    echo -n "Removing $NAME ... "
    if [ ! -f $DEPLOY_DIR/$NAME ]; then
        echo "skipped! Not found!"
        exit
    fi
    fail=$(rm $DEPLOY_DIR/$NAME 2>&1) || (echo -n "failed! "; echo "$fail"; exit 1)
    echo "success!"
}

# Run OP
$OP