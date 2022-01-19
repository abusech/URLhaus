#!/usr/bin/python3
import sys
import requests
import json
import re

def query_urlhaus(file_hash):
    # Validate file hash provided
    if re.search(r"^[A-Za-z0-9]{32}$", file_hash):
        hash_algo = 'md5_hash'
    elif re.search(r"^[A-Za-z0-9]{64}$", file_hash):
        hash_algo = 'sha256_hash'
    else:
        print("Invalid file hash provided")
        return
    # Construct the HTTP request
    data = {hash_algo : file_hash}
    response = requests.post('https://urlhaus-api.abuse.ch/v1/payload/', data)
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
    print("Looking up a file hash (MD5 or SHA256) on the URLhaus bulk API")
    print("Usage: python3 lookup_filehash.py <md5 or sha256 hash>")
