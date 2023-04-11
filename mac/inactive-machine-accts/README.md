# Purge Inactive Local Accounts on Macs
Set a threshold for account age and purge inactive accounts.

## To Use
- Set as a verification script
- Modify the variables within the script:
  - THRESHOLD = how far to check for account activity
  - TESTING = set to `0` to purge accounts, 1 just to collect data
  - WEBHOOK_URL = if you want to post logs to a chatbot on Slack or Hangouts
  - LOCAL_ADMIN = specify your organization's local administrator acct, so it can be hidden from users menu
