#!/bin/bash
# turn off tamper protection before deployment
# https://cloud.sophos.com/manage/endpoint/config/settings/tamper-protection

# scan extension doesnt seem to remove
# if issues persist, a manual removal is required: 
# https://forums.macrumors.com/threads/removing-com-sophos-endpoint-scanextension.2337752/post-30931739
# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/sophos-uninstall.txt
# active user
ACTIVE_USER=$(stat -f%Su /dev/console)
# if we're at the login screen, ACTIVE_USER will return root, so for good measure:
LAST_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/  { print $3 }')
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
WEBHOOK_URL="your_chatbot_webhook_here"
NOTIFY=0
# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

function uninstallTest {
    # see if components still exist
    if [ -e /Applications/Sophos/Sophos\ Endpoint.app ];
    then
        NOTIFY=1
        writeLog "Uninstall from /Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer failed!"
        writeLog "/Applications/Sophos/Sophos Endpoint.app still exists.\n"
    else
        writeLog "Uninstall appears successful; /Applications/Sophos/Sophos Endpoint.app not found!"
    fi

    if [ -e /Applications/Sophos/Sophos\ Network\ Extension.app ];
    then
        NOTIFY=1
        writeLog "\t>> Uninstall from /Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer failed!"
        writeLog "\t>>/Applications/Sophos/Sophos Network Extension.appp still exists.\n"
    else
        NOTIFY=0
        writeLog "Uninstall appears successful; /Applications/Sophos/Sophos Network Extension.app not found!"
    fi
}

function removeThis {
    if [[ -e "$1" ]];
    then
        rm -rf "$1" && writeLog "Removed $1"
    else
        writeLog "$1 not found, nothing to remove"
    fi
}

function removeThisGlob {
    # do a separate approach for wildcards, otherwise there's a false-negative
    if [[ "$(ls $1 2> /dev/null | wc -l)" -ge 1 ]];
    then
        rm -r "$1" && writeLog "Removed $1"
    else
        writeLog "$1 not found, nothing to remove"
    fi
}

if [ "$ACTIVE_USER" != "root" ] && [ "$ACTIVE_USER" != "loginwindow" ];
then
  USEDBY=" used by $ACTIVE_USER"
elif [ "$ACTIVE_USER" == "loginwindow" ] || [ "$ACTIVE_USER" == "root" ];
then
  USEDBY=" - not currently in use by anyone"
else
  USEDBY=" last used by $LAST_USER"
fi

writeLog "== Sophos uninstall for $DEVICE_NAME $USEDBY =="

pkill -9 "Sophos*" && writeLog "Successfully killed all running Sophos apps"

if [ -e /Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer ];
then
    /Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer --remove && writeLog "Ran /Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer"
    sleep 5

    uninstallTest
else
    writeLog "\t>>/Library/Application\ Support/Sophos/saas/Installer.app/Contents/MacOS/tools/InstallationDeployer does not exist!!"
    writeLog "\t>>Possibly already removed"
fi

# remove files.. because i don't trust their uninstaller to be thorough
removeThis "/Library/Sophos\ Anti-Virus"
removeThisGlob "/Library/LaunchDaemons/com.sophos.*"
removeThisGlob "/Library/LaunchAgents/com.sophos.*"
removeThisGlob "/Library/Preferences/com.sophos.*"
removeThis "/Library/Logs/Sophos\ Anti-Virus.log"
removeThis "/Users/$ACTIVE_USER/Library/Logs/Sophos\ Anti-Virus/Scans/"
removeThis "/Library/Sophos\ Anti-Virus/"
removeThis "/Library/Application\ Support/Sophos/"
removeThis "/Applications/Sophos\ Anti-Virus.app"
removeThis "/Applications/Remove\ Sophos\ Anti-Virus.app"
removeThisGlob "/Applications/Sophos/*"
removeThis "/var/db/receipts/com.sophos.*"
removeThisGlob "/Library/Extensions/Sophos*"
removeThis "/Library/Frameworks/SAVI-pyexec.framework "
removeThis "/Library/Frameworks/SAVI.framework"
removeThis "/Library/Frameworks/SophosGenericsCommon.framework"
removeThis "/Library/Frameworks/SophosGenericsCore.framework"

/usr/bin/dscl . -delete /Users/_sophos && writeLog "Deleted _sophos user"

systemextensionsctl uninstall 2H5GFH3774 com.sophos.endpoint.scanextension && writeLog "Successfully uninstalled com.sophos.endpoint.scanextension"
systemextensionsctl uninstall 2H5GFH3774 com.sophos.endpoint.networkextension && writeLog "Successfully uninstalled com.sophos.endpoint.networkextension"

# test system extension
if [ "$(systemextensionsctl list | grep -i sophos)" == "" ];
then
    writeLog "System extension test passed; no extensions matching Sophos found!"
else
    # don't care about the sophos extension anymore
    NOTIFY=0
    writeLog "\t>> System extension test FAILED - found:"
    writeLog "\t$(systemextensionsctl list | grep -i sophos)"
    writeLog "\tcom.sophos.endpoint.scanextension may need to be removed in safe mode"
    writeLog "\tIf issues persist, remove manually - see source code of sophos-uninstall.sh"
fi

if [ "$NOTIFY" -eq 1 ];
then
  echo "Posting to chat room.."
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi

exit 0
