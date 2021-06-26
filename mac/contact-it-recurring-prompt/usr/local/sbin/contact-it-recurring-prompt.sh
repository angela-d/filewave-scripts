#!/bin/bash

# get the user firstname
FIRSTNAME="$(id -F | awk '{print $1}')"
ICON="/var/scripts/contact-it-prompt/AppIcon.icns"

# generates an alert box with 2 args, the user must click OK to rid
function alert() {

  osascript -e 'display dialog "'"$1\n\n$2"'" with icon POSIX file "'"$ICON"'" buttons {"Ok"}'

}

alert "$FIRSTNAME, Please Contact IT" "You have an open ticket that needs to be resolved immediately.\nEmail at your earliest convenience: support@example.com\n\t\t\t\t\t- Example IT"

exit 0
