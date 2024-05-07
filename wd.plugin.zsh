#!/bin/zsh

# WARP DIRECTORY
# ==============
# Jump to custom directories in terminal
# because `cd` takes too long...
#
# @github.com/mfaerevaag/wd

eval "wd() { source '${0:A:h}/wd.sh' }"
wd > /dev/null
# Register the function as a Zsh widget
zle -N wd_browse
# Bind the widget to a key combination
bindkey '^G' wd_browse
