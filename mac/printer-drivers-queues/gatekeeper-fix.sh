#!/bin/bash
# parent path of the frameworks directory that gatekeeper is upset about
UNBLOCK_PATH="/Library/Printers/DriverPath/manufacturer/PDEs/ABC123456/"

for UNBLOCK in "$UNBLOCK_PATH"*.framework;
do
  xattr -d com.apple.quarantine "$UNBLOCK" && echo "$UNBLOCK whitelisted in Gatekeeper"
done

exit 0
