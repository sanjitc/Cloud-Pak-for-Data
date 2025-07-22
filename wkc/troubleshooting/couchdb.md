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

How to check the design document version for a given catalog?
```
1. oc get secret wdp-couchdb -o yaml -n <<namespace>> | grep "adminUsername:" |head -n 1 | awk -F ": " '{print $2}' | base64 -d | xargs
2. oc get secret wdp-couchdb -o yaml -n <<namespace>> | grep "adminPassword:" |head -n 1 | awk -F ": " '{print $2}' | base64 -d | xargs
3. oc get pods -n <<namespace>> | grep catalog-api
4. oc exec -it <<one of catalog api pods>> -n <<namespace>> bash
5. env |grep -i cloudant
6. curl -k -s https://<<user-from-1>>:<<password-from-2>>@$<<host-port-from-5>>/v2_<<GCP-Catalog-Id>>_assets/_all_docs | grep -oE '"_design/combined_search_asset_v[0-9]+(_temporary)?"

In this case, step 1-5 are to gather variable values.
Step 6 is checking for a single catalog ID.
```

How to find the size of portal-notifications in the CouchDB?
```
oc exec wdp-couchdb-0 -c couchdb -- bash -c 'curl -ks -u "admin:`cat /etc/.secrets/COUCHDB_PASSWORD`" https://localhost:6984/portal-notifications_icp_test' |jq .
```
