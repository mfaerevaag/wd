#!/usr/bin/env zsh

wd() {
    output=$(_wd $@)

    if [ $? -eq 0 ]
    then
        echo "Success!"
        echo "$output"
    else
        echo "Fail!"
        echo "$output"
    fi
}
