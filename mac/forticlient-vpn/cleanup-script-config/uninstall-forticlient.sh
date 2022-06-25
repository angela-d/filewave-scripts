#!/bin/bash

# components of the path removal section are from a mini script posted to macadmins slack by Henri K
# array of partial filename(s) to kill
TO_KILL=(
FortiClient
)

for target_service in "${TO_KILL[@]}";
do
	pkill -9 -f "$target_service" && echo "Killed $target_service"
done


"/Applications/FortiClientUninstaller.app/Contents/Library/LaunchServices/com.fortinet.forticlient.uninstall_helper" && echo "Ran uninstall helper" &&
rm -rf "/Library/Application Support/Fortinet/" && echo "Removed root Fortinet Application Support files" &&
rm -rf "/Library/Application Support/FortiClient/" && echo "Removed root FortiClient Application Support files" &&
rm -rf /private/var/root/Library/Preferences/com.fortinet.FortiClientAgent.plist && echo "Removed plist data"

# remove any residual stuff from user dirs, too
USERS=$(dscl . list /Users | grep -v '^_' | grep -v daemon | grep -v nobody | grep -v root)

while IFS= read -r USER; do
	rm -rf "/Users/$USER/Library/Application Support/Fortinet/" && echo "Removed users/$USER Fortinet Application Support files"
	rm -rf "/Users/$USER/Library/Application Support/FortiClient/" && echo "Removed users/$USER FortiClient Application Support files"
done <<< "$USERS"

exit 0
