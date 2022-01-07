# Reset Local Admin Password Remotely
This script had to be used in a pinch:
- User let their battery die and found their clock reset to 1/1/1969 over Christmas
  - Since the clock is off, the machine no longer communicates with Filewave, so deploying a [temporary admin](../temporary-admin) is not possible
  - For some reason, Apple decided clocks are only modifiable by admins

## Scenario
Users do not have administrator privileges.

User was working remotely and didn't want to bring their machine in for reasons, our only option to rectify was to reveal the original local admin password to the user.

- User was able to successfully reset their clock

## New Problem
User now has the local admin password and effectively, unlimited access to their machine.

## Fix
Now that the user's clock is fixed, the machine is communicating with Filewave again, so we used this script to change the local admin password to revoke administrator privileges.

## Caveats:
- Transmits the local admin password in plaintext (though running as root, as all Filewave scripts do, so risk is minute.)

  - Revoke the script association after completion and modify the fileset so your preferred administrator privileges aren't stored openly in Filewave.

Assess your risk vs reward scenario before using this approach.
