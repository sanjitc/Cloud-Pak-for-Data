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
curl -X GET https://localhost:19200/\_cluster/health?filter_path=status,*_shards\&pretty=true
curl -X GET  https://localhost:19200/_cluster/health
```

## Logs

