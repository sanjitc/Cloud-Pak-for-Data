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
For health check from the elasticsearch cluster pods (all curl commands need to run from inside a elasticsearch pod; oc exec elasticsearch-master-0 -c elasticsearch -- curl command)
```
curl -X GET https://localhost:19200/_cluster/health?filter_path=status,*_shards\&pretty=true
curl -X GET  https://localhost:19200/_cluster/health
```
## Other Troubleshooting command
```
curl -X GET https://localhost:19200/_cat/shards?v=true&h=index,shard,prirep,state,node,unassigned.reason&s=state
curl --request GET --url http://localhost:19200/_cat/indices?v=true  --header 'content-type: application/json'
curl --request GET --url 'http://localhost:19200/_cat/recovery?detailed=true&active_only=true&v=true'  --header 'content-type: application/json'
curl --request GET --url 'http://localhost:19200/_snapshot' --header 'content-type: application/json'

```
## Check incoming request from an user
```
oc logs catalog-api... -f --tail=10 | grep <userid of the use i.e., svc_maria_prod_dgi>

For example:
oc logs catalog-api-64c959cc85-n6qwt -f --tail=10 | grep 1000331024
```
## Logs

