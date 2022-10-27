# Troubleshooting - WKC QuickScan 
## Prods 

```
iis-services 
odf-fast-analyzer
```

## Logs
Application logs
* All logs from pod `iis-services*:/opt/IBM/InformationServer/wlp/usr/servers/iis/logs/`
* All logs from pod `is-en-conductor-0:/opt/IBM/InformationServer/ASBNode/logs` (some versions have it linked to /logs)


## Status
WKC Healthcheck
```
### This script runs all health check endpoints
### Assumptions as follows
# - Works with sequoia (3.5.x) and ironwood (4.0.x) releases
# - Access to cp4d host via shell
# - python is installed (for pretty printing)
# - User has credentials to login cp4d env, admin credentials recommended
# to execute just run the script and follow the prompts

if [ "$#" -eq 3 ]
then
  HOSTNAME=$1
  USER=$2
  PASSWORD=$3
else
  echo "Usage ./run_omrs_healthcheck.sh <hostname> <usename> <password>"
  echo "example ./run_omrs_healthcheck.sh zen-cpd-zen.apps.xen-cea-bvt-oc-46-pwx-8.os.fyre.ibm.com admin password"
  exit 1
fi

echo "Getting WKC token"
WKC_TOKEN=$(curl "https://$HOSTNAME/v1/preauth/validateAuth" -s -H "username:$USER" -H "password:$PASSWORD" -k -X GET | awk -F 'accessToken":"' '{print $2}' | awk -F '"' '{print $1}' | xargs)

echo "Getting IGC token"
IGC_TOKEN=$(curl -X POST -k https://$HOSTNAME/ibm/iis/api/auth_token/v1/tokens -d "{\"username\":\"$USER\", \"password\": \"$PASSWORD\"}" -s | awk -F 'access_token": "' '{print $2}' | awk -F '"' '{print $1}' |
xargs)

echo "running OMAG health check"
curl -X GET -k "https://$HOSTNAME/ibm/iis/api/igc-omrs/servers/igc_omrs/healthcheck" -s -H "Authorization: Bearer $IGC_TOKEN" | python -mjson.tool

echo "\n\nrunning BG health check"
curl -X GET -k "https://$HOSTNAME/v3/glossary_terms/admin/open-metadata/healthcheck" -s -H "Authorization: Bearer $WKC_TOKEN" -H 'Accept: application/json' -H 'Content-Type: application/json' | python -mjson.tool

echo "\n\nrunning CAMS health check"
curl -X GET -k "https://$HOSTNAME/v2/catalogs/default/healthcheck" -s -H "Authorization: Bearer $WKC_TOKEN" -H 'Accept: application/json' -H 'Content-Type: application/json' | python -mjson.tool
```

## Common Problems
### Fail to browse assets from connection
* Review pod logs from `iis-services`
* Search error messages seen in popup when browsing assets. Typically, this symptom is due to connection failure for authentication, remote data source refusing connection, or connection ID has no permission to retrieve metadata information from remote source. 

### Discovery error
* Review pod logs form `iis-services` and `odf-fast-analyzer`
* Search QuickScan job ID, and look for error around the locations, e.g. JDBC error, SQL error, exception and stack trace.

### QuickScan job failure
* Run `is-en-conductor-0:/opt/IBM/InformationServer/ASBNode/bin/ODFAdmin.sh` script from inside the pod. Common script options are:
```
 a -l	  List recent analysis requests
 a -d <arg>		Show detailed status of a specific request by its id
 a -d <numbe>
```
* Review pod logs form `odf-fast-analyzer`
