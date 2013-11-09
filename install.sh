#!/bin/sh

# WARP
# ====
# Installation script
#
# @github.com/mfaerevaag/wd

# variables
BIN=$HOME/bin
DIR=$BIN/wd
REPO=https://github.com/mfaerevaag/wd.git
ZSHRC=$HOME/.zshrc

# colors
BLUE="\033[96m"
RED="\033[91m"
NOC="\033[m"

# make temporary log file
LOG="$(mktemp -t wd_install)" || exit 1
exec 2> $LOG

# check if already exists
if [ -e $DIR ]
then
    echo "Directory '$DIR' already exists. Backup, and try again..."
    exit 1
fi

# lazy mkdir
if [ ! -d $BIN ]
then
    echo "Making a bin directory in your home folder..."
    mkdir $BIN
fi

# clone
if git clone $REPO $DIR
then
    # add alias
    echo "Adding alias to your config..."
    echo "alias wd='. $DIR/wd.sh'" >> $ZSHRC

    # remove log
    rm -rf $LOG

    # finish
    echo "$BLUE              _ "
    echo "$BLUE             | |"
    echo "$BLUE __      ____| |"
    echo "$BLUE \ \ /\ / / _\` |"
    echo "$BLUE  \ V  V / (_| |"
    echo "$BLUE   \_/\_/ \__,_|"
    echo "$BLUE                "
    echo "... is now installed. $NOC"
    echo "Remember to open new zsh to load alias."
    echo "For more information on usage, see README. Enjoy!"
else
    # ops
    echo "$RED\nOps! An error occured: $NOC"
    cat $LOG
    echo "\nIt would be great of you to file an issue"
    echo "at GitHub so I can fix it asap. Sorry!"
    echo "Log file: $LOG"
fi
