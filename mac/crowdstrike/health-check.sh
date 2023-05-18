#!/bin/bash
TARGET_VERSION="6.54.16702"
FEATURE_VERSION="6.55.16804"

# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/crowdstrike-health-check.txt
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# signed in (non-root) user, might be useful at some point
ACTIVE_USER=$(stat -f%Su /dev/console)
# if we're at the login screen, ACTIVE_USER will return root, so for good measure:
LAST_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/  { print $3 }')
# url to post to a chat bot
WEBHOOK_URL="your_chatbot_webhook_here"
# trim the last . to ignore odd patch versions, only care about the pkg, really
CURRENT_VERSION=$(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep version | awk '{print $2}' | rev | cut -d. -f2- | rev | sed 's/[^0-9.]//g')
# this seems to be the sensor version?
#CURRENT_VERSION=$(defaults read /Applications/Falcon.app/Contents/Info.plist CFBundleShortVersionString)
SYSEXT_PLIST=/tmp/systemext.plist
NOTIFY_BOT=0

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

function health_check {
  # #license is being sent by env in filewave
  LICENSE_CHECK=$(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep agentID | awk '{ print $2 }')
  writeLog "License ID: $LICENSE_CHECK"

  if [ "$LICENSE_CHECK" == "" ] || [ "$LICENSE_CHECK" == "agentID: 00000000-0000-0000-0000-000000000000" ];
  then
    writeLog "License did not apply during setup!"
    writeLog "Re-running the licensing script..."
    /Applications/Falcon.app/Contents/Resources/falconctl license "$LICENSE" && writeLog "License key applied successfully"

    LICENSE_CHECK_AGAIN=$(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep agentID)
    writeLog "License ID after automated attempt: $LICENSE_CHECK_AGAIN"

    if [ "$LICENSE_CHECK_AGAIN" == "" ];
    then
      writeLog "License has not applied!  Crowd Strike is NOT active!"
      writeLog "Attempted to re-run licensing and issues persist!!"
      writeLog "\t >> Manual intervention required - machine probably just needs a restart."
      NOTIFY_BOT=1
    fi
  fi

  OPERATIONAL_CHECK=$(/Applications/Falcon.app/Contents/Resources/falconctl stats agent_info | grep operational)
  writeLog "$OPERATIONAL_CHECK"

  if [ ! "$(echo "$OPERATIONAL_CHECK" | awk '{ print $3 }')" == "true" ];
  then
    writeLog "Sensor is not operational!  Crowd Strike is NOT active!"

    if [ "$ACTIVE_USER" != "root" ] && [ "$ACTIVE_USER" != "loginwindow" ];
    then
      su -l "$ACTIVE_USER" -c '/usr/local/sbin/9942748/gui-prompt.sh issue' && writeLog "\n\t>> Warning popup seen by $ACTIVE_USER\n"
      writeLog "If this message persists, contact $ACTIVE_USER and check to ensure Falcon is allowed to filter traffic."
    elif [ "$ACTIVE_USER" == "root" ] || [ "$ACTIVE_USER" == "loginwindow" ];
    then
      writeLog "\t>> Nobody is currently signed in, reboot from Filewave."
    fi

    NOTIFY_BOT=1
  fi

  INSTALLGUARD_CHECK=$(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep installGuard)
  writeLog "$INSTALLGUARD_CHECK"

  if [ ! "$(echo "$INSTALLGUARD_CHECK" | awk '{ print $2 }')" == "Enabled" ];
  then
    writeLog "InstallGuard is not enabled!  Crowd Strike can be uninstalled by malware or by the user!"
  fi

  # make sure there's at least 1 system extension..
  SYSTEM_CHECK=$(systemextensionsctl list | grep -i strike)
  if [ "$SYSTEM_CHECK" == "" ];
  then
    writeLog "\t>>There does not appear to be ANY System Extension for Crowd Strike active!"
    NOTIFY_BOT=1
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

writeLog "== Crowd Strike Health Check for $DEVICE_NAME $USEDBY =="

# version check
if [ ! "$CURRENT_VERSION" = "$TARGET_VERSION" ] || [ ! "$CURRENT_VERSION" = "$FEATURE_VERSION" ] && [ -n "$CURRENT_VERSION" ];
then

  writeLog "CROWD STRIKE MISMATCH!\nExpected version: $TARGET_VERSION\nRunning version: $CURRENT_VERSION"

    # a bug i need to fix
elif [ -z "$CURRENT_VERSION" ];
then
  writeLog "\t >> Current version is BLANK; unprocessed var: $(/Applications/Falcon.app/Contents/Resources/falconctl stats | grep version)"
  writeLog "\t  See debug output"

  NOTIFY_BOT=1

else
  echo "Crowd Strike up to date: $CURRENT_VERSION"
fi


## system extension check ##
# if a ghost sysext causes issues, see: https://grahamrpugh.com/2021/04/06/delete-system-extension-command-line.html

# generate a plist so we can parse data more easily
# https://stackoverflow.com/a/63790334
EXTENSION_DB=/Library/SystemExtensions/db.plist
SYSEXT_XML_DB="$(plutil -convert xml1 -o - "$EXTENSION_DB")"

# pass the xml output to a tmp file for use later
echo "$SYSEXT_XML_DB" > "$SYSEXT_PLIST"

if [ "$ACTIVE_USER" != "root" ] && [ "$ACTIVE_USER" != "loginwindow" ] && [ "$CURRENT_VERSION" = "$TARGET_VERSION" ] || [ "$CURRENT_VERSION" = "$FEATURE_VERSION" ];
then

  writeLog "All system extension data gets assessed when there is at least 1 sysext matching an exception state."
  writeLog "\nSystem Extension Overview:"

  # there may be numerous extensions returning, increment them so we can pull data from all relevant
  TOTAL_MATCHING_EXT=$(systemextensionsctl list | grep "extension(s)" | awk '{ print $1 }')

  # loop x amount of times, decided by the numeric value of TOTAL_MATCHING_EXT to account for multiple matching extensions
  for ((i=1; i <= TOTAL_MATCHING_EXT; i++));
  do
    # do some extra processing; if * is present in 1 line & not in others, the field counts are thrown off
    # probably a better way to do this; but this works, for now
    EXT_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "print:extensions:$i:identifier" $SYSEXT_PLIST)
    EXT_ORIGIN=$(/usr/libexec/PlistBuddy -c "print:extensions:$i:originPath" $SYSEXT_PLIST)
    TEAM_ID=$(/usr/libexec/PlistBuddy -c "print:extensions:$i:teamID" $SYSEXT_PLIST)
    BUNDLE_PATH=$(/usr/libexec/PlistBuddy -c "print:extensions:$i:container:bundlePath" $SYSEXT_PLIST)
    EXT_STATUS=$(/usr/libexec/PlistBuddy -c "print:extensions:$i:state" $SYSEXT_PLIST | sed 's/_/ /g')
    EXT_VERSION=$(/usr/libexec/PlistBuddy -c "print:extensions:$i:bundleVersion:CFBundleShortVersionString" $SYSEXT_PLIST)

    # the last array (first extension in the plist) never loads.. for some reason the increment, when i=0
    # still starts at 1, but then blanks out on the last
    # that is why i=1 is active and this extra condition is added..
    # faking it because this is a sloppy approach at getting data, anyway
    # it returns stuff like this: Print: Entry, ":extensions:3:identifier", Does Not Exist
    # but when you can /tmp/systemext.plist it's totally there.. idk

    [ "$EXT_IDENTIFIER" == "" ] && EXT_IDENTIFIER="No data"
    [ "$EXT_ORIGIN" == "" ] && EXT_ORIGIN="No data"
    [ "$BUNDLE_PATH" == "" ] && BUNDLE_PATH="No data"
    [ "$TEAM_ID" == "" ] && TEAM_ID="No data"
    [ "$EXT_VERSION" == "" ] && EXT_VERSION="No data"
    [ "$EXT_STATUS" == "" ] && EXT_STATUS="No data"

    if [ "$TEAM_ID" == "No data" ];
    then
      EXT_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "print:extensions:0:identifier" $SYSEXT_PLIST)
      EXT_ORIGIN=$(/usr/libexec/PlistBuddy -c "print:extensions:0:originPath" $SYSEXT_PLIST)
      TEAM_ID=$(/usr/libexec/PlistBuddy -c "print:extensions:0:teamID" $SYSEXT_PLIST)
      BUNDLE_PATH=$(/usr/libexec/PlistBuddy -c "print:extensions:0:container:bundlePath" $SYSEXT_PLIST)
      EXT_STATUS=$(/usr/libexec/PlistBuddy -c "print:extensions:0:state" $SYSEXT_PLIST | sed 's/_/ /g')
      EXT_VERSION=$(/usr/libexec/PlistBuddy -c "print:extensions:0:bundleVersion:CFBundleShortVersionString" $SYSEXT_PLIST)
    fi
    # so bad...

    writeLog "\nExtension $i of $TOTAL_MATCHING_EXT:"
    writeLog "Identifier: $EXT_IDENTIFIER"
    writeLog "Origin Path: $EXT_ORIGIN"
    writeLog "App Bundle Path: $BUNDLE_PATH"
    writeLog "Team ID: $TEAM_ID"
    writeLog "Extension Version: $EXT_VERSION"
    writeLog "Extension Status: $EXT_STATUS"

    [ "$EXT_STATUS" = "activated enabled" ] && writeLog "Working order.\n" || writeLog "\t >> Needs attention!"

    # don't make anyone reboot for anything but crowd strike
    if [ ! "$EXT_STATUS" = "activated enabled" ] && [ ! "$EXT_STATUS" = "No data" ] && [ "$TEAM_ID" = "X9E956P446" ];
    then
      writeLog "GUI prompt sent to $ACTIVE_USER -- Crowd Strike will not function properly until they reboot, so the extension can install"
      writeLog "Running app version: $CURRENT_VERSION"

      NOTIFY_BOT=1
      REBOOT_PROMPT=1
    elif [ "$EXT_STATUS" = "No data" ];
    then
      writeLog "Some system extension info is outside of the nested loop being processed; need to fix - just ensure Crowd Strike is active:"
      writeLog "$(systemextensionsctl list)"
      writeLog "Running app version: $CURRENT_VERSION"

      NOTIFY_BOT=1
    fi
  done

  if [ ! "$ACTIVE_USER" = "root" ] && [ ! "$ACTIVE_USER" = "loginwindow" ] && [ "$REBOOT_PROMPT" == "1" ];
  then
    # bug: if the user lets the popup linger, the script never finishes.  some more exploration is needed to discard the wait
    su -l "$ACTIVE_USER" -c '/usr/local/sbin/9942748/gui-prompt.sh update' && writeLog "\n\t>> Restart popup seen by $ACTIVE_USER\n"
    writeLog "If this message persists, contact $ACTIVE_USER and request they reboot.  Otherwise, nothing further we need to do."
  elif [ "$ACTIVE_USER" = "root" ] || [ "$ACTIVE_USER" = "loginwindow" ] && [ "$REBOOT_PROMPT" == "1" ];
  then
    writeLog "\t >> Nobody is actively using this machine.  Trigger a reboot in Filewave, then check the health check logs after it comes back up."
  fi

  health_check

elif [ "$ACTIVE_USER" = "root" ] && [ "$ACTIVE_USER" = "loginwindow" ];
then
  echo "User not logged in; no use in processing system extension data - will check again on next verify."
  NOTIFY_BOT=0
elif [ "$CURRENT_VERSION" == "" ];
then
  writeLog "Crowd Strike is not running!  Will attempt to start.. and re-run the health check.."
  # attempt to capture stdout
  "$(/Applications/Falcon.app/Contents/Resources/falconctl load)" | {
    while IFS= read -r output
    do
      writeLog "$output"
    done
  }

  health_check
elif [ "$CURRENT_VERSION" != "$TARGET_VERSION" ] && [ "$CURRENT_VERSION" != "$FEATURE_VERSION" ];
then
  writeLog "Potential app installation failure; version mismatch - system extension check skipped!"
  writeLog "Current version: $CURRENT_VERSION"
  writeLog "Expected version: $TARGET_VERSION (target) or $FEATURE_VERSION (feature version)"
  NOTIFY_BOT=1
else
  writeLog "Not sure why this landed here.  Need to find out."
fi

if [ "$NOTIFY_BOT" -eq 1 ];
then
  echo "done"
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi

exit 0