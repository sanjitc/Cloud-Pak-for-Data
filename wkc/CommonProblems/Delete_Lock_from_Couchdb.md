# CouchDB pod stuck in init-copy during start up.
```
# oc get pods |grep wdp-couchdb
wdp-couchdb-0                                                     0/2     Init:0/1            0               86m
wdp-couchdb-1                                                     0/2     Init:0/1            0               86m
wdp-couchdb-2                                                     2/2     Running             0               86m
```

During troubleshooting, at one point we noticed "write.lock" file left behind in the CouchDB pod. There’s already a graceful termination in place for the couchdb pods but this doesn’t account for pods that die abruptly due to crash for example. If we encounter the same issue again we need to clear the write locks on startup. Please keep a note of the "write.lock" cleanup process. 

- You only delete lock files during startup failure in init-copy container. It will happen before couchDB pods are running. Do NOT delete lock files while couchdb is running.

- You will see a longer time for couchdb pod to start. It takes really long time (more than 40min) on init-copy container when trying to delete previous write.lock files, as the files on the PVC is large (3.7M files in total under /opt/couchdb/data/).

- Delete lock files from the init-copy container of couchdb pod, before couchdb container is started.
##  RSH to the init-copy container of couchdb pod
```
oc rsh -c init-copy wdp-couchdb-0
```

## clear any left over locks, dont fail if nothing found
```
find /opt/couchdb/data/search_indexes/shards/* -name write.lock -type f -delete || true;
```
