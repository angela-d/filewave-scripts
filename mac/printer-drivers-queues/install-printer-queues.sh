#!/bin/bash

# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/printer-driver-setup.txt
# active user
ACTIVE_USER=$(stat -f%Su /dev/console)
# hostname will make it easy to locate the user in filewave
DEVICE_NAME=$(scutil --get LocalHostName)
# add your webhook chat bot here for notifications
WEBHOOK_URL=""

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

function removePrinter() {

  if [ ! "$(lpstat -p | awk '{print $2}' | grep -i "$1")" == "" ]
  then
      lpadmin -x "$1"
      writeLog "Removed queue $1"
      writeLog "On next verify, the queue should be added"
  else
      writeLog "$1 queue does not exist; NOT removing"
  fi

}
# 1st arg of printList function is the queue name
function printList() {

  # pre-fill the driver ppd path, so we can make sure the drivers even exist; throw an error if not
  if [ ! "$5" == "Fiery" ];
  then
    PPD_PATH="/Library/Printers/PPDs/Contents/Resources/$5.gz"
    SOFTWARE_PATH="/Library/Printers/MANUFACTURER/$6"
  else
    PPD_PATH="/Library/Printers/PPDs/Contents/Resources/en.lproj/Fiery CS IC-313 PS2.2"
    SOFTWARE_PATH="/Library/Printers/FieryDriver/efi"
  fi

  # check for existing queues and do not add if they already exist
  if [ ! -e /etc/cups/ppd/"$1".ppd ];
  then

    ## queue does not yet exist ##

    # standard path ppd all share the same location, short of the gz data; make sure it exists
    if [ -e "$PPD_PATH" ];
    then
      lpadmin -p "$1" -D "$2" -L "$3" -E -v lpd://print.example.com/"$4" -P "$PPD_PATH" -o printer-is-shared=false -o KMDuplex=Single && echo "$4 added"
  	else
  	  writeLog "ERROR: $1 PPD does not exist: $PPD_PATH"
      ERROR="1"

      # since an error was triggered, purge all ppds to force a "reset" like is done from sys pref > reset printing
      # except don't touch non-org printers
      rm -rf /etc/cups/ppd/"$4".ppd && echo "Reset /etc/cups/ppd/$4 -- Hit Verify on client in Filewave to reinstall queue"
    fi

    # give a detailed error & fail at the first sign of trouble
    [[ "$ERROR" == "1" ]] && echo ">> Reinstall the affected driver PKG (not the queue script or group!) inside the fileset to put the drivers where they belong" && exit 0

  ## queue exists, so make sure the ppd does, too ##

  elif [ -e /etc/cups/ppd/"$1".ppd ] && [ -e "$PPD_PATH" ] && [ -e "$SOFTWARE_PATH" ];
  then

      # check for the queue
      if [ ! "$(lpstat -p | awk '{print $2}' | grep "$1")" == "" ];
      then
        writeLog "$1 exists and should be visible in print list"
      else
        writeLog "$1 does NOT exist.. will try to add"
        lpadmin -p "$1" -D "$2" -L "$3" -E -v lpd://print.example.com/"$4" -P "$PPD_PATH" -o printer-is-shared=false -o KMDuplex=Single && writeLog "$4 queue added"

        # check for it again
        if [ ! "$(lpstat -p | awk '{print $2}' | grep "$1")" == "" ];
        then
          writeLog "$1 should now be in the print menu"
        else
          writeLog " >> Something weird happened and $1 was not added.."
          CASE_TEST="$(lpstat -p | awk '{print $2}' | grep -i "$1")"
          writeLog "It may exist with a different case; testing: $CASE_TEST"
          [[ ! "$CASE_TEST" == "" ]] && writeLog " >> Since a case mismatch exists, removing it.." && removePrinter "$1"
          ERROR=1
        fi
      fi

    else
      ERROR=1
      writeLog "ERROR: $1 queue exists, but PPD and/or software does not:"
      writeLog "  PPD: $PPD_PATH"
      writeLog"  SOFTWARE: $SOFTWARE_PATH"
    fi

  }

  # make sure none are paused
  # https://jacobsalmela.com/2015/04/10/bash-script-fix-paused-printers-in-os-x/
  if [ -n "$(lpstat -p | awk '/disabled/ {print $2}')" ];
  then
    writeLog "Disabled printer detected!"
    for PRINTER in $(lpstat -p | awk '/disabled/ {print $2}')
    do
      # Cancel all jobs (and their files)--disable/enable CUPS as well
      /usr/bin/cancel -ax && wruteLog "Canceled queued print jobs, for good measure"
      /usr/sbin/cupsdisable "$PRINTER" && writeLog "Disabled CUPS"
      /usr/sbin/cupsenable "$PRINTER" && writeLog "Re-enabled CUPS"
      writeLog "\n >> FIXED $PRINTER"
    done
  fi
# trigger printer list deployment function, printList()
# each space suffixed indicates a +1 of the argument passed into the printList() function

# PPD FILE    = $1 (ls /etc/cups/ppd on a mac w/ these already installed; extracted in deploy())
# DESCRIPTION = $2
# LOCATION    = $3
# URL         = $4
# DRIVERPATH  = $5 (lpinfo -m on a mac w/ these already installed)
# SOFTWARE    = $6 prerequisite software that accompanies the ppd, usually in /Library/Printers
printList "2nd_Floor_BW" "2nd Floor B&W" "By the coffee machine" "2ndFloorBW" "PPDdriverPath" "123"
printList "4th_Floor_Color" "4th Floor Color" "Between the washrooms" "4thFloorColor" "KONICAMINOLTAC658" "C456"
# give the user permission to manage printers (staff/faculty, only)
ACTIVE_USER="$(stat -f%Su /dev/console)"
if [ ! "$(dscacheutil -q group -a name _lpadmin | grep "$ACTIVE_USER")" ];
then
  dseditgroup -o edit -a "$ACTIVE_USER" _lpadmin && echo "$ACTIVE_USER added to _lpadmin group"
  /usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
  /usr/sbin/security authorizationdb write system.preferences allow
  /usr/sbin/security authorizationdb write system.preferences.printing allow
  /usr/sbin/security authorizationdb write system.print.operator allow
else
  echo "$ACTIVE_USER" already has _lpadmin perms
fi

if [ "$ERROR" == "1" ] && [ "$ACTIVE_USER" != "root" ];
then
  writeLog "Hostname: $DEVICE_NAME\nActive User: $ACTIVE_USER"
  echo "Posting to chat room.."
  curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"
fi
exit 0
