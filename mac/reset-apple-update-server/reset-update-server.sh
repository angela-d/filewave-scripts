#!/bin/bash
TMPLOG=/tmp/update-check.txt
# url to post to a chat bot
WEBHOOK_URL="https://your api url"

# reset any existing log
echo > "$TMPLOG"

# allow stdout and log capture at the same time
function writeLog {
  # allow escaping so newlines can be added, when needed
  echo -e "$1"
  echo -e "$1">>"$TMPLOG"
}

CURRENT_SERVER=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL)
writeLog "Current update server: $(defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL)"

defaults delete /Library/Preferences/com.apple.SoftwareUpdate CatalogURL && writeLog "Deleting update server..."

writeLog "Latest update server: $(defaults read /Library/Preferences/com.apple.SoftwareUpdate CatalogURL)"

curl -X POST -H 'Content-Type: application/json' -d '{"text": "'"$(cat $TMPLOG)"'"}' "$WEBHOOK_URL"

exit 0
