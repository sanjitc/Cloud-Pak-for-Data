## Check all pods are healthy
```
# oc get pod | egrep -v 'Complete|1/1|2/2|3/3|4/4|5/5|6/6'
NAME                                                              READY   STATUS      RESTARTS         AGE
env-spec-sync-job-29197720-xl99c                                  0/1     Error       0                18d
lineage-scanner-service-5fb6b79c87-4z8gx                          0/1     Error       0                36d
```
## Any global search catalog bulk reindex running?
Check `wkc-search-reindexing-job` is running on any catalog, which can cause a performance issue. With a large amount of data, this causes undue stress on the system and slows down the global search activities. You can delete the job anytime without causing any problem.
```
oc get jobs | grep wkc-search-reindexing-job
```
## Size of portal-notification-db in CouchDB
A large number of notification records in the `portal-notification-db` can cause problems. This database stores the notifications and any email alerts generated from the CPD, IKC, and other services. A couple of GB in size is fine. Make sure to periodically clean the data from portal-notification-db.
- Find the data size
```
# oc exec wdp-couchdb-0 -c couchdb -- bash -c 'curl -ks -u "admin:`cat /etc/.secrets/COUCHDB_PASSWORD`" https://localhost:6984/portal-notifications_icp_test' |jq .

{
  "instance_start_time": "1616623961",
  "db_name": "portal-notifications_icp_test",
  "purge_seq": "0-g1AAAAC_eJzLYWBgYMpgTmFwTc4vTc5ISXIoTynQhbJ1DfSQeHoZBSVlugVF-SnJOfmlKQWJ2XrFZcl6yTmlxSWpRXo5-cmJOTkg4_JYgCRDA5D6DwRZiQxUNj-RIakeYnAWAGj1Q6g",
  "update_seq": "2752140-g1AAAAFxeJzLYWBgYMpgTmFwTc4vTc5ISXIoTynQhbJ1DfSQeHoZBSVlugVF-SnJOfmlKQWJ2XrFZcl6yTmlxSWpRXo5-cmJOTkg4_JYgCRDA5D6DwRZGcxJDCL_lucCxdjNLVIMTdJSqWUdlR2eyJBUD3fx_6dgF6eaJKUYG5lRy54sAHJegv4",
  "sizes": {
    "file": 108802073170,       <---- DATA SIZE
    "external": 378633160850,
    "active": 108532152797
  },
  "props": {},
  "doc_del_count": 0,
  "doc_count": 2751810,
  "disk_format_version": 8,
  "compact_running": false,
  "cluster": {
    "q": 2,
    "n": 3,
    "w": 2,
    "r": 2
  }
}
```
- Delete record:
Clean up the notifications-db using the following API and restart the portal-notification pod afterward.
```
# oc exec wdp-couchdb-0 -c couchdb -- bash -c 'curl -ks -u "admin:`cat /etc/.secrets/COUCHDB_PASSWORD`" -X DELETE https://localhost:6984/portal-notifications_icp_test'
```
Alternatively, on CPD 5.x, a new cronjob `portal-notifications-db-cleanup-cronjob` was introduced to clean this database. "By default, this cronjob is suspended. We should enable the cronjob and let it run once every week. By default cronjob will keep the last 7 days of data in the portal-notification information. It is controlled by the environment variable `CLEANDB_RANGESTART_DAYS` in the cronjob. 

## Check status of elasticsearch
Run cluster health check. Status should be green.
```
# oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request GET --url 'http://localhost:19200/_cat/health' --header 'content-type: application/json'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    70  100    70    0     0   7777      0 --:--:-- --:--:-- --:--:--  8750
1753470082 19:01:22 es-cluster green 3 3 true 126 43 0 0 0 0 - 100.0%
```
If cluster status is yellow or red, check the status of shards:
```
# oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request GET --url http://localhost:19200/_cat/shards  --header 'content-type: application/json'
```
If any shard is UNASSIGNED, loop through all the elastic shards and reroute them to assign them for any unassigned shards.
```
oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request POST --url http://localhost:19200/_cluster/reroute?retry_failed=true  --header 'content-type: application/json'
```
