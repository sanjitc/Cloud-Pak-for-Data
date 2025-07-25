## Check all pods are healthy

## Any global search catalog bulk reindex running?
Check wkc-search-reindexing-job running on any catalog, which can cause performance issue. You can delete the job anytime without causing any problem.
```
oc get jobs | grep wkc-search-reindexing-job
```
## Size of portal-notification-db in CouchDB
Large amount of notification records in the portal-notification-db can cause problem. Couple of Gb in size fine. Make sure periodically clean the data from portal-notification-db.
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
