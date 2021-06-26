#!/bin/bash

# remove by queue name only, that way if the user has any personal printers installed, we won't break those
function removePrinter() {

  lpadmin -x "$1"
  echo "Removed $1 queue"

}

removePrinter "2nd_Floor_BW"
removePrinter "4th_Floor_Color"

# reset cups via cli - pt1/start
echo "Stopping CUPS..."
launchctl stop org.cups.cupsd
rm /etc/cups/cupsd.conf
cp /etc/cups/cupsd.conf.default /etc/cups/cupsd.conf

# remove all manufacturer stuff
rm -rf /Library/Printers/MANUFACTURER/ && echo "Removed Manufacturer drivers..."
# remove fiery
rm -rf /Library/Printers/efi/ && echo "Removed Fiery drivers..."
rm -rf /Library/Printers/PPDs/Contents/Resources/MANUFACTURER*.gz && echo "Removed Manufacturer PPDs..."
# remove fiery ppd
rm -rf /Library/Printers/PPDs/Contents/Resources/*.lproj/Fiery* && echo "Removed Fiery PPDs..."
sed -i '' '/KONICA/d' /Library/Printers/InstalledPrinters.plist && echo "Updated /Library/Printers/InstalledPrinters.plist"
rm /Library/Preferences/org.cups.printers.plist && echo "Remove preferences list"

# reset cups via cli - p2/finish
echo "Restarting CUPS..."
sudo rm /etc/cups/printers.conf
sudo launchctl start org.cups.cupsd
echo "Done."

exit 0
