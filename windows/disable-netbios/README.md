# Disable NetBIOS via Powershell & Filewave

## Pre-flight Checks

- Open Wireshare and search for netbios traffic: `port 137` > Capture
- In command-prompt, `nbtstat -c` to check for NBT's cache

## Setup

1. Create an empty fileset with requirements for Windows only
2. Click the fileset and go to the Scripts tab
3. Copy the script to the verification phase

## Verifying Netbios is Disabled

On a target machine:

Control Panel > Network and Internet: View network status and tasks > Change adapter settings > right-click on an adapter > Properties > under the Networking tab: select Internet Protocol Version 4 (TCP/IPv4) > Properties > Advanced > under WINS tab > NetBIOS Setting should ALREADY BE disabled (after this script as run)

View script output > shows logs of what interface gets switched to disabled

### Worth Noting

Until the machine reboots, the listening ports will still remain active:
```batch
netstat -nao  | find /i ":137"
netstat -nao  | find /i ":5353"
netstat -nao  | find /i ":5355"
```

`:5353` may return localhost or services like Tailscale; but if `:137` or `:5355` have output post-update, something didn't disable like expected.
