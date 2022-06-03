# Disable Printer Sharing
If a managed device has printer sharing enabled, make it stop with a simple shell script.

## Pre-requisite
Know your printer names
```bash
lpstat -v
```

`cupsctl --no-share-printers` may be a catchall approach, but I did the more detailed route by hitting each printer by name in my script.
