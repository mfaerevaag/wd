#!/bin/zsh

# WARP DIRECTORY
# ==============
# Jump to custom directories in terminal
# because `cd` takes too long...
#
# @github.com/mfaerevaag/wd

# version
readonly WD_VERSION=0.2.0

# colors
readonly BLUE="\033[96m"
readonly GREEN="\033[92m"
readonly YELLOW="\033[93m"
readonly RED="\033[91m"
readonly NOC="\033[m"

## functions

wd_warp()
{
    local point=$1

    if [[ $point =~ "^\.+$" ]]
    then
        if [ $#1 < 2 ]
        then
            wd_print_msg $YELLOW "Warping to current directory?"
        else
            (( n = $#1 - 1 ))
            cd -$n > /dev/null
        fi
    elif [[ ${points[$point]} != "" ]]
    then
        cd ${points[$point]}
    else
        wd_print_msg $RED "Unknown warp point '${point}'"
    fi
}

wd_add()
{
    local force=$1
    local point=$2

    if [[ $point =~ "^[\.]+$" ]]
    then
        wd_print_msg $RED "Warp point cannot be just dots"
    elif [[ $point =~ "(\s|\ )+" ]]
    then
        wd_print_msg $RED "Warp point should not contain whitespace"
    elif [[ $point == *:* ]]
    then
        wd_print_msg $RED "Warp point cannot contain colons"
    elif [[ $point == "" ]]
    then
        wd_print_msg $RED "Warp point cannot be empty"
    elif [[ ${points[$2]} == "" ]] || $force
    then
        wd_remove $point > /dev/null
        printf "%q:%q\n" "${point}" "${PWD}" >> $CONFIG

        wd_print_msg $GREEN "Warp point added"
    else
        wd_print_msg $YELLOW "Warp point '${point}' already exists. Use 'add!' to overwrite."
    fi
}

wd_remove()
{
    local point=$1

    if [[ ${points[$point]} != "" ]]
    then
        if sed -n "/^${point}:.*$/!p" $CONFIG > $CONFIG_TMP && mv $CONFIG_TMP $CONFIG
        then
            wd_print_msg $GREEN "Warp point removed"
        else
            wd_print_msg $RED "Something bad happened! Sorry."
        fi
    else
        wd_print_msg $RED "Warp point was not found"
    fi
}

wd_list_all()
{
    wd_print_msg $BLUE "All warp points:"

    while IFS= read -r line
    do
        if [[ $line != "" ]]
        then
            arr=(${(s,:,)line})
            key=${arr[1]}
            val=${arr[2]}

            printf "%20s  ->  %s\n" $key $val
        fi
    done <<< $(sed "s:${HOME}:~:g" $CONFIG)
}

wd_show()
{
    local cwd=$(print $PWD | sed "s:^${HOME}:~:")

    wd_print_msg $BLUE "Warp points to current directory:"
    wd_list_all | grep -e "${cwd}$"
}

wd_print_msg()
{
    if [[ $QUIET -eq 0 ]] then
        local color=$1
        local msg=$2

        if [[ $color == "" || $msg == "" ]]
        then
            print " ${RED}*${NOC} Could not print message. Sorry!"
        else
            print " ${color}*${NOC} ${msg}"
        fi
    fi
}

wd_print_usage()
{
    cat <<- EOF
Usage: wd [add|-a|--add] [rm|-r|--remove] <point>

Commands:
	add	Adds the current working directory to your warp points
	add!	Overwrites existing warp point
	rm	Removes the given warp point
	show	Outputs warp points to current directory
	ls	Outputs all stored warp points
	help	Show this extremely helpful text
EOF
}


## run

# initialize config file
local CONFIG=$HOME/.warprc
local CONFIG_TMP=$CONFIG.tmp
local QUIET=0

# Parse 'meta' options first to avoid the need to have them before
# other commands. The `-D` flag consumes recognized options so that
# the actual command parsing won't be affected.

zparseopts -D -E -A meta_opts \
    c: -config: \
    q=wd_quiet_mode -quiet=wd_quiet_mode \
    v=wd_print_version -version=wd_print_version

if [[ ! -z $wd_quiet_mode ]] then
    QUIET=1
fi

if [[ ! -z $wd_print_version ]] then
    echo "wd version $WD_VERSION"
fi

if [[ ! -z $meta_opts[-c] ]] then
    CONFIG=$meta_opts[-c]
    CONFIG_TMP=$CONFIG.tmp
fi

# check if config file exists
if [ ! -e $CONFIG ]
then
    # if not, create config file
    touch $CONFIG
fi

# load warp points
typeset -A points
while read -r line
do
    arr=(${(s,:,)line})
    key=${arr[1]}
    val=${arr[2]}

    points[$key]=$val
done < $CONFIG



# get opts
args=$(getopt -o a:r:lhsq -l add:,rm:,ls,help,show,quiet -- $*)
# check if no arguments were given
if [[ $? -ne 0 || $#* -eq 0 ]]
then
    wd_print_usage

# check if config file is writeable
elif [ ! -w $CONFIG ]
then
    # do nothing
    # can't run `exit`, as this would exit the executing shell
    wd_print_msg $RED "\'$CONFIG\' is not writeable."

else

    # parse rest of options
    for o
    do
        case "$o"
            in
            -a|--add|add)
                wd_add false $2
                break
                ;;
            -a!|--add!|add!)
                wd_add true $2
                break
                ;;
            -r|--remove|rm)
                wd_remove $2
                break
                ;;
            -l|--list|ls)
                wd_list_all
                break
                ;;
            -h|--help|help)
                wd_print_usage
                break
                ;;
            -s|--show|show)
                wd_show
                break
                ;;
            *)
                wd_warp $o
                break
                ;;
            --)
                break
                ;;
        esac
    done
fi

## garbage collection
# if not, next time warp will pick up variables from this run
# remember, there's no sub shell

unset wd_warp
unset wd_add
unset wd_remove
unset wd_show
unset wd_list_all
unset wd_print_msg
unset wd_print_usage

unset args
unset points
unset val &> /dev/null # fixes issue #1
