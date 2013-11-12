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

# make temporary log file
LOG="$(mktemp -t wd_install.XXXXXXXXXX)" || exit 1
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
    echo "\033[96m"'              _ '"\033[m"
    echo "\033[96m"'             | |'"\033[m"
    echo "\033[96m"' __      ____| |'"\033[m"
    echo "\033[96m"' \ \ /\ / / _` |'"\033[m"
    echo "\033[96m"'  \ V  V / (_| |'"\033[m"
    echo "\033[96m"'   \_/\_/ \__,_|'"\033[m"
    echo "\033[96m"'                '"\033[m"
    echo "\033[96m... is now installed. \033[m"
    echo "Remember to open new zsh to load alias."
    echo "For more information on usage, see README. Enjoy!"
else
    # ops
    echo "\033[91m \nOps! An error occured: \033[m"
    cat $LOG
    echo "\nIt would be great of you to file an issue"
    echo "at GitHub so I can fix it asap. Sorry!"
    echo "Log file: $LOG"
fi
