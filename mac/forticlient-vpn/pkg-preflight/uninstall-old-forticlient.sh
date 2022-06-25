#!/bin/bash
TARGET_VERSION="7.0.5.0166"
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/uninstall-forticlient-pkg.txt
# local ip is used to determine whether or not the user is onsite
LOCALIP=$(ifconfig -l | xargs -n1 ipconfig getifaddr)
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in (non-root) user
ACTIVE_USER=$(stat -f%Su /dev/console)
# regex of ip's to compare for onsite determination
ONSITE_IP="172.2*"
# url to post to a chat bot
WEBHOOK_URL="https://example/v1/your_webhook_stuff_here"
CURRENT_VERSION=$(defaults read /Applications/FortiClient.app/Contents/Info.plist CFBundleShortVersionString)

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

# version check
if [ ! "$CURRENT_VERSION" = "$TARGET_VERSION" ];
then
  writeLog "About to uninstall: $CURRENT_VERSION"
  SKIP_UPDATE=0
else
  echo "Forticlient already up to date: $TARGET_VERSION"
  SKIP_UPDATE=1
  # give a non-zero error code to prevent the pkg installation from happening, since we're already up to date
  exit 255
fi

if [ "$SKIP_UPDATE" -eq 0 ];
then
  writeLog "Hostname: $DEVICE_NAME\nActive User: $ACTIVE_USER"
  # use ip prefix to determine whether or not they're onsite
  if [[ ! "$LOCALIP" =~ $ONSITE_IP ]];
  then
    writeLog "$ACTIVE_USER is offsite"
  else
    writeLog "$ACTIVE_USER is onsite: $LOCALIP"
  fi

  # components of the path removal section are from a mini script posted to macadmins slack by Henri K
  # array of partial filename(s) to kill
  TO_KILL=(
  FortiClient
  )

  for target_service in "${TO_KILL[@]}";
  do
  	pkill -9 -f "$target_service" && writeLog "Killed $target_service"
  done

  "/Applications/FortiClientUninstaller.app/Contents/Library/LaunchServices/com.fortinet.forticlient.uninstall_helper" && writeLog "Ran uninstall helper" &&
  rm -rf "/Library/Application Support/Fortinet/" && writeLog "Removed root Fortinet Application Support files" &&
  rm -rf "/Library/Application Support/FortiClient/" && writeLog "Removed root FortiClient Application Support files" &&
  rm -rf /private/var/root/Library/Preferences/com.fortinet.FortiClientAgent.plist && writeLog "Removed plist data"

  # remove any residual stuff from user dirs, too
  USERS=$(dscl . list /Users | grep -v '^_' | grep -v daemon | grep -v nobody | grep -v root)

  while IFS= read -r USER; do
  	rm -rf "/Users/$USER/Library/Application Support/Fortinet/" && writeLog "Removed users/$USER Fortinet Application Support files"
  	rm -rf "/Users/$USER/Library/Application Support/FortiClient/" && writeLog "Removed users/$USER FortiClient Application Support files"
  done <<< "$USERS"

  writeLog "Upgrade PKG about to commence!"
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi
exit 0
