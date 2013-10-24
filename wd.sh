#!/bin/zsh

# WARP
# ====
# Jump to custom directories in terminal
# because `cd` takes too long...
#
# @ github.com/mfaerevaag/warp


# variables
FILENAME=".warprc"
CONFIG=$HOME/$FILENAME

# colors
BLUE="\033[96m"
GREEN="\033[92m"
YELLOW="\033[93m"
RED="\033[91m"
NOC="\033[m"


# if not exists
if [[ ! -e $CONFIG ]]
then
    touch $CONFIG
    print_msg $YELLOW "No config file found so one was created"
fi

typeset -A points

# read config
while read line
do
    arr=(${(s,:,)line})
    key=${arr[1]}
    val=${arr[2]}

    points[$key]=$val
done < $CONFIG


# functions
warp()
{
    if [[ $1 =~ ^[\.]+$ ]]
    then
        if [[ $#1 < 2 ]]
        then
            print_msg $YELLOW "Warping to current directory?"
        else
            (( n = $#1 - 1 ))
            print_msg $BLUE "Warping..."
            cd -$n > /dev/null
        fi
    elif [[ ${points[$1]} != "" ]]
    then
        print_msg $BLUE "Warping..."
        cd ${points[$1]}
    else
        print_msg $RED "Unkown warp point '$1'"
    fi
}

add()
{
    if [[ $1 =~ ^\.+$ ]]
    then
        print_msg $RED "Illeagal warp point (see README)."
    elif [[ ${points[$1]} == "" || $2 == "F" ]]
    then
        remove $1 > /dev/null
        print "$1:$PWD" >> $CONFIG
        print_msg $GREEN "Warp point added"
    else
        print_msg $YELLOW "Warp point '$1' alredy exists. Use 'add!' to overwrite."
    fi
}

remove()
{
    if [[ ${points[$1]} != "" ]]
    then
        TMP=mktemp
        sed "/$1:/d" $CONFIG > $TMP
        if [ $? -eq 0 ]
        then
            cat $TMP > $CONFIG
            rm -f $TMP
            print_msg $GREEN "Warp point removed"
        else
            print_msg $RED "Warp point unsuccessfully removed. Sorry!"
        fi
    else
        print_msg $RED "Warp point was not found"
    fi
}

list_all()
{
    print_msg $BLUE "All warp points:"
    while read line
    do
        arr=(${(s,:,)line})
        key=${arr[1]}
        val=${arr[2]}

        print "\t" $key "\t -> \t" $val
    done < $CONFIG
}

print_msg()
{
    if [[ $1 == "" || $2 == "" ]]
    then
        print " $RED*$NOC Could not print message. Sorry!"
    else
        print " $1*$NOC $2"
    fi
}


# get opts
args=`getopt -o a:r:l -l add:,remove:,list -- $*`

# run
if [[ $? -ne 0 || $#* -eq 0 ]]
then
		print "Usage: wd [add|-a|--add] [rm|-r|--remove] [ls|-l|--list] <point>"
    print "\nCommands:"
    print "\t add \t Adds the current working directory to your warp points"
    print "\t add! \t Overwrites existing warp point"
    print "\t remove  Removes the given warp point"
    print "\t list \t Outputs all stored warp points"
else
    # can't exit, as this would exit the excecuting shell
    # e.i. your terminal

    #set -- $args # WTF

    for i
    do
		    case "$i"
		        in
			      -a|--add|add)
                add $2
				        shift
                shift
                break
                ;;
            -a!|--add!|add!)
                add $2 "F"
				        shift
                shift
                break
                ;;
			      -r|--remove|rm)
				        remove $2
                shift
				        shift
                break
                ;;
			      -l|--list|ls)
				        list_all
				        shift
                break
                ;;
            *)
                warp $i
                shift
                break
                ;;
			      --)
				        shift; break;;
		    esac
    done
fi # exit


# garbage collection
# if not, next time warp will pick up variables from this run
# remember, there's no sub shell
points=""
unhash -d val # fixes issue #1
