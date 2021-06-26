#!/bin/bash

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

    ## queue does not exist ##

    # standard path ppd all share the same location, short of the gz data; make sure it exists
    if [ -e "$PPD_PATH" ];
    then
      lpadmin -p "$1" -D "$2" -L "$3" -E -v lpd://print.example.com/"$4" -P "$PPD_PATH" -o printer-is-shared=false -o KMDuplex=Single && echo "$4 added"
  	else
  	  echo "ERROR: $1 PPD does not exist: $PPD_PATH"
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
    echo "$1 queue dependencies exist"
  else
    echo "ERROR: $1 queue exists, but PPD and/or software does not:"
    echo "  PPD: $PPD_PATH"
    echo "  SOFTWARE: $SOFTWARE_PATH"
  fi

}

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

exit 0
