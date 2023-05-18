#!/bin/bash
# only send webhooks for this user
SEND_WEBHOOK="your_asset_tag_here"
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/falcon.txt
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in (non-root) user
ACTIVE_USER=$(stat -f%Su /dev/console)
# if we're at the login screen, ACTIVE_USER will return root, so for good measure:
LAST_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/  { print $3 }')
# url to post to a chat bot
WEBHOOK_URL="your_chatbot_url_here"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog() {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

# user / last user of the machine
if [ "$ACTIVE_USER" != "root" ] && [ "$ACTIVE_USER" != "loginwindow" ];
then
  USEDBY="used by $ACTIVE_USER"
elif [ "$ACTIVE_USER" == "loginwindow" ] || [ "$ACTIVE_USER" == "root" ];
then
  USEDBY="- not currently in use by anyone"
else
  USEDBY="last used by $LAST_USER"
fi


echo "=== Output of FALCON_STATS on $DEVICE_NAME $USEDBY: ===" > /tmp/falcon.txt
/Applications/Falcon.app/Contents/Resources/falconctl stats >> /tmp/falcon.txt

echo -e "\n\n=== System extensions: ===\n" >> /tmp/falcon.txt
systemextensionsctl list >> /tmp/falcon.txt

echo -e "\n\n=== System extension tmp file: ===\n" >> /tmp/falcon.txt
cat /tmp/systemext.plist >> /tmp/falcon.txt

if [ "$SEND_WEBHOOK" != "" ];
then
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi

exit 0