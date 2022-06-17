#!/bin/bash

# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/admin-check.txt
# active user
ACTIVE_USER=$(stat -f%Su /dev/console)
# if we're at the login screen, ACTIVE_USER will return root, so for good measure, a 2nd check
LAST_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/  { print $3 }')
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
WEBHOOK_URL="https://example/v1/your_webhook_api_stuff"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

# do a comparison check
if [ "$ACTIVE_USER" != "$LAST_USER" ];
then
	# nobody is signed in, probably; so no notification, but make note of it
  echo "Active user: $ACTIVE_USER and Last user: $LAST_USER differ - plausibly inactive session"
  NOTIFY=0
else
  NOTIFY=1
fi

# filewave logging only; no notification
echo -e "Hostname: $DEVICE_NAME\nActive User: $ACTIVE_USER"

# see if the user is even an admin
CHECK_PRIVS="$(dscacheutil -q group -a name admin | grep "$ACTIVE_USER")"
if [ "$CHECK_PRIVS" == "" ]; then
	echo "$ACTIVE_USER is not an admin; exiting."
	exit 0
else
  if [ "$NOTIFY" -eq 1 ];
  then
    # admin detected
    writeLog "$ACTIVE_USER on $DEVICE_NAME has admin privileges!"
    echo "Posting to chat room.."
    curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
  fi
fi

exit 0
