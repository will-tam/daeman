#!/bin/bash

# daeman.sh : daemon manager ou management, as anyone wishes.
# Start or stop some preset services, through Systemd.
# Renewal of my 2 shell scripts with "dialog" within only 1 with "whiptail".
# Will_tam - ver 20170525-benri
#
# Yes, start() and stop() have common points !!!


CONFFILE=$(dirname "$0")/../etc/startstop.conf      # Where is the config file ?
nonAuto=$(cat $CONFFILE 2> /dev/null)        # What inside it ?


function helpThisHuman()
# Simply display some help.
# @Parameters : none.
# @Return : none.
{
    echo -en "\nHelp :\n"
    echo -en "possible using : daeman.sh [start | stop]\n\n"
    echo -en "If no arguments, opening of a menu.\n\n"
}

function informThem()
# Display a message box for some informations.
# See man whiptail or http://xmodulo.com/create-dialog-boxes-interactive-shell-script.html (thanks)
# @Parameters : a message to display.
# @Return : none.
{
    whiptail --clear\
             --title "For your information"\
             --msgbox "$1"\
             7 30
}

function menuOfTheDay()
# Display the main menu, under some conditions (see main()-like at deep of this script).
# See man whiptail or http://xmodulo.com/create-dialog-boxes-interactive-shell-script.html (thanks)
# @Parameters : none.
# @Return : what the user has choosen.
{
    whiptail --clear\
             --title="Menu of the day."\
             --fb\
             --yes-button "Invoke a daemon"\
             --no-button "Exorcise a démon"\
             --yesno "You should prefer"\
             10 80\
             3>&1 1>&2 2>&3
    echo $?
}

function daemonsMenu()
# Display the commun menu of the services to start or stop.
# See man whiptail or http://xmodulo.com/create-dialog-boxes-interactive-shell-script.html (thanks)
# @Parameters : none.
# @Return : the wanted daemon(s) without any quotes.
{
    daemons=$(whiptail --clear\
                       --title="Who should be invoked"\
                       --fb\
                       --checklist "One or more of them"\
                       20 40 10\
                       $items\
                       3>&1 1>&2 2>&3)

    echo ${daemons//\"/}     # Thanks http://www.linuxquestions.org/questions/linux-newbie-8/bash-command-for-removing-special-characters-from-string-644828/ and man bash
}

function start()
# Start wanted deamon(s).
# @Parameters : none.
# @Return : none.
{
    items=""

    # systemclt status service
    # ret = 3 => Inactive
    for l in $nonAuto; do
        systemctl status $l > /dev/null 2>&1
        ret=$?
        if [ $ret -eq 3 ]; then
            items=$items$(echo $l $l off" ")    # Not started yet, will display it.
        fi
    done

    if [[ -z $items ]]; then        # Nothing to do ? So, inform it.
        informThem "No more daemons to invoke !"
        exit 0
    fi
    
    choices=$(daemonsMenu $items)
    
    # Check if something has been chooseen.
    if [[ -n $choices ]]; then
        for l in $choices; do
            echo -en $l "\n\tStarting\n"
            systemctl start $l
        done
    fi
}

function stop()
# Stop wanted deamon(s).
# @Parameters : none.
# @Return : none.
{
    items=""

    # systemclt status service
    # ret = 0 => Ok
    for l in $nonAuto; do
        systemctl status $l > /dev/null 2>&1
        ret=$?
        if [ $ret -eq 0 ]; then
            items=$items$(echo $l $l off" ")    # Not stopped yet, will display it.
        fi
    done

    if [[ -z $items ]]; then        # Nothing to do ? So, inform it.
        informThem "No daemon to exorcise !"
        exit 0
    fi
    
    choices=$(daemonsMenu $items)
    
    # Check if something has been chooseen.
    if [[ -n $choices ]]; then
        for l in $choices; do
            echo -en $l "\n\tStopping\n"
            systemctl stop $l
        echo -en "\tDeactivate\n"
        systemctl disable $l
        done
    fi
}


# main() {
args=$@    # Maybe, a user wants something.

[ -z $args ] && args=$(menuOfTheDay)       # No argument ? Proposition of the menu. The argument become the wanted daemon(s).

while true;do   # Just do it, eternally ... will be brooken with an exit 0.
    case $args in
        0 | "start") start; exit 0;;
        1 | "stop") stop; exit 0;;
        "help") helpThisHuman; exit 0;;
        *) args=$(menuOfTheDay);;
    esac
done
#}