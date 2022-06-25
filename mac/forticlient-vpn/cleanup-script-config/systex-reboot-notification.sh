#!/bin/bash

# get the user firstname
FIRSTNAME="$(id -F | awk '{print $1}')"
ICON="/var/scripts/your_fileset_id/icon.icns"

# generates an alert box with 2 args, the user must click OK to rid
function alert() {

  osascript -e 'display dialog "'"$1\n\n$2"'" with icon POSIX file "'"$ICON"'" with title "VPN Client Update" buttons {"OK"}'

}

alert "$FIRSTNAME, IT deployed a security update to your VPN client." "In order for the security settings to auto-configure for your machine, a full system reboot will be necessary:\n\n- Click the Apple icon in the top bar\n- Select Restart\n\nThis can be done at a time that is convenient for you, but your VPN may experience issues until the reboot takes place.\n\nIf you need assistance, email us: it@yourorg\n\t\t\t\t\t- YOURORG IT"

exit 0
