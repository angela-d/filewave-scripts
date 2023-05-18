#!/bin/bash
# put the token in an env in filewave with the var MAINT_TOKEN:
# double-click the script fileset, ie. Crowdstrike License
# nav to /var/scripts/[id]/uninstall-crowdstrike.sh > select > get info > executable tab
# > environment variables tab > put token in value box beside MAINT_TOKEN
# https://www.crowdstrike.com/blog/tech-center/uninstall-protection-for-the-falcon-agent/

# possibly of use if system extension removal becomes an issue:
# https://www.buaq.net/go-89156.html

# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/crowdstrike-uninstall.txt
# active user
ACTIVE_USER=$(stat -f%Su /dev/console)
# if we're at the login screen, ACTIVE_USER will return root, so for good measure:
LAST_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/  { print $3 }')
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
WEBHOOK_URL="your_chatbot_webhook_here"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

function confirmRemoval {
    if [ -e /Applications/Falcon.app ];
    then
        writeLog "/Applications/Falcon.app still exists; removal unsuccessful!"
        writeLog "Fileset disassociated, but the Falcon app remains on the machine!  Send a secondary script to fix this."
    else
        writeLog "/Applications/Falcon.app appears to have been removed successfully."
    fi
}

[ "$ACTIVE_USER" == "root" ] && ACTIVE_USER="$LAST_USER"

writeLog "== Crowd Strike uninstall requested for $DEVICE_NAME used by $ACTIVE_USER =="

if [ -z "$MAIN_TOKEN" ];
then
    writeLog "No maintenance token in Filewave env vars, trying removal without..."
    /Applications/Falcon.app/Contents/Resources/falconctl uninstall

    sleep 5

    confirmRemoval
else
    /Applications/Falcon.app/Contents/Resources/falconctl uninstall --maintenance-token "$MAINT_TOKEN"

    sleep 5

    confirmRemoval
fi

# uninstall system extension
systemextensionsctl uninstall X9E956P446 com.crowdstrike.falcon.Agent && writeLog "Successfully uninstalled com.crowdstrike.falcon.Agent"


# test system extension
if [ "$(systemextensionsctl list | grep -i strike)" == "" ];
then
    writeLog "System extension test passed; no extensions matching Crowd Strike found!"
else
    writeLog "\t>> System extension test exception - found:"
    writeLog "\t$(systemextensionsctl list | grep -i strike)"
fi

[ -e /Applications/Falcon.app ] && rm -rf /Applications/Falcon.app && writeLog "Manual removal of the Falcon app successful"

writeLog "\n\n== If this was not intentional, check on the machine! =="

# it looks like they unload the launchagent, but the config remains
[ -e /Library/LaunchAgents/com.crowdstrike.falcon.UserAgent.plist ] && rm /Library/LaunchAgents/com.crowdstrike.falcon.UserAgent.plist && writeLog "Manually removed /Library/LaunchAgents/com.crowdstrike.falcon.UserAgent.plist"

echo "Posting to chat room.."
curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"

exit 0
