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
readonly WD_BLUE="\033[96m"
readonly WD_GREEN="\033[92m"
readonly WD_YELLOW="\033[93m"
readonly WD_RED="\033[91m"
readonly WD_NOC="\033[m"

## functions

# helpers
wd_exit_fail()
{
    local msg=$1

    wd_print_msg $WD_RED $1
    WD_EXIT_CODE=1
}

wd_exit_warn()
{
    local msg=$1

    wd_print_msg $WD_YELLOW $msg
    WD_EXIT_CODE=1
}

# core
wd_warp()
{
    local point=$1

    if [[ $point =~ "^\.+$" ]]
    then
        if [ $#1 < 2 ]
        then
            wd_exit_warn "Warping to current directory?"
        else
            (( n = $#1 - 1 ))
            cd -$n > /dev/null
        fi
    elif [[ ${points[$point]} != "" ]]
    then
        cd ${points[$point]}
    else
        wd_exit_fail "Unknown warp point '${point}'"
    fi
}

wd_add()
{
    local force=$1
    local point=$2

    if [[ $point =~ "^[\.]+$" ]]
    then
        wd_exit_fail "Warp point cannot be just dots"
    elif [[ $point =~ "(\s|\ )+" ]]
    then
        wd_exit_fail "Warp point should not contain whitespace"
    elif [[ $point == *:* ]]
    then
        wd_exit_fail "Warp point cannot contain colons"
    elif [[ $point == "" ]]
    then
        wd_exit_fail "Warp point cannot be empty"
    elif [[ ${points[$2]} == "" ]] || $force
    then
        wd_remove $point > /dev/null
        printf "%q:%q\n" "${point}" "${PWD}" >> $WD_CONFIG

        wd_print_msg $WD_GREEN "Warp point added"

        # override exit code in case wd_remove did not remove any points
        # TODO: we should handle this kind of logic better
        WD_EXIT_CODE=0
    else
        wd_exit_warn "Warp point '${point}' already exists. Use 'add!' to overwrite."
    fi
}

wd_remove()
{
    local point=$1

    if [[ ${points[$point]} != "" ]]
    then
        local config_tmp=$WD_CONFIG.tmp
        if sed -n "/^${point}:.*$/!p" $WD_CONFIG > $config_tmp && mv $config_tmp $WD_CONFIG
        then
            wd_print_msg $WD_GREEN "Warp point removed"
        else
            wd_exit_fail "Something bad happened! Sorry."
        fi
    else
        wd_exit_fail "Warp point was not found"
    fi
}

wd_list_all()
{
    wd_print_msg $WD_BLUE "All warp points:"

    while IFS= read -r line
    do
        if [[ $line != "" ]]
        then
            arr=(${(s,:,)line})
            key=${arr[1]}
            val=${arr[2]}

            printf "%20s  ->  %s\n" $key $val
        fi
    done <<< $(sed "s:${HOME}:~:g" $WD_CONFIG)
}

wd_show()
{
    local name_arg=$1
    # if there's an argument we look up the value
    if [[ ! -z $name_arg ]]
    then
        if [[ -z $points[$name_arg] ]]
        then
            wd_print_msg $WD_BLUE "No warp point named $name_arg"
        else
            wd_print_msg $WD_GREEN "Warp point: ${WD_GREEN}$name_arg${WD_NOC} -> $points[$name_arg]"
        fi
    else
        # hax to create a local empty array
        local wd_matches
        wd_matches=()
        # do a reverse lookup to check whether PWD is in $points
        if [[ ${points[(r)$PWD]} == $PWD ]]
        then
            for name in ${(k)points}
            do
                if [[ $points[$name] == $PWD ]]
                then
                    wd_matches[$(($#wd_matches+1))]=$name
                fi
            done

            wd_print_msg $WD_BLUE "$#wd_matches warp point(s) to current directory: ${WD_GREEN}$wd_matches${WD_NOC}"
        else
            wd_print_msg $WD_BLUE "No warp points to $cwd"
        fi
    fi
}

wd_print_msg()
{
    if [[ -z $wd_quiet_mode ]]
    then
        local color=$1
        local msg=$2

        if [[ $color == "" || $msg == "" ]]
        then
            print " ${WD_RED}*${WD_NOC} Could not print message. Sorry!"
        else
            print " ${color}*${WD_NOC} ${msg}"
        fi
    fi
}

wd_print_usage()
{
    cat <<- EOF
Usage: wd [command] <point>

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

local WD_CONFIG=$HOME/.warprc
local WD_QUIET=0
local WD_EXIT_CODE=0
local WD_DEBUG=0

# Parse 'meta' options first to avoid the need to have them before
# other commands. The `-D` flag consumes recognized options so that
# the actual command parsing won't be affected.

zparseopts -D -E \
    c:=wd_alt_config -config:=wd_alt_config \
    q=wd_quiet_mode -quiet=wd_quiet_mode \
    v=wd_print_version -version=wd_print_version \
    d=wd_debug_mode -debug=wd_debug_mode

if [[ ! -z $wd_print_version ]]
then
    echo "wd version $WD_VERSION"
fi

if [[ ! -z $wd_alt_config ]]
then
    WD_CONFIG=$wd_alt_config[2]
fi

# check if config file exists
if [ ! -e $WD_CONFIG ]
then
    # if not, create config file
    touch $WD_CONFIG
fi

# load warp points
typeset -A points
while read -r line
do
    arr=(${(s,:,)line})
    key=${arr[1]}
    val=${arr[2]}

    points[$key]=$val
done < $WD_CONFIG

# get opts
args=$(getopt -o a:r:lhs -l add:,rm:,ls,help,show -- $*)

# check if no arguments were given
if [[ $? -ne 0 || $#* -eq 0 ]]
then
    wd_print_usage

    # check if config file is writeable
elif [ ! -w $WD_CONFIG ]
then
    # do nothing
    # can't run `exit`, as this would exit the executing shell
    wd_exit_fail "\'$WD_CONFIG\' is not writeable."

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
                wd_show $2
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
unset wd_alt_config
unset wd_quiet_mode
unset wd_print_version

unset args
unset points
unset val &> /dev/null # fixes issue #1

if [[ ! -z $wd_debug_mode ]]
then
    exit $WD_EXIT_CODE
else
    unset wd_debug_mode
fi
