#!/bin/zsh

# WARP
# ====
# Jump to custom directories in terminal
# because `cd` takes too long...
#
# @github.com/mfaerevaag/warp


## variables
FILENAME=".warprc"
CONFIG=$HOME/$FILENAME

## colors
BLUE="\033[96m"
GREEN="\033[92m"
YELLOW="\033[93m"
RED="\033[91m"
NOC="\033[m"


## if not exists
if [[ ! -e $CONFIG ]]
then
    touch $CONFIG
    wd_print_msg $YELLOW "No config file found so one was created"
fi

# hash with warp points
typeset -A points

# read config
while read line
do
    arr=(${(s,:,)line})
    key=${arr[1]}
    val=${arr[2]}

    points[$key]=$val
done < $CONFIG


## functions
# prepended wd_ to not conflict with your environment (no sub shell)

wd_warp()
{
    if [[ $1 =~ "^\.+$" ]]
    then
        if [[ $#1 < 2 ]]
        then
            wd_print_msg $YELLOW "Warping to current directory?"
        else
            (( n = $#1 - 1 ))
            wd_print_msg $BLUE "Warping..."
            cd -$n > /dev/null
        fi
    elif [[ ${points[$1]} != "" ]]
    then
        wd_print_msg $BLUE "Warping..."
        cd ${points[$1]}
    else
        wd_print_msg $RED "Unkown warp point '$1'"
    fi
}

wd_add()
{
    if [[ $1 =~ "^\.+$" ]]
    then
        wd_print_msg $RED "Illeagal warp point (see README)."
    elif [[ ${points[$1]} == "" ]] || $2
    then
        wd_remove $1 > /dev/null
        print "$1:$PWD" >> $CONFIG
        wd_print_msg $GREEN "Warp point added"
    else
        wd_print_msg $YELLOW "Warp point '$1' alredy exists. Use 'add!' to overwrite."
    fi
}

wd_remove()
{
    if [[ ${points[$1]} != "" ]]
    then
        TMP=mktemp
        sed "/$1:/d" $CONFIG > $TMP
        if [ $? -eq 0 ]
        then
            cat $TMP > $CONFIG
            rm -f $TMP
            wd_print_msg $GREEN "Warp point removed"
        else
            wd_print_msg $RED "Warp point unsuccessfully removed. Sorry!"
        fi
    else
        wd_print_msg $RED "Warp point was not found"
    fi
}

wd_list_all()
{
    wd_print_msg $BLUE "All warp points:"
    while read line
    do
        arr=(${(s,:,)line})
        key=${arr[1]}
        val=${arr[2]}

        print "\t" $key "\t -> \t" $val
    done < $CONFIG
}

wd_print_msg()
{
    if [[ $1 == "" || $2 == "" ]]
    then
        print " $RED*$NOC Could not print message. Sorry!"
    else
        print " $1*$NOC $2"
    fi
}

wd_print_usage()
{
		print "Usage: wd [add|-a|--add] [rm|-r|--remove] [ls|-l|--list] <point>"
    print "\nCommands:"
    print "\t add \t Adds the current working directory to your warp points"
    print "\t add! \t Overwrites existing warp point"
    print "\t remove  Removes the given warp point"
    print "\t list \t Outputs all stored warp points"
    print "\t help \t Show this extremely helpful text"
}


## run

# get opts
args=`getopt -o a:r:lh -l add:,remove:,list,help -- $*`

if [[ $? -ne 0 || $#* -eq 0 ]]
then
    wd_print_usage
else
    # can't exit, as this would exit the excecuting shell
    # e.i. your terminal

    #set -- $args # WTF

    for i
    do
		    case "$i"
		        in
			      -a|--add|add)
                wd_add $2 false
				        shift
                shift
                break
                ;;
            -a!|--add!|add!)
                wd_add $2 true
				        shift
                shift
                break
                ;;
			      -r|--remove|rm)
				        wd_remove $2
                shift
				        shift
                break
                ;;
			      -l|--list|ls)
				        wd_list_all
				        shift
                break
                ;;
			      -h|--help|help)
				        wd_print_usage
				        shift
                break
                ;;
            *)
                wd_warp $i
                shift
                break
                ;;
			      --)
				        shift; break;;
		    esac
    done
fi


## garbage collection
# if not, next time warp will pick up variables from this run
# remember, there's no sub shell
points=""
args=""
unhash -d val # fixes issue #1
