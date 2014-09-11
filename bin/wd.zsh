#!/usr/bin/env zsh

wd() {
    output=$(_wd $@)

    if [ $? -eq 0 ]
    then
        cd "$output"
    else
        echo "$output"
    fi

    unset output
}
