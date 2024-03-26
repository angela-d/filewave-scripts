#!/usr/bin/env python3

from datetime import datetime
import json
import os
import smtplib
from email.mime.text import MIMEText
import time
import requests

# config for your environment
SNIPEIT_URL = 'https://snipeit.example.com/'
SNIPEIT_NAME = 'Your Snipe IT System'
BASE_URL = 'https://filewave.example.com/'
FW_API =  BASE_URL + 'api/'
SNIPEIT_TOKEN = os.getenv('ASSETS_TOKEN')
FW_API_TOKEN = os.getenv('FILEWAVE_TOKEN')
FW_QUERY = '225'
ZEN_API = 'yourorgexample'
ZEN_USER = os.getenv('ZENDESK_USER')
ZEN_TOKEN = os.getenv('ZENDESK_TOKEN')
ZEN_AUTHOR = '1234567890'
PORT = 25
SMTP_SERVER = 'mail.example.com'
SENDER = 'filewave@example.com'
RECEIVER = 'zendesk@example.com'
NOTIFY_PROB = 'admin@example.com'

def date_formatting(date_str):
    ''' some of these have ms & some don't, for some reason.. '''
    try:
        datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%S.%fZ")
        date_formatted = datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%S.%fZ").strftime('%b %d, %Y %I:%M %p')
    except ValueError:
        date_formatted = datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%SZ").strftime('%b %d, %Y %I:%M %p')

    return date_formatted

def send_email(details, subject, sender=SENDER, receiver=RECEIVER):
    ''' open a ticket '''
    format_message = MIMEText(details)
    format_message['Subject'] = subject
    format_message['From'] = sender
    format_message['To'] = receiver

    try:
        with smtplib.SMTP(SMTP_SERVER, PORT) as server:
            server.set_debuglevel(1)
            server.sendmail(receiver, receiver, format_message.as_string())
            server.quit()

        # tell the script to report if your message was sent or which errors need to be fixed
        print('Notification sent')
    except smtplib.SMTPServerDisconnected:
        print('Failed to connect to the server. Wrong user/password?')
    except smtplib.SMTPException as error_msg:
        print('Nothing has been sent: ' + str(error_msg))


def zendesk(subject, api_type, followup=''):
    ''' Make an API call to Zendesk & check for existing tickets '''
    # check the http status coming from zendesk
    conn = 'https://' + ZEN_API + '.zendesk.com/api/v2/' + api_type

    if api_type == 'search.json':
        # parameterize it, else requests wont encode and the spaces or : give false-positives
        params = {
            'query': 'type:ticket status:pending status:open status:new subject:'+ subject,
        }

    auth = (ZEN_USER, ZEN_TOKEN)
    zen_status = requests.get(conn, params=params, auth=auth, timeout=2)

    # check for http errors
    if zen_status.status_code != 200:
        print('Status:', zen_status.status_code, 'Check your settings and try again.')
        exit()
    else:
        print('Connected to API: ' + conn + ' with params: ' + str(params))

    if api_type == 'search.json':
        ticket = zen_status.json()
        total = ticket['count']

        if total >=1:
            ticket_number = ticket['results'][0]['id']
            ticket_status = ticket['results'][0]['status']

            print(str(total) + ' ticket matches, current ticket status: ' + ticket_status)
            print('Ticket #' + str(ticket_number) + ' exists; will update...')

            if ticket_status != 'solved' and ticket_status != 'closed':
                # send an update to the existing ticket
                conn = 'https://' + ZEN_API + '.zendesk.com/api/v2/tickets/' + str(ticket_number) + '.json'
                auth = (ZEN_USER, ZEN_TOKEN)
                headers = {"Accept": "application/json","Content-Type": "application/json"}
                params= {
                    "ticket": {
                        "comment": {
                            "author_id": ZEN_AUTHOR,
                            "body": followup, "public": True
                        },
                        "status": "open"
                    }
                }

                params = json.dumps(params)

                update_ticket = requests.put(conn, data=params, auth=auth, \
                    headers=headers, timeout=2)

                if update_ticket.status_code == 200:
                    status = 'Ticket #' + str(ticket_number) + ' has been updated'
                else:
                    #error_result = zen_status.json()
                    #print(error_result)
                    status = 'There was a problem updating the ticket; status code: ' + str(update_ticket.status_code)

                print(status)
            else:
                # something funky is going on here, notify me
                problem = 'This run wanted to update ticket #' + str(ticket_number) + ' which is ' + ticket_status + "\n" \
                    'API: ' + api_type + ' for ' + subject + "\n\n" \
                    'Original ticket content:' + "\n\n" + followup
                send_email(problem, 'Attempting to Update Closed Ticket', SENDER, NOTIFY_PROB)

        elif total == 0:
            # this sends a 0 result signal to the api lookup & a new ticket email is sent
            print('No matching tickets for ' + subject)
            return 0


def in_between(start, end):
    ''' limit sending of alerts for certain types of filewave queries '''
    now = datetime.now().strftime('%H:%M')

    if now >= start and now <= end:
        return True
    else:
        return False



