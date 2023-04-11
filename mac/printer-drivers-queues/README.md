# Printer Queue / Drivers & PPD Deployment for MacOS via Filewave MDM
Scripts to handle deployment of printer stuff to Macs managed under Filewave MDM.

Before letting these scripts loose in your environment, you'll want to:
- Install printers to a testing Mac, the manual way
  - Run `lpinfo -m` to get the paths of the driver/PPDs:
    - ```text
      Library/Printers/PPDs/Contents/Resources/MANUFACTURERMODELA.gz MANUFACTURER MODEL PS
      ```
    - `MANUFACTURERMODELA` is argument `$5` / `"PPDdriverPath"` (example value) on [install-printer-queues.sh](install-printer-queues.sh)
    - If you have multiple printers by the same manufacturer, it's very likely a lot of your queues may use the same driver/PPDs
- In Finder, navigate to the folder: `/Library/Printers` (system library, not the user library path)
  - Reference the software/driver path in [install-printer-queues.sh](install-printer-queues.sh) as well; for example, a Konica Minolta Color printer could be something like:
  - Folder: `/Library/Printers/KONICAMINOLTA`
  - Subfolder: `/Library/Printers/KONICAMINOLTA/C759` -- `C759` would be argument `$6` / `"C456"` (example value) in [install-printer-queues.sh](install-printer-queues.sh)
- Add your queue paths to [uninstall-queues.sh](uninstall-queues.sh), too
- Set your print server URL in place of **example.com** (and any special characteristics) in:
  ```bash
  lpadmin -p "$1" -D "$2" -L "$3" -E -v lpd://print.example.com/"$4" -P "$PPD_PATH" -o printer-is-shared=false -o KMDuplex=Single && echo "$4 added"```
- A Fiery EFI queue would look something like:
```bash
/Library/Printers/PPDs/Contents/Resources/en.lproj/Fiery CS IC-313 PS2.2
```
and is referenced as a conditional value in [install-printer-queues.sh](install-printer-queues.sh) -- be sure to adjust to your model.

If you have anything like EFI Fiery, you may also run into security prompts for bundled frameworks with Gatekeeper (after the fileset is deployed and active on the client machine):

> "hcxpcore.framework" can't be opened because it was not downloaded from the App Store.
>
> Your security preferences allow installation of only apps from the App Store.

- You can bypass Gatekeeper by utilizing [gatekeeper-fix.sh](gatekeeper-fix.sh)

## Compatible MacOS Versions
Used on machines from on Catalina to Ventura, so far.

## Set Up
> There may be a better way to build a fileset, at the time of writing I am a newb to Filewave but well-versed in programming, so this is my approach.
>
> Feel free to modify these steps if you're a Filewave expert.

- Create a New **Fileset Group**
- Create an empty **Desktop Fileset** inside the new fileset group
- Put all of your PKGs inside this group
- Select your newly-created fileset > click on **Scripts** tab inside this fileset and import the scripts as the following (click Import > select file > drag to re-order):
  - **Verification Scripts**
    - [install-printer-queues.sh](install-printer-queues.sh)
  - **Pre-Uninstallation Scripts**
    - [uninstall-queues.sh](install-printer-queues.sh)
- Click OK > double-click the fileset to get the scripts tree; un-tick "Hide unused folders" and *make sure* the file structure is that of MacOS:
  - If you're working on this fileset on a Windows machine, it'll import to a Windows folder structure -- you can expand the carats to see the darkened fileset ID (usually a long number string and colored in black whereas others are light grey - drag the black fileset directory to the MacOS path)
- Scripts/files should be in the corresponding directories in Filewave's tree view:
  - `/var/scripts/install-printer-queues.sh`
  - `/var/scripts/uninstall-queues.sh`

  **Note:** If you need the Gatekeeper fix, attach that in the Scripts tab and add it as a verification and/or activation script.

## Troubleshooting
If a user is experiencing missing printers or incomplete printing capabilities, (in Filewave) locate the client > right-click:
- Client info
- In the **Fileset status** tab, locate the name of your **Fileset Group** that houses your drivers and queue scripts > select it
- In the right pane, you should see the installation script; if the script didn't execute and errored out, you'll see that here; otherwise, right-click on it > **View script output** for logs related to the printer stuff

### Credits
Borrowed code snipped for detecting paused printers from [Jacob Salmela](https://jacobsalmela.com/2015/04/10/bash-script-fix-paused-printers-in-os-x/)

### Caveat
[CUPS has deprecated printer drivers](https://www.cups.org/blog/2018-06-06-demystifying-cups-development.html).
