# Troubleshooting - CAMS and Global Search Syncing
## Prods 
- catalog-api (CAMS)
## Logs
- Swagger Link - https://<CPD_HOST>/v2/cams/explorer/#/Assets/retrieveAssets
## Status

## How to resync CAMS? [^1]
1. Get List of all catalog to find CATALOG_ID for default catalog
```
GET {CPD_URL}/v2/catalogs
```
2. Find SERVICE_ID_CREDENTIALS
```
SERVICE_ID_CREDENTIALS=$(oc get secret wdp-service-id -o yaml | grep service-id-credentials | awk '{print $2}' | base64 -d)
```
3. Delete everything with in the catalog <CATALOG_ID>
```
curl -XDELETE --header 'Content-Type:text/plain' --header 'Accept:application/json' --header 'Authorization: Basic <SERVICE_ID_CREDENTIALS>' -d 'entity.assets.catalog_id:<CATALOG_ID>'  https://<CPD_URL>/v3/search/delete_by_query?provider_type_ids=cams
```
Note that it needs to be run with Basic Auth + Service ID credentials

4)  Start resync job:
~~`oc create job --from=cronjob/wkc-search-reindexing-cronjob wkc-search-reindexing-cronjob-manual-01`~~
- Ran [cpd_gs_sync.sh](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/wkc/scripts/cpd_gs_sync.sh) (Orginal location - https://github.ibm.com/wdp-gov/wdp-catalog-service/wiki/How-to-run-GS-resync-for-specific-catalogs-in-CPD-environment) for particular catalog.
  Run chmod +x ./cpd_gs_sync.sh to make the above script executable.
  Run ./cpd_gs_sync.sh to execute job against specific catalogs. Follow prompts to customize it as required. NOTE: if empty list of containers is provided - ALL of the catalogs/project/spaces will be resync'd.
Script will ask for:
  - Project name where catalog resides, 
  - catalog_id


[^1]: SF Ticket TS010669978
