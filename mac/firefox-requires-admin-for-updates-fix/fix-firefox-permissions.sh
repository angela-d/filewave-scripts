#!/bin/bash

current_user="$(stat -f%Su /dev/console)"

chown -R "$current_user":staff /Applications/Firefox.app && echo "Permissions for /Applications/Firefox.app successfully changed"
ls -l /Applications/Firefox.app

exit 0
