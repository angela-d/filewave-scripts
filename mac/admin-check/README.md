# Admin Check via Filewave
If you're in an environment where users should be on standard accounts instead of admin, set a verification script to routinely check and notify when admin is on.

## Scenario
- The active user's account is compared against admin group users
- Unless your local administrator is actively signed in while the script executes, you won't be notified about it
  - The script does not care about offline admins on machines, only active users
