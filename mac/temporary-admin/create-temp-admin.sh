#!/bin/bash
#adduser script, must be run as root
# 2013 Jul 12 -benm@filewave.com - Updated to write to client log and a line 28 syntax error
# 2013 JUL 24 -benm@filewave.com - added quotes in line 25 to handle spaces in realnames
# 2014 Feb 21 - christiang@filewave.com - Update to allow creation of non-admin users
# 2021 Jun 02 - Angela - Modify for use as a temp admin acct
exec 1>>/var/log/fwcld.log
exec 2>>/var/log/fwcld.log

#replace variables with desired values
#unix shortname (no spaces)
username=tempadmin
#Long/display name
realname="tempadmin"
password=tempadmin
uniqueid="2000"

#Checks to see if user exists if so exit script else continue with creation
result="$(dscl . -list /Users | grep $username)"
if [ "$result" = "$username" ]; then
	echo "$username already exists; exiting."
	exit 0
else

#1 is make into admin, 0 is make as standard user
islocaladmin="1"

echo "Creating local admin Account"
echo "USERNAME $realname"

#### don't edit below this line #####
#add the user, homedirectory, shell, etc.
dscl . -create /Users/$username
dscl . -create /Users/$username UserShell /bin/bash
dscl . -create /Users/$username RealName "$realname"
dscl . -create /Users/$username UniqueID $uniqueid
dscl . -create /Users/$username PrimaryGroupID 20
dscl . -create /Users/$username NFSHomeDirectory /Users/$username

#setting the users password
dscl . -passwd /Users/$username $password

#if the user is supposed to be an admin, add it to the admin group
if [ "$islocaladmin" == "1" ] ; then
	dscl . -append /Groups/admin GroupMembership $username


fi

# Below line will hide the newly created user from the login window and System Preferences -> Users & Groups. Remove the comment if you would like to add this.
	dscl . create /Users/$username IsHidden 1
fi

# Have script delete itself

rm -- "$0"

exit 0
