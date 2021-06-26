@echo off

net localgroup "Administrators" "tempadmin" /DELETE
net user "tempadmin" /DELETE

exit 0
