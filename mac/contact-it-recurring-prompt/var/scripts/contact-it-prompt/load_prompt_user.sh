#!/bin/zsh

current_user="$(stat -f%Su /dev/console)"

if [[ "$current_user" != ^"root"$ ]]
then
    su -l $current_user -c 'launchctl load /Library/LaunchAgents/com.github-angela-d.contactIT.plist'
fi

exit 0
