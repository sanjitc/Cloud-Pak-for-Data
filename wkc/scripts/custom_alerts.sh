#!/bin/bash
# Pseudo code for send notification from custom alerts. 
# Currently it monitor CouchDB reindexing. You can run this periodically from the cron job, and depending on the reindexing activity, it send an alert.
# More checks can be add in future.

couchdb_designdoc_reindexing() {
  oc exec -n <wkc/cpd project> wdp-couchdb-0 -c couchdb -- bash -c 'curl -ks -u "admin:`cat /etc/.secrets/COUCHDB_PASSWORD`" https://localhost:6984/_active_tasks' |jq '.[] | select((.type == "search_indexer") and (.design_document|endswith("_temporary")))' > /tmp/couchdb_designdoc_reindexing.out

  if [ `stat -c %s /tmp/couchdb_designdoc_reindexing.out` -ne 0 ]; then
	  echo "file empty"
	  mail -s "PRODUCTION: Warning! Reindexing in Progress for CouchDB Design Document" <email address> < /tmp/couchdb_designdoc_reindexing.out
  fi
}

oc login .......

## Monitoring couchDB reindexing
couchdb_designdoc_reindexing
