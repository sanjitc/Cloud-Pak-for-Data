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
## Force sync
To trigger re-sync of all the assets under a project or catalog, you can use this curls command.
```
curl -i -k -H "content-type: application/json" -H "Authorization: Bearer $TOKEN" -X POST "https://$HOSTNAME/v3/reporting/999/start?soft_restart=true&failed_only=true&include_passed_zone_ids=\"<coma separated list of catalig_id/project_id>\""
```
Example:
```
curl -i -k -H "content-type: application/json" -H "Authorization: Bearer $TOKEN" -X POST "https://$HOSTNAME/v3/reporting/999/start?soft_restart=true&failed_only=true&include_passed_zone_ids=\"aaaaa090-64bc-4c26-9ad7-ae615db92cab,xxxxx090-64bc-4c26-9ad7-ae615db92cab\""
```
