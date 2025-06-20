# 0 = uses NetBIOS setting from the DHCP server
# 1 = enables NetBIOS
# 2 = disabled

# specify the registry tree to read
$regPath = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
$regSettings = Get-ChildItem -Path $regPath

# echo a path reminder
Write-Output "`n`nTree: $regPath`n`n"

# loop through and display all interfaces
foreach ($key in $regSettings) {
    $values = Get-ItemProperty -Path $key.PSPath -Name "NetbiosOptions"
    $keyName = $($key.PSChildName)
    $numericValue = $($values.NetbiosOptions)

    Write-Output "Key: $keyName is set to: $numericValue"
    
    if ($numericValue -ne 2) {
        $modifyPath = "$regPath\$keyName"
        Write-Output "---"
        Write-Output "$keyName will be modified to disable..."
        Write-Output "---`n"
        Set-ItemProperty -Path $modifyPath -Name NetbiosOptions -Value "2"
    } else {
        Write-Output "---"
        Write-Output "$keyName is already set to disabled, nothing to change"
        Write-Output "---`n"
    }
} 
