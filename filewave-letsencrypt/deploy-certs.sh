#!/bin/bash

# generate a tmp file of output, to easily attach it to the curl webhook
TMPLOG=/tmp/cert-renew.txt
# if you post to a chat bot like slack or google hangouts, put that here
WEBHOOK_URL=""
# where your acme.sh install is
ACME_INSTALL="/root/acme.sh"
# your filewave domain
FILEWAVE_URL="filewave.example.com"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

writeLog "== Filewave SSL Cert Renewal =="

# remove previous backups
if [ -e "$ACME_INSTALL/backup_certs/server.crt" ];
then
  rm "$ACME_INSTALL"/backup_certs/server.crt && writeLog "Removed last renewals backup of server.crt"
  rm "$ACME_INSTALL"/backup_certs/server.key && writeLog "Removed last renewals backup of server.key"
fi

# make new backups
mv /usr/local/filewave/certs/server.crt "$ACME_INSTALL"/backup_certs/server.crt && writeLog "Backed up current server.crt"
mv /usr/local/filewave/certs/server.key "$ACME_INSTALL"/backup_certs/server.key && writeLog "Backed up current server.key"


cp "$ACME_INSTALL"/"$FILEWAVE_URL"_ecc/fullchain.cer /usr/local/filewave/certs/server.crt && writeLog "Installed new server.crt"
cp "$ACME_INSTALL"/"$FILEWAVE_URL"_ecc/"$FILEWAVE_URL".key /usr/local/filewave/certs/server.key && writeLog "Installed new server.key"

chown apache:apache /usr/local/filewave/certs/server.* && writeLog "chown to apache on both"
chmod 664 /usr/local/filewave/certs/server.* && writeLog "chmod 664 on both"

/usr/local/filewave/apache/bin/apachectl graceful && writeLog "Gracefully restarted Apache service"

# pipe a pseudo argument to accept the cli prompt so the script can run without user intervention
yes | /usr/local/filewave/python/bin/python /usr/local/filewave/django/manage.pyc update_dep_profile_certs && writeLog "Updated DEP certs"

writeLog "If there are any issues, make sure all of the certs are where they should be!"

echo "Posting to chat room.."
curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"

exit 0
