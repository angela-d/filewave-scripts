#!/usr/local/bin/python3
import json
import subprocess as sp
from urllib import request
import urllib.error
import os
import datetime

# token is passed as an env from filewave
SNIPEIT = 'https://snipeit.example.com'
token = os.getenv('token')
serial = sp.getoutput('ioreg -l | grep IOPlatformSerialNumber').replace("\"","").split("=")[1].strip()
headers = {
    "Authorization": "Bearer " + token,
    "Accept": "application/json",
    "Content-Type": "application/json"
}
nameservers = sp.getoutput('scutil --dns | grep 172.16')

# apis
HW_API = '/api/v1/hardware/byserial/' + serial + '?deleted=false'

def get_location(serial):

    if len(serial) <10:
        print('Serial is too short: ' + serial)

    else:
        request = urllib.request.Request(SNIPEIT + HW_API, headers=headers)
        opener = urllib.request.build_opener()
        response = opener.open(request)

        api_result = json.loads(response.read())
        checkout = api_result['rows'][0]
 
        if checkout['location'] is not None:
            print(checkout['location']['name'])
        elif checkout['rtd_location'] is not None:
            print('Default: ' + checkout['rtd_location']['name'])
        else:
            print('no default location')


if __name__ == '__main__':

    # only change value when onsite
    if nameservers:
        get_location(serial)
    else:
        # not onsite
        exit(220)

    exit(0) 
