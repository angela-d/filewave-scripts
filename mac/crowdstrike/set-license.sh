#!/bin/bash
# put the key in an env in filewave with the var LICENSE:
# double-click the script fileset, ie. Crowdstrike License
# nav to /var/scripts/[id]/set-license.sh > select > get info > executable tab
# > environment variables tab > put token in value box beside LICENSE

# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/crowdstrike-setup.txt
# active user
ACTIVE_USER=$(stat -f%Su /dev/console)
# if we're at the login screen, ACTIVE_USER will return root, so for good measure:
LAST_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/  { print $3 }')
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
WEBHOOK_URL="your_chatbot_webhook_here"
#license is being sent by env in filewave

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

[ "$ACTIVE_USER" == "root" ] && ACTIVE_USER="$LAST_USER"

writeLog "== Crowd Strike license setup for $DEVICE_NAME used by $ACTIVE_USER =="
if [ -e /Applications/Falcon.app/Contents/Resources/falconctl ];
then
  /Applications/Falcon.app/Contents/Resources/falconctl license "$LICENSE" && echo "License key applied successfully"
  NOTIFY=0
else
  writeLog "\t>> /Applications/Falcon.app/Contents/Resources/falconctl does not yet exist, license NOT applied!"
  NOTIFY=1
fi

if [ "$NOTIFY" -eq 1 ];
then
  echo "Posting to chat room.."
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi

exit 0
