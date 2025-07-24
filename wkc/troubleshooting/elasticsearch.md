# Troubleshooting - Elasticsearch issues
## Prods 
v.4.6.x
```
elasticsearch-master-[0-3]
```

v.4.8.x
```
elasticsea-*-es-server-esnode*
```
## Check health
For a health check from the elasticsearch cluster pods (all curl commands need to run from inside an elasticsearch pod; oc exec elasticsearch-master-0 -c elasticsearch -- curl command)
```
oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request GET --url 'http://localhost:19200/_cat/health' --header 'content-type: application/json'
oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request GET --url 'http://localhost:19200/_cat/health?filter_path=status,*_shards\&pretty=true' --header 'content-type: application/json'
```
## Other Troubleshooting command
All these commands can be run as `oc exec $(oc get pod -l app.kubernetes.io/managed-by=ibm-elasticsearch,apps.kubernetes.io/pod-index=0 -o jsonpath='{.items[0].metadata.name}') -- curl ....`
```
curl -X GET https://localhost:19200/_cat/shards?v=true&h=index,shard,prirep,state,node,unassigned.reason&s=state
curl --request GET --url http://localhost:19200/_cat/indices?v=true  --header 'content-type: application/json'
curl --request GET --url 'http://localhost:19200/_cat/recovery?detailed=true&active_only=true&v=true'  --header 'content-type: application/json'
curl --request GET --url 'http://localhost:19200/_snapshot' --header 'content-type: application/json'
curl --request GET --url 'http://localhost:19200/_cat/shards?v=true&h=index%2Cshard%2Cprirep%2Cstate%2Cnode%2Cunassigned.reason&s=state' --header 'content-type: application/json'
curl --request GET --url 'http://localhost:19200/_cat/indices?h=name' --header 'content-type: application/json'
```
## Check status of shards:
```
oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request GET --url http://localhost:19200/_cat/shards  --header 'content-type: application/json'
```
## Check reason for shards UNASSIGNED:
```
oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request GET --url http://localhost:19200/_cluster/allocation/explain  --header 'content-type: application/json'  --data '{"index": "wkc","shard": 0,"primary": false}'
```
## Monitor the status of the initialization and rerouting of shards:
```
oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request GET --url http://localhost:19200/_cat/recovery?detailed=true&active_only=true&v=true  --header 'content-type: application/json'
```
## Loop through all the elastic shards and reroute them to assign them for any unassigned shards
```
oc exec elasticsea-0ac3-ib-6fb9-es-server-esnodes-0 -c elasticsearch -- curl --request POST --url http://localhost:19200/_cluster/reroute?retry_failed=true  --header 'content-type: application/json'
```
## Check incoming request from a user
```
oc logs catalog-api... -f --tail=10 | grep <userid of the use i.e., svc_maria_prod_dgi>

For example:
oc logs catalog-api-64c959cc85-n6qwt -f --tail=10 | grep 1000331024
```
## Logs

