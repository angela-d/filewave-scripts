# Duplicate Chrome Check
Whenever CVE's are released for Chrome, I like to use Filewave's reporting tools to see what machines are out of date and see why they aren't self-updating (as the dispatched profiles require)

There was a few users who kept reporting ancient versions of Chrome despite running the latest version whenever it was checked.

## Cause
Some users weren't privy to the fact IT ships browsers automatically, via MDM
- They downloaded their own copy and left it in their Downloads, Desktop and sometimes "save for later" type directories
- Some users were inexplicably running their browser from within a mounted dmg, which of course prevents it from self-updating

## Fix
Locate them and remotely delete them
- I like to get a chat notification when this occurs, to see if there's any repeat offenders
- Send a dock profile to **pin the browsers to the dock** to prevent future recurrences
