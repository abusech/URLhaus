#!/usr/bin/python3
import sys
import requests
import json

def query_urlhaus(url):
    # Construct the HTTP request
    data = {'url' : url}
    response = requests.post('https://urlhaus-api.abuse.ch/v1/url/', data)
    # Parse the response from the API
    json_response = response.json()
    if json_response['query_status'] == 'ok':
        print(json.dumps(json_response, indent=4, sort_keys=False))
    elif json_response['query_status'] == 'no_results':
        print("No results")
    else:
        print("Something went wrong")

if len(sys.argv) > 1:
    query_urlhaus(sys.argv[1])
else:
    print("Looking up a URL on the URLhaus bulk API")
    print("Usage: python3 lookup_url.py <URL>")
