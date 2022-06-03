#!/bin/bash

/usr/sbin/lpadmin -p Printer_1_name -o printer-is-shared=false
/usr/sbin/lpadmin -p Printer_2_name -o printer-is-shared=false

cupsctl --no-share-printers
exit 0
