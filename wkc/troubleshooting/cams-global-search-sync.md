# Troubleshooting - CAMS and Global Search Syncing
## Prods 

## Logs

## Status

## How to resync CAMS?
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
4. Run reindex job
````
oc create job --from=cronjob/wkc-search-reindexing-cronjob wkc-search-reindexing-cronjob-manual-01
```
