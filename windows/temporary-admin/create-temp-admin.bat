@echo off

net user "tempadmin" "tempadmin" /add

net localgroup "Administrators" "tempadmin" /add

WMIC USERACCOUNT WHERE "Name='tempadmin'" SET PasswordExpires=FALSE

exit 0
