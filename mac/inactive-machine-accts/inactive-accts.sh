#!/bin/bash
THRESHOLD=120
TESTING=1
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# generate a tmp file of output, to easily attach it to the curl webhook for testing mode
TMPLOG=/tmp/obsolete-accts.txt
# url to post to a chat bot
WEBHOOK_URL=""
LOCAL_ADMIN="local_admin"

# reset any existing log
[ "$TESTING" -eq 1 ] && echo > "$TMPLOG" || echo "In live mode, not purging log"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

function removeUser {
  # checks to see if user exists before deleting
  result="$(dscl . -list /Users | grep "$1")"
  if [ "$result" = "$1" ];
  then

  	dscl . -delete /Users/"$1" && writeLog "Deleted $1 account"

    # if dscl didn't delete the home folder, nuke that, too
    [ -e "/Users/$1" ] && rm -rf "/Users/$1" && writeLog "Deleted /Users/$1 folder" || writeLog "/Users/$1 already removed"

  fi
}

writeLog "== Obsolete User Check Test Mode ==\nAccounts will not be deleted, only checked!"
writeLog "Hostname: $DEVICE_NAME\n"

# check if admin acct is already hidden
HIDDEN_CHECK="$(dscl . -list /Users IsHidden 1 | grep "$LOCAL_ADMIN" | awk '{ print $2 }')"

if [ "$HIDDEN_CHECK" != "" ] && [ "$HIDDEN_CHECK" -eq 1 ];
then
  writeLog "$LOCAL_ADMIN is already hidden"
else
  # hide local admin acct; 1st arg user screen, 2nd arg /Users dir
  dscl . create /Users/"$LOCAL_ADMIN" IsHidden 1 && chflags hidden /Users/"$LOCAL_ADMIN" && writeLog "$LOCAL_ADMIN acct is now hidden"
fi

# collect usernames, but exclude system accts + local admin
USERS=$(dscl . list /Users | grep -v '^_' | grep -v daemon | grep -v nobody | grep -v root | grep -v ''$LOCAL_ADMIN$'')
NOW=$(date)

# loop through the result from the users var
for USER in $USERS
do
  LAST_ACTIVITY=$(date -r "/Users/$USER")
  echo -e "\n$USER - $LAST_ACTIVITY"
  DAYS_SINCE=$((($(date -jf "%a %b  %d %H:%M:%S %Z %Y" "$NOW" +%s) - $(date -jf "%a %b  %d %H:%M:%S %Z %Y" "$LAST_ACTIVITY" +%s))/86400))
  echo "$DAYS_SINCE days since last sign in"

  if [ "$TESTING" -eq 0 ];
  then

    # live code / delete accts
    [ "$DAYS_SINCE" -gt "$THRESHOLD" ] && removeUser "$USER" && writeLog "$USER's account deleted" || writeLog "$USER's account within $THRESHOLD days of activity and was left alone"

  elif [ "$TESTING" -eq 1 ];
  then

    [ "$DAYS_SINCE" -gt "$THRESHOLD" ] && writeLog "$USER's account would be purged" || writeLog "$USER's account would be left alone; last activity within $THRESHOLD days"

  fi

done

writeLog "To delete accounts, set TESTING var to 1 and re-run this script."

# only send log content if we're in testing mode
if [ "$TESTING" -eq 1 ];
then
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi
