#!/usr/bin/python3
import sys
import urllib3
import json
import os

# Prepare HTTPSConnectionPool
pool = urllib3.HTTPSConnectionPool('urlhaus-api.abuse.ch', port=443, maxsize=10)

def query_urlhaus(url):
    # Construct the HTTP request
    data = {'url' : url}
    response = pool.request_encode_body("POST", "/v1/url/", fields=data, encode_multipart=False)
    # Parse the response from the API
    response = response.data.decode("utf-8", "ignore")
    # Convert response to JSON
    json_response = json.loads(response)
    if json_response['query_status'] == 'ok':
        print(f"[+] FOUND:     {url}")
    elif json_response['query_status'] == 'no_results':
        print(f"[-] Not found: {url}")
    else:
        print(f"[-] Error:     {url}")

if len(sys.argv) > 1:
    if not os.path.isfile(sys.argv[1]):
        print("Input file not found")
        quit()
    file = open(sys.argv[1], 'r')
    urls = file.readlines()
    for url in urls:
        query_urlhaus(url.strip())
else:
    print("Takes a local file name as argument and looks up each URL sequentialy on the URLhaus bulk API")
    print("Input file must contain one URL per line")
    print("Usage: python3 lookup_url_bulk.py <input file>")
