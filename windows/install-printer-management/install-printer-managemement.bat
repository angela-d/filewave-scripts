@echo off

dism /Online /Remove-Capability /CapabilityName:Print.Management.Console~~~~0.0.1.0
timeout /t 60

dism /Online /add-Capability /CapabilityName:Print.Management.Console~~~~0.0.1.0

exit 0
