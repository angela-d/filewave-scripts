 # Snipe IT Integration for Filewave Reports
 Pull details from your Snipe IT installation for use in Filewave reports.

 **Pre-requisites**
 - A [Snipe IT](https://snipeitapp.com/) installation
    - [API token](https://snipe-it.readme.io/reference/generating-api-tokens) from your Snipe IT install
 - Python deployment ('builtin' Python is a stub); we deploy the [latest stable](https://www.python.org/downloads/macos/) release
    - Once you got the PKG deployment setup, you'll want to setup the following activation script:
    ```bash
    #!/bin/bash

    # without this, https connections get SSL: CERTIFICATE_VERIFY_FAILED
    /Applications/Python\ 3.11/Install\ Certificates.command

    exit 0
    ```

    - Adjust version (3.11) accordingly
    - Without running `Certificates.command`, anytime your scripts make an https request you'll get SSL: CERTIFICATE_VERIFY_FAILED errors


That's it!  

Now all you have to do:
- Configure your [custom fields](https://kb.filewave.com/books/evaluation-guide/page/custom-fields) and attach one of the enclosed scripts

- Once your custom field is setup, click the **Execution Environment** tab and go to **environment variables**, click + and create:
    - Variable: `token`
    - Value: your Snipe IT API token (no Bearer; just the random keystrokes key)

You'll find your custom field values under Clients > Device Details tab, along with script status (Success or Failed)

- Modify the following in your chosen script:
    - `SNIPEIT` - Specify your Snipe IT URL
    - `nameservers` - I only want this script updating when users are onsite, set your full or partial onsite DNS server

- Unfortunately, custom field scripts have no logging, so for debugging I make a "debug" fileset with the script contents and appropriate arguments that mimic the environment of the custom field script and deploy it to a testing machine.
    - When problems arise, navigate to `/var/scripts/[fileset id]` and execute your script in the terminal to see how it behaves in it's natural environment if the logging available from within Filewave is insufficient