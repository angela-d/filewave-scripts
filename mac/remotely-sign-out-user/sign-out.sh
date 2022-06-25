#!/bin/bash
# user to sign out
KICKOUT="johndoe"
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/signout.txt
# local ip
LOCALIP=$(ifconfig -l | xargs -n1 ipconfig getifaddr)
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in user
ACTIVE_USER=$(stat -f%Su /dev/console)
# url to post to a chat bot
WEBHOOK_URL="https://example/v1/your_webhook_stuff_here"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

writeLog "Hostname: $DEVICE_NAME\nActive User: $ACTIVE_USER\nLocal IP: $LOCALIP"

# send signoff
launchctl bootout user/$(id -u "$KICKOUT") && writeLog "Signed out $KICKOUT"

curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"

exit 0
