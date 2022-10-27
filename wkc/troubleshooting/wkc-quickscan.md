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
Find WKC Report status response 
```

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
 a -l			    List recent analysis requests
 a -d <arg>		Show detailed status of a specific request by its id
 a -d <numbe>
```
* Review pod logs form `odf-fast-analyzer`
