# check if the item exists, first
$anyDesk = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\AnyDesk MSI.lnk"

if (!(Test-Path $anyDesk)) {
  Write-Host "Anydesk startup entry has already been removed"
} else { 
  Remove-Item -Path $anyDesk
  Write-Host "Anydesk startup entry has been removed"
}

exit 0
