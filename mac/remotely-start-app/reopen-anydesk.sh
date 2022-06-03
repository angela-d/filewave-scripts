#!/bin/bash
ACTIVE_USER=$(stat -f%Su /dev/console)

killall AnyDesk && echo "Killed Anydesk"
ps aux | grep AnyDesk

su - "$ACTIVE_USER" -c "open -a /Applications/AnyDesk.app/Contents/MacOS/AnyDesk" && echo "Opened AnyDesk as $ACTIVE_USER"

echo "Is it running?"
ps aux | grep AnyDesk

exit 0
