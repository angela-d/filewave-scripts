#!/bin/bash
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/forti-check.txt
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in (non-root) user
ACTIVE_USER=$(stat -f%Su /dev/console)
# url to post to a chat bot
WEBHOOK_URL="https://example/v1/spaces/webhook_stuff_here"

TARGET_VERSION="7.0.5.0166"
CURRENT_VERSION=$(defaults read /Applications/FortiClient.app/Contents/Info.plist CFBundleShortVersionString)
NOTIFY_BOT=0

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

function checkConfig {
  if [ -e "$1" ];
  then
     echo "$1 exists"
  else
    writeLog "$1 missing"
    NOTIFY_BOT=1
  fi
}

writeLog "Hostname: $DEVICE_NAME\nActive User: $ACTIVE_USER"

# version check
if [ ! "$CURRENT_VERSION" = "$TARGET_VERSION" ];
then
  writeLog "FORTICLIENT OUT OF DATE: $CURRENT_VERSION"
else
  echo "Forticlient up to date: $CURRENT_VERSION"
fi

# make sure config exists
USER_CONFIG="/Users/$ACTIVE_USER/Library/Application Support/Fortinet/FortiClient/conf/vpn.plist"
ROOT_CONFIG="/Library/Application Support/Fortinet/FortiClient/conf/vpn.plist"

checkConfig "$USER_CONFIG"
checkConfig "$ROOT_CONFIG"

# system extension check
SYSEXT=$(systemextensionsctl list | grep "forticlient")
CURRENT_VERSION=$(defaults read /Applications/FortiClient.app/Contents/Info.plist CFBundleShortVersionString)

writeLog "\n\nSystem Extenstion Overview:"

if [ "$CURRENT_VERSION" = "$TARGET_VERSION" ] && [ ! "$ACTIVE_USER" = "root" ];
then
  # collect data from the systemextensionsctl command
  # redundancies, but drilling down will isolate the problem more readably
  IS_ENABLED=$(echo "$SYSEXT" | awk '{ print $1 }')
  IS_ACTIVE=$(echo "$SYSEXT" | awk '{ print $2 }')
  EXT_STATUS=$(echo "$SYSEXT" | awk '{print substr($0,index($0,$7))}')

  if [ "$IS_ENABLED" = "*" ];
  then
    writeLog "Enabled: Yes"
  else
    writeLog "Enabled: No"
  fi

  if [ "$IS_ACTIVE" = "*" ];
  then
    writeLog "Enabled: Yes"
  else
    writeLog "Enabled: No"
  fi

  if [ "$EXT_STATUS" = "[activated enabled]" ];
  then
    writeLog "Extension Status: activated enabled"
  else
    writeLog "Extension Status: $EXT_STATUS"
    writeLog "GUI prompt sent to $ACTIVE_USER"
    # bug: if the user lets the popup linger, the script never finishes.  some more exploration is needed to discard the wait
    su -l $ACTIVE_USER -c '/usr/local/sbin/systext-reboot-notification.sh' && writeLog "Restart popup sent to $ACTIVE_USER"
    NOTIFY_BOT=1
  fi
elif [ "$ACTIVE_USER" = "root" ];
then
  echo "User not logged in; not sending notice - will on next verify."
  NOTIFY_BOT=0
else
  writeLog "Potential app installation failure; version mismatch - system extension check skipped!"
  writeLog "Current version: $CURRENT_VERSION"
fi

if [ "$NOTIFY_BOT" -eq 1 ];
then
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi

exit 0
