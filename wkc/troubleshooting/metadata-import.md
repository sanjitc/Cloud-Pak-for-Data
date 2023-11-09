# Troubleshooting - Metadata Import

## Check if metadata_discovery queues draining from CLI. If queue is not draining, restart the metadata_discovery pods.
```
oc exec rabbitmq-ha-0 -- rabbitmqctl list_queues | grep metadata-discovery
```
## Prods 

```
$ oc get pods | grep "metadata-discovery*"

metadata-discovery-7db58cb974-fcphw                               1/1     Running                 985        15d
metadata-discovery-7db58cb974-vj54w                               1/1     Running                 2629       40d
metadata-discovery-7db58cb974-crbds                               1/1     Running                 2629       40d

jobs-api*
wdp-couchdb*
rabbitmq*
``` 

## Logs
