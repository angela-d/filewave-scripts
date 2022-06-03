#!/bin/bash
#adduser script, must be run as root
# 2013 Jul 12 -benm@filewave.com - Updated to write to client log and a line 28 syntax error
# 2013 JUL 24 -benm@filewave.com - added quotes in line 25 to handle spaces in realnames
# 2014 Feb 21 - christiang@filewave.com - Update to allow creation of non-admin users
# 2021 Jun 02 - Angela - rework to delete admin user upon disassociation of fileset
exec 1>>/var/log/fwcld.log
exec 2>>/var/log/fwcld.log

username=$(stat -f%Su /dev/console)

dscl . -delete /Groups/admin GroupMembership "$username" && echo "Removed $username from admin group"
