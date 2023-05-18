# System Extensions

Full system database:

- /Library/SystemExtensions/db.plist
    - Human readable: `defaults read /Library/SystemExtensions/db`


Crowd Strike System Extension:

```json
identifier = "com.crowdstrike.falcon.Agent";
originPath = "/Applications/Falcon.app/Contents/Library/SystemExtensions/com.crowdstrike.falcon.Agent.systemextension";
references =             (
                    {
        appIdentifier = "com.crowdstrike.falcon.App";
        appRef = "file:///.file/id=6571367.33927585/";
        teamID = X9E956P446;
    }
);
```

This guy reverse-engineered the system extension setup and goes in-depth about it: [https://knight.sc/reverse%20engineering/2019/08/24/system-extension-internals.html](https://knight.sc/reverse%20engineering/2019/08/24/system-extension-internals.html)

## Where Are System Extensions Used?
- During install/upgrade of the PKG
    - The installer deals with it
- [Health checks verification script](health-check.sh)


### Relevant
- [Check Your System Extensions if You Have a Bootloop](https://old.reddit.com/r/macsysadmin/comments/ydupj8/check_your_system_extensions_if_you_have_a_boot/)