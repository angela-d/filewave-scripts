#!/bin/bash
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/duplicate-zoom-check.txt
# local ip is used to determine whether or not the user is onsite
LOCALIP=$(ifconfig -l | xargs -n1 ipconfig getifaddr)
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in user
ACTIVE_USER=$(stat -f%Su /dev/console)
# regex of ip's to compare for onsite determination
ONSITE_IP="172.2*"
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

# use ip prefix to determine whether or not they're onsite
if [[ ! "$LOCALIP" =~ $ONSITE_IP ]];
then
  writeLog "$ACTIVE_USER is offsite"
else
  writeLog "$ACTIVE_USER is onsite"
fi

FOUND_ZOOM=$(find / -type d -name "*zoom*.app")
writeLog "\nFound apps:"

for VERSION in $FOUND_ZOOM;
do
  CURRENT_VERSION=$(defaults read "$VERSION"/Contents/Info CFBundleShortVersionString)
  writeLog "$VERSION Version: $CURRENT_VERSION\n"
done

# do a full check to see any possible zoom references
curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"

exit 0
