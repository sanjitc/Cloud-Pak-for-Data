### CouchDb pod using high CPU/Memory resource.

What's running inside CouchDb pod? 
```
oc exec wdp-couchdb-0 -c couchdb -- bash -c 'curl -ks -u "admin:`cat /etc/.secrets/COUCHDB_PASSWORD`" https://localhost:6984/_active_tasks' |jq .

oc exec wdp-couchdb-0 -c couchdb -- bash -c 'curl -ks -u "admin:`cat /etc/.secrets/COUCHDB_PASSWORD`" https://localhost:6984/_active_tasks' |jq '. | length'
```

Access CouchDb console:
```
Get credential from the wdp-couchdb secret
oc port-forward svc/wdp-couchdb-svc 5984:5984
https://localhost:5984/_utils/
```
