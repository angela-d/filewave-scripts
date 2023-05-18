#!/bin/bash
ACTIVE_USER=$(stat -f%Su /dev/console)
FIRSTNAME="$(id -F | awk '{print $1}')"
ICON="/usr/local/icons/yourcompany/icon.icns"

# argument is passed from the health check script in filewave
if [ "$1" == "update" ];
then
    TITLE="Security Suite Update"
    MSG="$FIRSTNAME, your security suite has been updated and requires a restart to finish configuring itself.\n\n\n\nPlease save your work and reboot at your earliest convenience to ensure your machine is protected from technological threats on the web."
elif [ "$1" == "issue" ];
then
    TITLE="Security Suite Issue"
    MSG="$FIRSTNAME, there is an issue with your security suite - your machine is vulnerable and not protected!\n\n\n\nPlease reboot your machine and contact IT if this message persists."
fi

# details are passed by the root script
CHOICES=$(osascript -e 'display dialog "'"$MSG"'" with icon POSIX file "'"$ICON"'" with title "'"$TITLE"'" buttons {"I Need Help", "Restart Now", "Restart Later"} default button "Restart Later"')

if [[ "$CHOICES"  = "button returned:I Need Help"* ]];
then
    # this assumes you use the it help app: https://github.com/angela-d/it-help-app
    open "/Users/$ACTIVE_USER/Desktop/IT Help.app"
    exit 0
elif [[ "$CHOICES"  = "button returned:Restart Now"* ]];
then
    osascript -e 'tell app "loginwindow" to «event aevtrrst»'
    exit 0
elif [[ "$CHOICES"  = "button returned:Restart Later"* ]];
then
    exit 0
fi

exit 0
