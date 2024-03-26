 
# How To Update Filewave Devices Custom Fields from Snipe IT
Use APIs from Filewave and Snipe IT to attach more fine-grained data to your Filewave reports while utilizing Zendesk alerts or tickets on exceptions like missing device records.

**Important note:** This script should not be used until **you** customized it.  The variable keys hardcoded 
into the script are unlikely 1:1 matches for your environment, only use it as a guide.
This approach is not the prettiest, but is one of my first scripts with Filewave's API and the primary goal was to just get the data between both systems.



### Requirements
- A server with Python 3.9.2+
    - Moderate understanding of Python; you'll need to customize the code to fit your environment
- Firewall rules between both Snipe IT & Filewave open to port 443 + whatever server your Python script is on 
(which doesn't need to reside on either Filewave *or* Snipe IT's servers)


## First Steps - Acquainting Yourself with Filewave & Snipe IT's API

**Filewave**

***

1. If you don't have one already, setup a report/query within your Filewave dashboard targeting the devices you'd like to use Snipe IT's data on
2. Pop into the Swagger viewer for your Filewave setup
    - Your url would be `https://yourfilewaveurl/api/doc`
    - Sign in
    - To the right, authenticate with your API user's username & password
        - Set one up if you don't have an API user & token yet: Assistants > Manage Administrators > Application Tokens

3. Locate `[ GET ] /inv/api/v1/query` - Running this will show you all available queries exposed to your API.  
Make note of the `"id":` number for the query you want to use, which will be used in the script
    - If you don't already have an existing query, make one that would target the devices in Snipe IT

4. Locate which custom fields you want to use; 

**Snipe IT**

***

1. If you don't already have an API token, go into your settings area (upper right-corner, click your name > Manage API Keys)
2. Create a new token (which will be much larger character-wise than Filewave's)
3. Assuming your devices are under the hardware category with populated serials, you should be good to go!

**Server Running Python**

***

[Envio CLI](https://github.com/envio-cli/envio) can make storing your API keys and tokens a bit cleaner. (optional)

Wherever you decide to house your Python script, you should make environment variables that hold your tokens.  
Somewhere like `~/.profile` or `~/.bash_profile` would suffice -- note that wherever you put them should be executable. 
`chmod +x ~/.profile` (assuming the user you're logged in as will be the one running the script)

Within your `~/.profile` file, add your tokens:
```bash
export ZENDESK_USER="myzendeskadmin@example.com/token"
export ZENDESK_TOKEN="Abcdefghjzendeskapitokenhere"
export FILEWAVE_TOKEN="ijklmnofilewavetokenhere"
export ASSETS_TOKEN="pqrstextremelylogsnipeittokenhere"
```
- Save
- Invoke the latest updates in your current shell, for testing:
```bash
. ~/.profile
```

In the directory where you'll be leaving & running the script:

1. Make a logs directory: `mkdir logs`
2. Make an empty log file: `mkdir filewave-snipeit-update.log`


**Customizing the Script**

***

Open the script and modify the following: variables to suit:
```bash
SNIPEIT_URL = 'https://snipeit.example.com/'
SNIPEIT_NAME = 'Your Snipe IT System'
BASE_URL = 'https://filewave.example.com/'
FW_QUERY = '225'
ZEN_API = 'yourorgexample'
ZEN_AUTHOR = '1234567890'
PORT = 25
SMTP_SERVER = 'mail.example.com'
SENDER = 'filewave@example.com'
RECEIVER = 'zendesk@example.com'
NOTIFY_PROB = 'admin@example.com'
```

- `FW_QUERY` is from step #3 under **Filewave**

1. Browse the script and you'll see `device[3]` and `device[4]` - these are what must require complete customization on your part.
    - The numeric key corresponds to the column position in your report.  [0] indicates it's the first column showing under your **Fields** tab of your Filewave report.

2. Your Filewave custom field can really be anything, but my script example references **Checked Out To**, **Checkout Location** and **Checkout Expected Return**
    - If you don't already have one you want to use: Assistants > Custom Fields > Edit Custom Fields Definitions
    - Make note of the **Internal Name** which will be used in your script

3. In the script, adjust all references of `device[#]` to match your own query and any corresponding verbiage

4. Finally, adjust the custom fields reference to match what was referenced in step #2 a moment ago:
```python
"CustomFields": {
    "checked_out_to": {
        "exitCode": 0,
        "status": 0,
        "updateTime": datetime.now().isoformat(),
        "value": assigned_to
    },
    "checkout_location": {
        "exitCode": 0,
        "status": 0,
        "updateTime": datetime.now().isoformat(),
        "value": location
    },
    "expected_checkin": {
        "exitCode": 0,
        "status": 0,
        "updateTime": datetime.now().isoformat(),
        "value": expected_checkin
    }
```
- The only components you need to change are `checked_out_to`, `checkout_location`, `expected_checkin` or remove/add as many options as needed.

### Testing
It is recommended to first ensure you have a **backup** of your entire Filewave server before proceeding.. then test this with a single serial before letting it loose on your entire environment.

Once you have a serial you want to test with, locate: `for device in query_result['values']:` and indent that entire block x1

Positioned above that indent, do an if statement against your testing serial, like so (**assuming** column 1 is the device serial in your Filewave query):

```python
if device[1] == 'serialnumberhere':
```

That should make it so your loop only ever has one match, minimizing the risk of complete destruction of your Filewave instance.  (Which would only occur by your code being horrifically sloppier than my own - there's no destructive functions in this setup, just updates - but best to be safe than sorry!)