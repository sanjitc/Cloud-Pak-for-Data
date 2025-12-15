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

## RMQ queues and consumer details
```
oc exec -ti rabbitmq-ha-0 -- rabbitmqctl list_queues -p / name messages messages_ready messages_unacknowledged | grep bidata
oc exec -ti rabbitmq-ha-0 -- rabbitmqctl list_consumers | grep bidata
```
## Find ongoing sync process status of a catalog or project

- Check `bidata_sync_status` table to monitor the current processed count.
```
select count(*) from wkc_reporting.bidata_sync_status where zone_id = '<catalog_id/project_id>'
```
- Check `bidata_sync_errors` table for skipped assets.
```
select * from wkc_reporting.bidata_sync_errors where zone_id = '<catalog_id/project_id>'
```
## Find rebalancing status
1) Capture WKC report status using above APIs
2) Cpature reporing feature status from the Db2 database.
```
oc exec -it c-db2oltp-wkc-db2u-0 bash
db2 connect to wfdb
db2 "select distinct feature from BIOPSDB_icp4data.rpt_load_feature_status order by feature" > features.log
db2 "select a.service, a.zone_id, b.status, c.feature, c.status as fstatus from BIOPSDB_icp4data.RPT_DATA_TENANTS_ZONES a INNER JOIN BIOPSDB_icp4data.RPT_LOAD_ZONE_QUEUE b ON b.ZONE_ID = a.zone_id JOIN BIOPSDB_icp4data.RPT_LOAD_FEATURE_STATUS c ON c.zone_id = b.zone_id AND c.zone_id = a.zone_id order by a.service, a.zone_id, c.feature " > feat_status.log
```
3) Build current rebalancing status
   
3.1. From features list - pick these features (which are added after VZ last 4.8.5)
For catalog - CAMS_ASSET_500
For projects - PROJ_ASSET_500
For Glossary - GLOSSARY_510

3.2. Find total registered number from the `register.json`

3.3. Searching them in feat_status (number of lines/rows containing). For example:
CAMS_ASSET_500 = 32 - i.e. feature status is updated for 32 catalogs out of total registered 174 catalogs
PROJ_ASSET_500 = 111 - i.e. feature status is updated for 111 projects out of total registered 1073 projects
GLOSSARY_510 = 15 - i.e. feature status is updated for 15 categories out of total registered 15 categories


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
group by container_id;
```
## Check/monitor current initial crawl processed count for a catalog.
```
select * from wkc_reporting.bidata_sync_status where zone_id = '<catalog_id>'
```

## How Reporting sync works?
* When you enable a catalog (same for projects/categories), it will crawl through the catalog and sync all it's assets/artifacts.
  * If sync fails for any asset - It is skipped and logged into __bidata_sync_errors__ table
    * (It retries them __once__ at the end of crawl process again) 
  * Then the catalog is marked as __ACTIVE__. 
    * After that any change in any assets within the catalog is communicated to reporting through RMQ events 
      * And, once it receives any event for any asset, it will __sync/re-sync that individual asset for delta change__. 
  * If it encounters any rare scenario which is not handled by code. 
     * It will re-try for 4 times at the interval of 15 minutes. 
     * and will mark catalog as __FAILED , if the issue persists even after 4 retries__. 
     * If it is marked as __FAILED__ 
       * Will need to identify the cause, and fix it. 
       * And need to initiate re-sync of that catalog - using UI option - __Update Reporting__ 

## Find reason for skipped assets
```
select count(*) from wkc_reporting.dq_checks where container_id = '<catalog_id/project_id';
select count(*) from wkc_reporting.dq_issues_for_assets where container_id = '<catalog_id/project_id';
select count(*) from wkc_reporting.dq_issues_for_asset_columns where container_id = '<catalog_id/project_id';
select object_type, count(*) from wkc_reporting.bidata_sync_errors where zone_id = '<catalog_id/project_id' group by object_type;
```
Depending on where you find the record, check that table for details, for example: `select * from wkc_reporting.bidata_sync_errors where zone_id = '<catalog_id/project_id>'`

## Force sync
To trigger re-sync of all the assets under a project or catalog, you can use this curls command.
```
curl -i -k -H "content-type: application/json" -H "Authorization: Bearer $TOKEN" -X POST "https://$HOSTNAME/v3/reporting/999/start?soft_restart=true&failed_only=true&include_passed_zone_ids=<coma separated list of catalig_id/project_id>"
```
Example:
```
curl -i -k -H "content-type: application/json" -H "Authorization: Bearer $TOKEN" -X POST "https://$HOSTNAME/v3/reporting/999/start?soft_restart=true&failed_only=true&include_passed_zone_ids=aaaaa090-64bc-4c26-9ad7-ae615db92cab,xxxxx090-64bc-4c26-9ad7-ae615db92cab"
```

## WKC reporting synchronization appearing stuck
1) Set the status of catalogs & projects back to ACTIVE/SUCCESS:
```
oc exec -it c-db2oltp-wkc-db2u-0 bash
db2 connect to wfdb

db2 "delete from BIOPSDB_icp4data.rpt_error_cache"

db2 "update BIOPSDB_icp4data.rpt_load_zone_queue set status = 1000"
db2 "update BIOPSDB_icp4data.rpt_load_feature_status set status = 1000"
```
2) Restarted wkc_bi_service pods.

