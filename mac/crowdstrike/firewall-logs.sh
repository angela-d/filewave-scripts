#!/bin/bash
POST_WEBHOOK="1"
# note that if the user is offsite, you need the LOCAL targets, not their external ip
SEARCH_TARGET="192.168.1.154"
SEARCH_NOTE=""
SEARCH_LIMIT="10"
# addl searching in one swoop
SEARCH_EXPAND=""
SEARCH_EXPAND_NOTE=""
SEARCH_EXPAND_LIMIT="10"
# don't touch after this
FW_LOGS="/Library/Application Support/CrowdStrike/Falcon/hbfw.log"
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/cs-firewall-search.txt
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in (non-root) user, might be useful at some point
ACTIVE_USER=$(stat -f%Su /dev/console)
# if we're at the login screen, ACTIVE_USER will return root, so for good measure:
LAST_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/  { print $3 }')
# url to post to a chat bot
WEBHOOK_URL="your_chatbot_webhook_here"

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


# start the search + output
FW_QUERY=$(cat "$FW_LOGS" | grep "$SEARCH_EXPAND" | tail -n "$SEARCH_LIMIT")

writeLog "=== Output of firewall logs search for $SEARCH_TARGET on $DEVICE_NAME $USEDBY ==="
[ "$SEARCH_NOTE" != "" ] && writeLog "$SEARCH_NOTE"
writeLog "$FW_QUERY"
writeLog "\nLimited to $SEARCH_LIMIT lines"

# expanded search + output
if [ "$SEARCH_EXPAND" != "" ] && [ "$SEARCH_EXPAND_LIMIT" != "" ];
then
    FW_QUERY=$(cat "$FW_LOGS" | grep "$SEARCH_TARGET" | tail -n "$SEARCH_EXPAND_LIMIT")

    writeLog "=== Expanded search for $SEARCH_EXPAND on $DEVICE_NAME $USEDBY ==="
    [ "$SEARCH_EXPAND_NOTE" != "" ] && writeLog "$SEARCH_EXPAND_NOTE"
    writeLog "$FW_QUERY"
    writeLog "\nLimited to $SEARCH_EXPAND_LIMIT lines"
fi


if [ "$POST_WEBHOOK" -eq 1 ];
then
  echo "done"
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi

exit 0