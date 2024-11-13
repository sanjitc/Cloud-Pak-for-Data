### CouchDb pod using high CPU/Memory resource.

What's running inside CouchDb pod? 
```
oc exec wdp-couchdb-0 -c couchdb -- bash -c 'curl -ks -u "admin:`cat /etc/.secrets/COUCHDB_PASSWORD`" https://localhost:6984/_active_tasks' |jq .
```
