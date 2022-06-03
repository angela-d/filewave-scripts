# Uninstall Apps Previously Installed via MSI
Such apps do not remove automatically when disassociated in Filewave.

## Pre-requisite
Get the upgrade ID of the app(s) you want to remove.

Sending a simple powershell script to the target machine (or running the PS command on a test machine) will suffice.

```powershell
Get-WMIObject Win32_Product | Sort-Object -Property Name |Format-Table IdentifyingNumber, Name, LocalPackage -AutoSize
```

- Grab the {.....} from the **IdentifyingNumber** column
