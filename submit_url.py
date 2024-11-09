#!/usr/bin/env python3
import json
import requests

url = 'https://urlhaus.abuse.ch/api/'
# If you don't have an Auth-Key, you can log into
# https://auth.abuse.ch/ and generate one
auth_key = YOUR_AUTH_KEY

# You can add multiple URLs at once
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
r = requests.post(url, json=jsonData, timeout=15, headers=headers)
print(r.content)
