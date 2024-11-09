#!/usr/bin/python3
import sys
import urllib3
import json
import os

# Prepare HTTPSConnectionPool
pool = urllib3.HTTPSConnectionPool('urlhaus-api.abuse.ch', port=443, maxsize=10)

def query_urlhaus(auth_key, url):
    # Construct the HTTP request
    data = {
        'url' : url
    }
    # Set the Authentication header
    headers = {
        "Auth-Key"      :   auth_key
    }
    response = pool.request_encode_body("POST", "/v1/url/", fields=data, encode_multipart=False, headers=headers)
    # Parse the response from the API
    response = response.data.decode("utf-8", "ignore")
    # Convert response to JSON
    json_response = json.loads(response)
    if json_response['query_status'] == 'ok':
        print(f"[+] FOUND:     {url}")
    elif json_response['query_status'] == 'no_results':
        print(f"[-] Not found: {url}")
    else:
        print(f"[-] Error:     {url}: {json_response['query_status']}")

if len(sys.argv) > 2:
    if not os.path.isfile(sys.argv[2]):
        print("Input file not found")
        quit()
    file = open(sys.argv[2], 'r')
    urls = file.readlines()
    for url in urls:
        query_urlhaus(sys.argv[1], url.strip())
else:
    print("Takes a local file name as argument and looks up each URL sequentialy on the URLhaus bulk API")
    print("Input file must contain one URL per line")
    print("Usage: python3 lookup_url_bulk.py <input file>")
    print("Note: If you don't have an Auth-Key yet, you can obtain one at https://auth.abuse.ch/")
