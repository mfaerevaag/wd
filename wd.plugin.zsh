#!/bin/zsh

# WARP DIRECTORY
# ==============
# Jump to custom directories in terminal
# because `cd` takes too long...
#
# @github.com/mfaerevaag/wd

source ${0:A:h}/wd.sh

# Register the function as a Zsh widget
zle -N wd_browse
# Bind the widget to a key combination
bindkey '^G' wd_browse
