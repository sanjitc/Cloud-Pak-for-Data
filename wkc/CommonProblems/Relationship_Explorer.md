## After migration from 4.6 to 4.8/5.x we required run re-sync.

- For glossary artifacts:
```
curl -k -X 'POST' 'https://cpd- wkc.apps.cpdcluster.com/v3/glossary_terms/admin/resync?artifact_type=all' - H 'accept: application/json' -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{}' 
```
- To start sync process of all catalog assets:
```
oc create job --from=cronjob/wkc-search-lineage-cronjob lineage-job oc edit cronjob wkc-search-lineage-cronjob 
       - name: dbs_to_sync
              value: '[]'
```
- In case just one catalog needs to be synchronized, or more, value parameter can be modified to contain list of Catalog ID’s like in below example:
```
- name: dbs_to_sync
 value: '["9a2c6934-9ce2-4615-980e-24402aa20c38"]'
```
