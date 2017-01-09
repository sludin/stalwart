#!/bin/sh

# usage


USAGE=$(cat <<EOF
usage install.sh [options]
Options:
 -h this help
 -c destination for the config (default: $HOME/.stawart/start.config)
 -o stalwart host
 -k ssh key
 -u ssh user
 -d target directory on stalwart host
 -p ssh port (default: 22)
 -t directory to place stalwart.pl
 -i path to perl interpreter to use
 -x patterns to exclude
 -f files / diectories to sync
EOF
)

ARGS=`getopt nhx:f:c:o:k:u:d:p:t: $*`
if [ $? != 0 ]
then
    echo 'Usage: ...'
    exit 2
fi

set -- $ARGS

STALWART_PLIST=/Library/LaunchDaemons/org.ludin.stalwart.plist
STALWART_USER=""
STALWART_PORT=22
STALWART_CONFIG=$HOME/.stalwart/stalwart.config
STALWART_KEY=""
STALWART_TARGET="/usr/local/bin"
STALWART_DEST=""
STALWART_HOST=""
STALWART_FILES=""
STALWART_EXCLUDES=""
STALWART_PERL=`which perl`
DRY_RUN=""

for i
do
    case "$i" in
        -h)
            echo "$USAGE"
            exit 0
            ;;
        -n)
            DRY_RUN="YES"
            shift;
            ;;
        -c)
            STALWART_CONFIG="$2"
            shift; shift;
            ;;
        -o)
            STALWART_HOST=$2
            shift; shift;
            ;;
        -k)
            STALWART_KEY="$2"
            shift; shift;
            ;;
        -u)
            STALWART_USER="$2"
            shift; shift;
            ;;
        -d)
            STALWART_DEST="$2"
            shift; shift;
            ;;
        -p)
            STALWART_PORT=$2
            shift; shift;
            ;;
        -t)
            STALWART_TARGET="$2"
            shift; shift;
            ;;
        -x)
            STALWART_EXCLUDES="$2"
            shift; shift;
            ;;
        -f)
            STALWART_FILES="$2"
            shift; shift;
            ;;
        -i)
            STALWART_PERL="$2"
            shift; shift;
            ;;
        --) shift ; break ;;
    esac
done

EXIT=0
if [ -z $STALWART_USER ]; then echo "user (-u) required"; EXIT=1; fi
if [ -z $STALWART_HOST ]; then echo "host (-o) required"; EXIT=1; fi
if [ -z $STALWART_KEY ]; then echo "key (-k) required"; EXIT=1; fi
if [ -z $STALWART_DEST ]; then echo "dest (-d) required"; EXIT=1; fi
if [ -z $STALWART_TARGET ]; then echo "target (-t) required"; EXIT=1; fi
if [ "$EXIT" -eq 1 ]; then exit 1; fi

if [ ! -d $STALWART_TARGET ]; then
    echo "Target (-t) must be a directory"
    exit 1
fi

if [ -d $STALWART_CONFIG ]; then
    STALWART_CONFIG=`echo $STALWART_CONFIG | sed "s/\/$//"`
    STALWART_CONFIG=$STALWART_CONFIG/stalwart.config
fi

# Remove any trailing / from directory name
STALWART_TARGET=`echo $STALWART_TARGET | sed "s/\/$//"`

if [ "$DRY_RUN" = "YES" ]; then
    echo STALWART_USER = $STALWART_USER
    echo STALWART_PORT = $STALWART_PORT
    echo STALWART_HOST = $STALWART_HOST
    echo STALWART_KEY = $STALWART_KEY
    echo STALWART_DEST = $STALWART_DEST
    echo STALWART_TARGET = $STALWART_TARGET
    echo STALWART_CONFIG = $STALWART_CONFIG
    echo STALWART_PERL = $STALWART_PERL
    echo STALWART_EXCLUDES = $STALWART_EXCLUDES
    echo STALWART_FILES = $STALWART_FILES
    exit 0
fi


$STALWART_PERL -p -e "s|STALWART_USER|$STALWART_USER|g; s|STALWART_HOST|$STALWART_HOST|g; s|STALWART_PORT|$STALWART_PORT|g; s|STALWART_KEY|$STALWART_KEY|g; s|STALWART_DEST|$STALWART_DEST|g; s|STALWART_TARGET|$STALWART_TARGET|g; s|STALWART_CONFIG|$STALWART_CONFIG|g; s|STALWART_FILES|$STALWART_FILES|g; s|STALWART_EXCLUDES|$STALWART_EXCLUDES|g" stalwart.config.example > $STALWART_CONFIG

sudo $STALWART_PERL -p -e "s|STALWART_TARGET|$STALWART_TARGET/stalwart.pl|g; s|STALWART_CONFIG|$STALWART_CONFIG|g;" org.ludin.stalwart.plist.example > /tmp/stalwart.plist
sudo cp /tmp/stalwart.plist $STALWART_PLIST
rm -f /tmp/stalwart.plist

$STALWART_PERL -p -e "s|STALWART_PERL|$STALWART_PERL|g;" stalwart.pl > /tmp/stalwart.pl
sudo cp /tmp/stalwart.pl $STALWART_TARGET
rm -f /tmp/stalwart.pl

#sudo cp stalwart.pl $STALWART_TARGET
#sudo chmod +x $STALWART_TARGET

sudo launchctl unload $STALWART_PLIST
sudo launchctl load -w $STALWART_PLIST


