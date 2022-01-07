#!/bin/bash

# modify target info below
TARGET_USER="user_to_change"
OLDPW="old_pw_here"
NEWPW="new_pw_here"
# nothing else to change!

# change the logon pw
sysadminctl -adminUser "$TARGET_USER" -adminPassword "$OLDPW" -resetPasswordFor "$TARGET_USER" -newPassword "$NEWPW"
echo "$TARGET_USER password has been changed"

exit 0
