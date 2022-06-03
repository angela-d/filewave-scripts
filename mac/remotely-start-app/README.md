# Remotely Start a Service / Open an App Remotely
I was working on an offsite Mac and nobody was around to reopen Anydesk after a botched upgrade.

To fix that, I sent the necessary shell commands to the remote machine to open Anydesk (which was previously set as Unattended, but the service wasn't running + the app wasn't open after rolling back the upgrade)

## Pre-requisites
- The target machine must already be on
- Target user must be logged in
- Previously set 'unattended' config for Anydesk
