# URLhaus
URLhaus is an open platform for sharing malware distribution sites. This repository provides some sample python3 scripts on how to interact with the URLhaus bulk API.

## Report a malware URL
This script lets you report a malware URL to URLhaus:

```
python3 submit_url.py <YOUR-AUTH-KEY> http://evildomain1.tld/bad
```

Note: If you don't have an Auth-Key yet, you can obtain one at https://auth.abuse.ch/

## Lookup a URL
This script calls the URLhaus [URL information endpoint](https://urlhaus-api.abuse.ch/#urlinfo), looking up a particular URL in the URLhaus database:

```
python3 lookup_url.py http://77.73.133.113/lego/mine.exe
```

If you want to bulk lookups multiple URLs at the same time, you can save them to a file (one URL per line) and use the bulk lookup script, e.g.:

```
python3 lookup_url_bulk.py url-list.txt
```

## Lookup a file hash (MD5 or SHA256)
This script calls the URLhaus [payload information endpoint](https://urlhaus-api.abuse.ch/#payloadinfo), looking up a particular hash (MD5 or SHA256 hash) in the URLhaus database:

```
python3 lookup_filehash.py d72ba95c67364911636a82f711732eb67e235bb31b17928e832228e847d25890
```

If you want to bulk lookups multiple hashes at the same time, you can save them to a file (one MD5 or SHA256 hash per line) and use the bulk lookup script, e.g.:

```
python3 lookup_filehash_bulk.py hash-list.txt
```

## ClamAV rules for detecting known bad URLs
URLhaus publishes a ClamAV signature file, detecting malware distribution sites in e.g. emails. By running [clamav.sh](https://github.com/abusech/URLhaus/blob/master/clamav.sh) every minute as cronjob, you can make sure that the URLhaus signature DB stays up to date.

## API documentation
The documentation for the URLhaus bulk API os available here:

https://urlhaus-api.abuse.ch/

## Feed of collected payloads
URLhaus provides an hourly and daily batch of payload collected from malware distribution sites. The feeds are available here:

Hourly feed: https://datalake.abuse.ch/urlhaus/hourly/

Daily feed: https://datalake.abuse.ch/urlhaus/daily/
