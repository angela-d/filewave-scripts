# Using Let's Encrypt SSL Certificates with Filewave
Automatically generate and renew SSL certs for Filewave dashboard, DEP and client trust.

The basics of this implementation was given by Filewave's support (it's not documented, at the time of writing, what was necessary to get the clients to trust the cert) and was customized to suit my environment, in addition to [Review My Note's](https://www.reviewmynotes.com/2022/10/filewave-and-lets-encrypt.html) example.

For those curious, this is what pushes the certificate to DEP profiles for client trust:
```bash
/usr/local/filewave/python/bin/python /usr/local/filewave/django/manage.pyc update_dep_profile_certs
```

## Initial Setup
Since certbot has been deprecated in favor of snaps, which I am not a fan of, I opted for using [acme.sh](https://github.com/acmesh-official/acme.sh)

1. Setup acme.sh on your Filewave server
2. Make sure port 80 is open to the web at your firewall
3. Ensure Filewave listens on port 80:
  ```bash
  nano /usr/local/filewave/apache/conf/httpd.conf
  ```

  - append:

      ```bash
      Listen 80
      ```
    at the bottom of the **Listen** block

    - append

    ```bash
    IncludeOptional conf/letsencryp[t].conf
    ```
    near the other includes at the top of **httpd.conf**

4. Put [letsencrypt.conf](letsencrypt.conf) in `/usr/local/filewave/apache/conf/`

5. Issue your first cert:
  ```bash
  acme.sh --issue -d filewave.example.com -w /usr/local/filewave/apache/htdocs --debug 2
  ```

6. Add the following to `crontab -e` - swap `/your/path/to/` with your server's path to your acme.sh install:
  ```bash
  02 10 * * 01 /your/path/to/acme.sh --issue -d filewave.example.com -w /usr/local/filewave/apache/htdocs --debug 2
  ```


## Troubleshooting
Renewing a cert in April 2023, I found that the issuer wasn't being included in the fullchain when renewing via Let's Encrypt and was thereforce deemed 'untrustworthy' by an integral app.  Even attempting a clean install of acme.sh yielded the same results.

Using ZeroSSL got the fullchain so the certificate was recognized properly.

### Missing CA Fix (switching issuers from Let's Encrypt to ZeroSSL)
For good measure:
```bash
acme.sh --upgrade
```

```bash
acme.sh --install -m newzerossluser@example.com
```

```bash
acme.sh --register-account -m newzerossluser@example.com --server zerossl
```

Confirm your config changes:
```bash
cat ~/.acme.sh/account.conf
```

### Fixing the Certificate
New install:
```bash
acme.sh --install -d filewave.example.com -w /usr/local/filewave/apache/htdocs --debug 2
```

Renewing:
```bash
acme.sh --renew -d filewave.example.com -w /usr/local/filewave/apache/htdocs --debug 2
```

**Worth noting:** If you get that generic `Verify error:` message, be sure your perimiter firewall isn't blocking the request.

My first ZeroSSL issuance came from a Comodo IP, based in the UK - so if you are outside of the UK and geo-filter, at least add the UK to port 80 allowance.