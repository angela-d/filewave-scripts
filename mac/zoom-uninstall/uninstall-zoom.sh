#!/bin/bash
# log to easily attach to the webhook
TMPLOG="/tmp/zoom-uninstall.txt"
# signed in user
ACTIVE_USER=$(stat -f%Su /dev/console)
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
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

# array of partial filename(s) to kill
TO_KILL=(
Zoom
)

for target_service in "${TO_KILL[@]}";
do
  pkill -9 -f "$target_service" && writeLog "Killed $target_service service\n"
done


function removeAllUsersZoom() {
  # remove any residual stuff from user dirs, too
  USERS=$(dscl . list /Users | grep -v '^_' | grep -v daemon | grep -v nobody | grep -v root)
  writeLog "Machine users:\n $USERS\n"

  while IFS= read -r USER; do
    rm -rf "/Users/$USER/Applications/zoom.us.app" && writeLog "Removed users/$USER Zoom app from Applications"
    rm "/Users/$USER/Library/Internet Plug-Ins/ZoomUsPlugIn.plugin" && writeLog "Removed /Users/$USER/Library/Internet Plug-Ins/ZoomUsPlugIn.plugin"
    rm -rf "/Users/$USER/Library/Application Support/zoom.us/" && writeLog "Removed /Users/$USER/Library/Application Support/zoom.us/"
    rm /Users/"$USER"/Library/Preferences/us.zoom.xos.plist && writeLog "Removed /Users/$USER/Library/Preferences/us.zoom.xos.plist"
    rm /Users/"$USER"/Library/Preferences/ZoomChat.plist && writeLog "Removed /Users/$USER/Library/Preferences/ZoomChat.plist"
    rm /Users/"$USER"/Library/Caches/us.zoom.xos && writeLog "Removed /Users/$USER/Library/Caches/us.zoom.xos"
  done <<< "$USERS"
}

function locateZoom() {
  if [ -e "$1" ] && [ "$ACTIVE_USER" != "root" ];
  then
    writeLog "\n$ACTIVE_USER on $DEVICE_NAME had Zoom installed, at $1 -- it will be removed."
    echo "FOUND: $1 matches; removing..."
    rm -rf "$1" && writeLog "SUCCESS: Removed $1"

    echo "Verifying removal..."
    locateZoom "$1"
    echo "Posting to chat room.."
    curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
  elif [ "$ACTIVE_USER" = "root" ];
  then
    echo "No user signed in, at the moment - possibly on login screen."
  else
    echo "No match for $1"
  fi
}

# scope for not signed in users, too
removeAllUsersZoom

# wildcard removal doesn't appear to work
echo "Looking for matches..."
locateZoom "/Users/$ACTIVE_USER/Desktop/zoom.us.app"
locateZoom "/Users/$ACTIVE_USER/.Trash/zoom.us.app"
locateZoom "/Applications/zoom.us.app"

exit 0
