#!/bin/zsh

# WARP DIRECTORY
# ==============
# Jump to custom directories in terminal
# because `cd` takes too long...
#
# @github.com/mfaerevaag/wd

eval "wd() { source '${0:A:h}/wd.sh' }"
wd > /dev/null
zle -N wd_browse_widget
zle -N wd_restore_buffer
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init wd_restore_buffer
bindkey ${FZF_WD_BINDKEY:-'^B'} fuzzy_wd_widget
