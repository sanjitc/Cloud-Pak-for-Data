# Troubleshooting - WKC Reporting 
## Prods 

```
$ oc get pods | grep "wkc-bi-data-service"
```

## Logs

## Status
Find WKC Report status response 
```
curl -i -k -H "content-type: application/json" -H "Authorization: bearer $Bearer_TOKEN" -X GET "https://$HOSTNAME/v3/reporting/heartbeat"
curl -i -k -H "content-type: application/json" -H "Authorization: bearer $Bearer_TOKEN" -X GET "https://$HOSTNAME/v3/reporting/999/register"
curl -i -k -H "content-type: application/json" -H "Authorization: bearer $Bearer_TOKEN" -X GET "https://$HOSTNAME/v3/reporting/bistatus?tenant_id=999&table_name=all"
```

## Compare assets between IKC/WKC and WKC Reporting Datamart
Assets at IKC side. From CAMS API:
```
curl -i -k -H "content-type: application/json" -H "Authorization: Bearer $TOKEN" -X GET "https://$HOSTNAME/v2/asset_types/asset/search?catalog_id=<CATALOG ID>" -d "{\"query\":\"*:* AND NOT (asset.asset_category:SYSTEM)\",\"limit\":\"10\"}"
```
Response will have `total_rows` which is the total number of assets in the catalog.

Assets at WKC Reporting datamart. From PostgreSQL:
```
select container_id, count(*) 
from wkc_reorting.container_assets 
where container_id  = '<CATALOG ID>'
group by container_id
```

## Force sync
To trigger re-sync of all the assets under a project or catalog, you can use this curls command.
```
curl -i -k -H "content-type: application/json" -H "Authorization: Bearer $TOKEN" -X POST "https://$HOSTNAME/v3/reporting/999/start?soft_restart=true&failed_only=true&include_passed_zone_ids=\"<coma separated list of catalig_id/project_id>\""
```
Example:
```
curl -i -k -H "content-type: application/json" -H "Authorization: Bearer $TOKEN" -X POST "https://$HOSTNAME/v3/reporting/999/start?soft_restart=true&failed_only=true&include_passed_zone_ids=\"aaaaa090-64bc-4c26-9ad7-ae615db92cab,xxxxx090-64bc-4c26-9ad7-ae615db92cab\""
```

## WKC reporting synchronization appearing stuck in reporing UI
1. Set the status of catalogs & projects back to ACTIVE/SUCCESS:
```
oc exec -it c-db2oltp-wkc-db2u-0 bash
db2 connect to wfdb

db2 "delete from BIOPSDB_icp4data.rpt_error_cache"

db2 "update BIOPSDB_icp4data.rpt_load_zone_queue set status = 1000"
db2 "update BIOPSDB_icp4data.rpt_load_feature_status set status = 1000"
```
2. Restarted wkc_bi_service pods.

