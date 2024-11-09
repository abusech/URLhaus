#!/usr/bin/python3
import sys
import requests
import json

def query_urlhaus(auth_key, url):
    # Construct the HTTP request
    data = {
        'url' : url
    }
    # Set the Authentication header
    headers = {
        "Auth-Key"      :   auth_key
    }
    response = requests.post('https://urlhaus-api.abuse.ch/v1/url/', data, headers=headers)
    # Parse the response from the API
    json_response = response.json()
    if json_response['query_status'] == 'ok':
        print(json.dumps(json_response, indent=4, sort_keys=False))
    elif json_response['query_status'] == 'no_results':
        print("No results")
    else:
        print(json_response['query_status'])

if len(sys.argv) > 2:
    query_urlhaus(sys.argv[1], sys.argv[2])
else:
    print("Looking up a URL on the URLhaus bulk API")
    print("Usage: python3 lookup_url.py <YOUR-AUTH-KEY> <URL>")
    print("Note: If you don't have an Auth-Key yet, you can obtain one at https://auth.abuse.ch/")
