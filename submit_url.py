#!/usr/bin/env python3
import sys
import json
import requests

def report_urlhaus(auth_key, url):
    jsonData = {
      'anonymous' : '0',
      'submission' : [
        {
          'url'     : 'http://evildomain1.tld/bad',
          'threat'  : 'malware_download',
          'tags'    : [
            'Emotet',
            'doc'
          ]
        }
      ]
    }

    headers = {
        "Content-Type"  :   "application/json",
        "Auth-Key"      :   auth_key
    }
    r = requests.post('https://urlhaus.abuse.ch/api/', json=jsonData, timeout=15, headers=headers)
    print(r.content)

if len(sys.argv) > 2:
    report_urlhaus(sys.argv[1], sys.argv[2])
else:
    print("Report a malware URL to URLhaus")
    print("Usage: python3 submit_url.py <YOUR-AUTH-KEY> <URL>")
    print("Note: If you don't have an Auth-Key yet, you can obtain one at https://auth.abuse.ch/")
