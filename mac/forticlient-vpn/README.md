# Forticlient VPN Deployment via Filewave
Once you have the [pkg installer](https://github.com/angela-d/brain-dump/blob/master/networking/fortigate/obtain-msi-vpn-only.md) you can deploy it to your users via Filewave.

## Profile Setup
The profile **must be** installed on the machine prior to anything else.  Create the profile, but don't deploy, yet.

1. Create a **Profile** and name it `Profile - Forticlient Setup`
2. Under **General** > Security: Controls when the profile can be removed: `With Authorization`
  - Set a password
  - Why: When testing, this won't be removed if you revoke the fileset, without
3. Under **VPN**
  - Name: `Forticlient` or `VPN_FC` (anything but VPN)
  - Connection Type: `Custom SSL`
  - Identifier: `com.fortinet.forticlient.macos.vpn`
  - Server: `localhost`
  - Provider Bundle Identifier: `com.fortinet.forticlient.macos.vpn`
  - Provider Designated Requirement: `FortiTray`
4. Under **System Extension Policy**
  - Allowed System Extensions > +
  - Allowed Team Identifiers: `AH4XFXJ7DK`
  - Allowed System Extensions: `com.fortinet.forticlient.macos.vpn.nwextension`
    - Note that if you use something other than the VPN Only version of Forticlient, you'll probably have to add more system extensions here

## Deploy via a Checkbox Setup
Custom fields in Filewave are *awesome* and make a complicated setup like this super easy to deploy.
1. In the Filewave admin client:
  - Assistants > Custom Fields > Edit Custom Fields > +
2. Create a new custom field:
  - Name: `Add Forticlient`
  - [x] Assigned to all devices
  - Data Type: `Boolean`
  - [x] Use a default value: `false`
  - Save

## Create a Smart Group to Manage Associations
In the Filewave Admin client, go to **Clients**
1. Click **New Smart Group**
2. We use a naming convention like **SG group name** for smart groups and keep them all contained to a single "Smart Group" folder.
  - Name: `SG Forticlient Initiator`
  - + Client OS Platform equals macOS
  - Inventory Query `...`
  - Custom Fields / Add Forticlient equals true
3. **Associate the Profile - Forticlient Setup fileset to SG Forticlient Initiator**
  - With this setup, this will allow the profile to install before anything else without having to mess with dependencies; which were not reliably ordered when testing.

## Create Another Smart Group to Manage PKG Deployment
1. Create a new smart group, I named mine `SG Forticlient Components - no devices plz` (so nobody else directly associates devices to it, hopefully!) :)
- Client OS Platform equals macOS
- Inventory Query `...`
  - Fileset / Fileset ID equals `Your PROFILE's Filewave ID`
  - Fileset deployment status / Last Status contains `Installed Successfully`
    - **Associate the PKG Fileset to `SG Forticlient Components - no devices plz`**

## Companion Script + Config
I set this up as a separate fileset.
This will include a GUI popup if the user has to reboot for the system extension to finish setup.  (Alternatively, clicking Allow in System Preferences does the job too, but complicates things with some users.)

1. Upload [config-check.sh](config-check.sh) as a verification script
2. Modify [vpn.plist](vpn.plist) and configure the connection details for your environment
3. Open the fileset and put **vpn.plist** in the following locations:
  ```text
  Library > Application Support > Fortinet > FortiClient > conf
  Users > All Users > Library > Application Support > Fortinet > FortiClient > conf
  ```
4. Upload an **icon.ics** file to display with your popup.  If you don't have a company logo icns, you can grab FOSS icons from [macosicons.com](https://macosicons.com):
  ```text
  /var/scripts/[your fileset id]/icon.icns
  ```
5. Add [systex-reboot-notification.sh](systex-reboot-notification.sh) to:
  ```text
  /usr/local/sbin/systex-reboot-notification.sh
  ```
6. Modify [systex-reboot-notification.sh](systex-reboot-notification.sh) verbiage to match your organization's preferences
  - Be sure to set the proper path to your icon.icns file, else the pop up will never show!
7. Add [uninstall-forticlient.sh](uninstall-forticlient.sh) as a **Pre-uninstallation** script
  - This will uninstall Forticlient completely, upon disassociation of the filetset
8. **Associate this fileset to SG Forticlient Components - no devices plz**

## Preparing the Upgrade/Installer Fileset
1. Upload the PKG into Filewave
2. Name the fileset (I named mine `PKG - FortiClient_7.0.5.0166`) - which is the latest, at the time of writing
3. Modify [pkg-preflight/uninstall-old-forticlient.sh](pkg-preflight/uninstall-old-forticlient.sh) and set the **TARGET_VERSION** variable to the version you're uploading
  - Modify the webhook variable to post results to your Slack or Google Hangouts bot
  - Save it
4. Upload *your modified* [pkg-preflightuninstall-old-forticlient.sh](pkg-preflight/uninstall-old-forticlient.sh) as a **Pre-flight Script**
  - Be sure to set the line endings to **Unix**
    - I had a low success rate with in-place upgrades; uninstalling old versions prior to PKG install has 100% success rate, though there's a chance you may interrupt active sessions depending on when you deploy.

## Deploying
Now that the set up is done, this can be deployed at the literal check of a box!
- Locate the user(s) you want to assign Forticlient to
- Right-click on their client
- Select **Add Forticlient**

### Credits
Huge thanks to participants in the [JAMF forum](https://community.jamf.com/t5/jamf-pro/deploying-forticlient-preventing-as-many-popups-as-possible-on/m-p/260342) for discussing the breadcrumbs needed to figure all of this out and **Henri K** on the macadmins slack for sharing the uninstall script
