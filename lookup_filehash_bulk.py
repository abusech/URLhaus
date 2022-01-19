#!/usr/bin/python3
import sys
import urllib3
import json
import os
import re

# Prepare HTTPSConnectionPool
pool = urllib3.HTTPSConnectionPool('urlhaus-api.abuse.ch', port=443, maxsize=10)

def query_urlhaus(file_hash):
    # Validate file hash provided
    if re.search(r"^[A-Za-z0-9]{32}$", file_hash):
        hash_algo = 'md5_hash'
    elif re.search(r"^[A-Za-z0-9]{64}$", file_hash):
        hash_algo = 'sha256_hash'
    else:
        print(f"[-] Illegal hash: {file_hash}")
        return
    # Construct the HTTP request
    data = {hash_algo : file_hash}
    response = pool.request_encode_body("POST", "/v1/payload/", fields=data, encode_multipart=False)
    # Parse the response from the API
    response = response.data.decode("utf-8", "ignore")
    # Convert response to JSON
    json_response = json.loads(response)
    if json_response['query_status'] == 'ok':
        signature = json_response['signature']
        print(f"[+] FOUND:     {file_hash} {signature}")
    elif json_response['query_status'] == 'no_results':
        print(f"[-] Not found: {file_hash}")
    else:
        print(f"[-] Error:     {file_hash}")

if len(sys.argv) > 1:
    if not os.path.isfile(sys.argv[1]):
        print("Input file not found")
        quit()
    file = open(sys.argv[1], 'r')
    hashes = file.readlines()
    for hash in hashes:
        query_urlhaus(hash.strip())
else:
    print("Takes a local file name as argument and looks up each file hash (MD5 or SHA256 hash) sequentialy on the URLhaus bulk API")
    print("Input file must contain one MD5 or SHA256 hash per line")
    print("Usage: python3 lookup_filehash_bulk.py <input file>")
