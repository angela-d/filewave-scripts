# Firefox Requires Admin for Updates Fix
When deploying Firefox PKGs via MDM, it installs to `/Applications/Firefox.app` with the following permissions:
```text
drwxr-xr-x   3 root        wheel       96 Dec  8 10:11 Firefox.app
```
which is what triggers the admin requirement for updates.

## The Fix
Change ownership of `/Applications/Firefox.app` recursively.

Use the [post-install](fix-firefox-permissions.sh) script to fix the permissions after initial installation.

In Filewave:
- Select the Firefox ESR PKG
- Click the **Scripts** button in the top menu
- Under **Postflight Scripts** attach the post-install script
- Ensure your MDM preferences are set to ignore/leave behind, otherwise once it detects a change (such as an update), it will revert back to what was originally deployed

Now, everytime there's a new update, the user will simply have to restart their browser session for the browser to update itself.

After the post-install script:
```text
drwxr-xr-x   3 angelatest  staff       96 Dec 23 10:54 Firefox.app
```
