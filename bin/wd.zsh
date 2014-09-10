#!/usr/bin/env zsh

wd() {
    output=$(_wd $@)

    if [ $? -eq 0 ]
    then
        echo "TODO: cd"
        echo "$output"
    else
        echo "$output"
    fi
}
