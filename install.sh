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
MANLOC=/usr/share/man/man1

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
    echo "Adding wd function to your ~/.zshrc..."
    echo "wd() {"         >> $ZSHRC
    echo "  . $DIR/wd.sh" >> $ZSHRC
    echo "}"              >> $ZSHRC

    # TODO: we cannot process user input when piping the
    # script to sh, see https://github.com/mfaerevaag/wd/issues/27
    # install man page
    # while true
    # do
    #     echo "Would you like to install the man page? (requires root access) (Y/n)"
    #     read -r answer

    #     case "$answer" in
    #         Y|y|YES|yes|Yes )
    #             echo "Installing man page to ${MANLOC}/wd.1"
    #             sudo mkdir -p ${MANLOC}
    #             sudo cp -f ${DIR}/wd.1 ${MANLOC}/wd.1
    #             sudo chmod 644 ${MANLOC}/wd.1
    #             break
    #             ;;
    #         N|n|NO|no|No )
    #             echo "If you change your mind, see README for instructions"
    #             break
    #             ;;
    #         * )
    #             echo "Please provide a valid answer (y or n)"
    #             ;;
    #     esac
    # done

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
    echo "Remember to open new zsh to load wd."
    echo "For more information on usage, see README. Enjoy!"
else
    # ops
    echo "\033[91m \nOps! An error occured: \033[m"
    cat $LOG
    echo "\nIt would be great of you to file an issue"
    echo "at GitHub so I can fix it asap. Sorry!"
    echo "Log file: $LOG"
fi
