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
For health check from the elasticsearch cluster pods
```
curl -X GET https://localhost:19200/_cluster/health?filter_path=status,*_shards\&pretty=true
curl -X GET  https://localhost:19200/_cluster/health
```
## Check incoming request from an user
```
oc logs catalog-api... -f --tail=10 | grep <userid of the use i.e., svc_maria_prod_dgi>

For example:
oc logs catalog-api-64c959cc85-n6qwt -f --tail=10 | grep 1000331024
```
## Logs