def list_assets():

    ''' pull data from filewave '''
    api_request = FW_API + 'inv/api/v1/query_result/' + FW_QUERY

    try:
        fw_headers = {
            "Authorization": "Bearer " + FW_API_TOKEN,
            "Accept": "application/json",
            "Content-Type": "application/json"
        }

        get_data = requests.get(api_request, headers=fw_headers, timeout=2)
    except requests.exceptions.ReadTimeout:
        print('ERROR: Unable to connect to Filewave API!')
        error = 'Read timeout for API call'
        send_email(error, 'Filewave API Inaccessible', SENDER, NOTIFY_PROB)


    # check for http errors
    if get_data.status_code != 200:
        outage = \
            get_data.status_code + ':  Filewave server is undergoing maintenance, check back later.'
        print('Status:', get_data.status_code, outage)
    else:
        print('Connected to Filewave API!')

    query_result = json.loads(get_data.text)

    i = 1
    details = []
    missing_device = 0
    for device in query_result['values']:

        serial_lookup = 'api/v1/hardware/byserial/' + device[1]
        print(str(i) + ': Will search ' + SNIPEIT_NAME + ' for serial: ' + device[1] + '...')

        try:
            snipeit_headers = {
                "Authorization": "Bearer " + SNIPEIT_TOKEN,
                "Accept": "application/json",
                "Content-Type": "application/json"
            }
            snipeit_conn = SNIPEIT_URL + serial_lookup
            snipeit_data = requests.get(snipeit_conn, headers=snipeit_headers, timeout=2)
        except requests.exceptions.ReadTimeout:
            print('ERROR: Unable to connect to ' + SNIPEIT_NAME + ' API!')
            error = 'Read timeout for API call' + 'Status code: ' + str(snipeit_data.status_code)
            send_email(error, SNIPEIT_NAME + ' API Inaccessible', SENDER, NOTIFY_PROB)

        if snipeit_data.status_code != 200:
            outage = \
                str(snipeit_data.status_code) + ': ' + SNIPEIT_NAME + ' server is undergoing maintenance, check back later.'
            print('Status:', snipeit_data.status_code, outage)

            if snipeit_data.status_code == 429:
                print(SNIPEIT_NAME + ' API is refusing requests! Increase the limit in your env...')
        else:
            print(" " + 'Connected to ' + SNIPEIT_NAME + ' API: ' + serial_lookup)

            snipeit_result = json.loads(snipeit_data.text)

            # serial exists in filewave, but not snipeit
            if 'status' in snipeit_result and snipeit_result['status'] is not None and snipeit_result['status'] == 'error':
                details.append("\n" + 'Asset tag: ' + device[0] + "\n" + \
                    'Serial: ' + device[1] + "\n")

                if device[3] is not None:
                    details.append('Checked out to: ' + device[3]+ "\n")

                if device[4] is not None:
                    details.append('Checkout location: ' + device[4]+ "\n")

                if device[5] is not None:
                    details.append('Checkout return expected: ' + date_formatting(device[5]) + "\n")

                if device[6] is not None:
                    details.append('Last connected: ' + date_formatting(device[6]) + "\n")

                missing_device = 1
                print("\t\t" + '>> ERROR: ' + snipeit_result['messages'] + ' for serial ' + device[1])
            else:
                # matching serials
                snipeit = snipeit_result['rows'][0]

                if snipeit['serial'] == device[1]:
                    print('!!! ' + device[1] + ' matches ' + snipeit['serial'] + '!!! ')

                    # assigned user
                    if snipeit['assigned_to'] is not None:
                        assigned_to = snipeit['assigned_to']['name']
                    else:
                        assigned_to = 'ready to deploy'

                    # location
                    if snipeit['location'] is not None:
                        location = snipeit['location']['name']
                    elif snipeit['rtd_location'] is not None:
                        location = snipeit['rtd_location']['name']
                    else:
                        location = ''

                    # expected_checkin
                    if snipeit['expected_checkin'] is not None:
                        expected_checkin = snipeit['expected_checkin']
                    else:
                        expected_checkin = None

                    # update the custom field using the device id (column 2)
                    conn = FW_API + 'inv/api/v1/client/' + device[2]

                    params = {
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
                        }
                    }

                    params = json.dumps(params)

                    update_fields = requests.patch(conn, params, \
                        headers=fw_headers, timeout=2)

                    if update_fields.status_code == 200:
                        status = 'Device ' + snipeit['serial'] + ' has been updated' + "\n"
                    else:
                        missing_device = 1
                        details.append("\n" + 'Asset tag: ' + str(device[0]) + \
                            ' exists but could not be updated in Filewave; status: ' + \
                            str(update_fields.status_code) + "\n" + \
                            'Serial: ' + device[1] + "\n")

                        if device[3] is not None:
                            details.append('Checked out to: ' + device[3]+ "\n")

                        if device[4] is not None:
                            details.append('Checkout location: ' + device[4]+ "\n")

                        if device[5] is not None:
                            details.append('Checkout return expected: ' + date_formatting(device[5]) + "\n")

                        if device[6] is not None:
                            details.append('Last connected: ' + date_formatting(device[6]) + "\n")

                        status = "\t" + '>> There was a problem updating ' + snipeit['serial'] + '; device ID ' + device[2] + ' status code: ' + str(update_fields.status_code)

                    print(status)

                    i += 1

                    # sleep before processing further records to prevent exhausting the server(s)
                    time.sleep(2)

    # there were missing devices in this run
    if missing_device == 1:
        delist_details = ''.join(details)
        message_body = 'These devices are in Filewave, but not ' + SNIPEIT_NAME + "\n\n" + 'Search by the asset tag shown in Filewave; possible the serial is incorrect in ' + SNIPEIT_NAME + "\n\n" + delist_details
        send_email(message_body, 'Devices Not in ' + SNIPEIT_NAME)


    print('Total results: ' + str(i))




# if no args are passed, load this
if __name__ == '__main__':
    # /api/doc/

    list_assets()







