#!/bin/bash
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/chrome-check.txt
# local ip is used to determine whether or not the user is onsite
LOCALIP=$(ifconfig -l | xargs -n1 ipconfig getifaddr)
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in (non-root) user, might be useful at some point
ACTIVE_USER=$(stat -f%Su /dev/console)
# regex of ip's to compare for onsite determination
ONSITE_IP="172.2*"
# url to post to a chat bot
WEBHOOK_URL="https://your api chatbot url here"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

writeLog "Hostname: $DEVICE_NAME\nActive User: $ACTIVE_USER"

# use ip prefix to determine whether or not they're onsite
if [[ ! "$LOCALIP" =~ $ONSITE_IP ]];
then
  ONSITE="0"
  writeLog "$ACTIVE_USER is offsite"
else
  ONSITE="1"
  writeLog "$ACTIVE_USER is onsite"
fi

# check for mounted dmg and unmount, if so (yes, some people were running chrome like this; preventing it from updating...)
GOOGLE_MOUNT=$(diskutil list | grep "Google Chrome")

if [ "$GOOGLE_MOUNT" ];
then
  writeLog " >> A Google Chrome mount was found.. unmounting"
  hdiutil eject /Volumes/Google\ Chrome && writeLog ">> Success: Ejected Google Chrome"
else
  writeLog "No Google Chrome installers mounted"
fi

# not entirely sure how important the launchservices db being up-to-date is
# when the user allows an update from their site (browser restart), the framework -does not- update
# a separate script can be run to do so, with no apparent ux interruption, or re-deployment of a new pkg
# pkg route is preferred, as eventually chrome cannot be updated as the deployed version veers too long
# sed to replace tabs with spaces, for readability
writeLog "\n\n :: Searching launch services database :: "
lsDB="$(/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump | grep -i "google chrome" | grep "path" | grep -v "Volumes" | sed -e "s/[[:space:]]\+/ /g")"
writeLog "$lsDB"


# webhook to chat if offsite
# gchat has a limit of 4096 characters; quoted values will need escaping
if [ "$ONSITE" == "0" ];
then
  echo "User was offsite when this test was ran, sending a webhook.."
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi

echo "Done."
exit 0
