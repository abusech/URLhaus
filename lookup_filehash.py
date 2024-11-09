#!/usr/bin/python3
import sys
import requests
import json
import re

def query_urlhaus(auth_key, file_hash):
    # Validate file hash provided
    if re.search(r"^[A-Za-z0-9]{32}$", file_hash):
        hash_algo = 'md5_hash'
    elif re.search(r"^[A-Za-z0-9]{64}$", file_hash):
        hash_algo = 'sha256_hash'
    else:
        print("Invalid file hash provided")
        return
    # Construct the HTTP request
    data = {
        hash_algo : file_hash
    }
    # Set the Authentication header
    headers = {
        "Auth-Key"      :   auth_key
    }
    response = requests.post('https://urlhaus-api.abuse.ch/v1/payload/', data)
    # Parse the response from the API
    json_response = response.json()
    if json_response['query_status'] == 'ok':
        print(json.dumps(json_response, indent=4, sort_keys=False))
    elif json_response['query_status'] == 'no_results':
        print("No results")
    else:
        print("Something went wrong")

if len(sys.argv) > 2:
    query_urlhaus(sys.argv[1], sys.argv[2])
else:
    print("Looking up a file hash (MD5 or SHA256) on the URLhaus bulk API")
    print("Usage: python3 lookup_filehash.py <YOUR-AUTH-KEY> <md5 or sha256 hash>")
    print("Note: If you don't have an Auth-Key yet, you can obtain one at https://auth.abuse.ch/")
