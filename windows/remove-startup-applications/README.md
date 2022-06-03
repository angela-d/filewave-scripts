# Remove Startup Applications in Windows
Some apps create startup entries when mass deployed.

This will remove those entries.

## Locations for Startup Items
These entries can be in several different locations.


**All users**
- C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp
- Registry:
  - HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run
  -HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce



**Current user**
- C:\Users\<User>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\StartUp
  - You would need a custom variable for `<User>` in this context
- Registry:
  - HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce

**Other potential locations**
- Documents and Settings\All Users\Start Menu\Programs\Startup
- Documents and Settings\username\Start Menu\Programs\Startup
- Registry:
  - HKEY_CURRENT_USER\ProgID\Software\Microsoft\Windows\CurrentVersion\Run


### Worth Noting
[Disable Teams from Auto-starting](https://www.undocumented-features.com/2019/08/12/disabling-teams-autostart/)
 > Teams is updated out-of-band from Office ProPlus updates, if your users aren’t launching and using it periodically, it will become out of date and may cause problems
