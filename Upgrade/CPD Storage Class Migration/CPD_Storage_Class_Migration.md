# CPD storage class migration

---

## Migration context

### Environment info
```
OCP: 4.12
CPD: 4.8.5
ODF: 4.12
```

### PVs to be migrated from ocs-storagecluster-cephfs to ocs-storagecluster-ceph-rbd
```
### Db2u PVs related to IKC
c-db2oltp-wkc-data     Bound    pvc-0706f3af-ccd7-420f-840d-4cfdd56988de   243Gi      RWX            ocs-storagecluster-cephfs     385d
c-db2oltp-wkc-meta     Bound    pvc-fbe8fe5b-8c7e-42b6-a5ed-5e2aec25f2fd   20Gi       RWX            ocs-storagecluster-cephfs     385d
wkc-db2u-backups       Bound    pvc-d070ece6-7c0f-4419-8293-a3e48d084717   40Gi       RWX            ocs-storagecluster-cephfs     385d
```

## 1 Pre-migration tasks
### 1.1 Have a cluster level backup
Backup your Cloud Pak for Data installation before you upgrade.
For details, see Backing up and restoring Cloud Pak for Data (https://www.ibm.com/docs/en/SSQNUZ_4.8.x/cpd/admin/backup_restore.html).

### 1.2 Have backup for the statefulsets relevant to the PV migration
1.Create a backup dir.
```
mkdir -p /opt/ibm/cpd_pv_migration
export CPD_PV_MIGRATION_DIR=/opt/ibm/cpd_pv_migration
```

2.Bakup for the WKC CR.
```
oc get wkc -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/wkc-cr.yaml
```

3.Bakup for c-db2oltp-wkc-db2u.
```
oc get db2ucluster db2oltp-wkc -n ${PROJECT_CPD_INST_OPERANDS} -o yaml > ${CPD_PV_MIGRATION_DIR}/cr-db2ucluster.yaml

oc get sts -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc-db2u" | awk '{print $1}'| xargs oc get sts -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/sts-c-db2oltp-wkc-db2u-bak.yaml

for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep egrep "c-db2oltp-wkc|wkc-db2u-backups" | awk '{print $1}') ;do oc get pvc $p -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/pvc-$p-bak.yaml;done

for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc|wkc-db2u-backups" | awk '{print $3}') ;do oc get pv $p -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/pv-$p-bak.yaml;done
```

### 1.3 Mirror images

#### 1.3.1 Mirror the rhel-tools image 
- 1.Save the image in an internet connected machine.

```
podman pull registry.access.redhat.com/rhel7/rhel-tools:latest
podman save registry.access.redhat.com/rhel7/rhel-tools:latest -o rhel-tools.tar
```
- 2.Copy the rhel-tools.tar file to the bastion node

- 3.Push the rhel-tools.tar file to the private image registry.

```
podman load -i rhel-tools.tar

podman images | grep rhel-tools

podman login -u <username> -p <password> <target_registry> --tls-verify=false

podman tag 643870113757 <target_registry>/rhel7/rhel-tools:latest

podman push <target_registry>/rhel7/rhel-tools:latest --tls-verify=false
```

### 1.4 The permissions required for the upgrade is ready

It's recommended having the Openshift cluster administrator permissions ready for this migration.

### 1.5 A health check is made to ensure the cluster's readiness for upgrade.

The OpenShift cluster, persistent storage and Cloud Pak for Data platform and services are in healthy status.

- 1.Check OCP status
<br>
Log into OCP and run below command.

```
oc get co
```

Make sure all the cluster operators in AVAILABLE status. And not in PROGRESSING or DEGRADED status.

<br> <br>
Run this command and make sure all nodes in Ready status.

```
oc get nodes
```

Run this command and make sure all the machine configure pool are in healthy status.
```
oc get mcp
```

- 2.Check Cloud Pak for Data status

Log onto bastion node, run this command in terminal and make sure the Lite and all the services' status are in Ready status.

```
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}
```

```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

Run this command and make sure all pods healthy.
```
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[:digit:]])/\1.*R' | grep -v 'Completed'
```

- 3.Check ODF status
<br>
Make sure the ODF cluster status is healthy and also **with enough capaciy**. 

```
oc describe cephcluster ocs-storagecluster-cephcluster -n openshift-storage
```

### 1.6 Schedule a maintenance time window
This migration work requires down time. It's recommended sending a heads-up to all end-users before starting this migration. 

## 2 Migration 
**Note** This migration steps need to be validated carefully in a testing cluster. Down time is expected during this migration.
### 2.1.Put WKC into maintenance mode
Put WKC into maintenance mode for preventing the migration work from being impacted by the operator reconciliation.
```
oc patch wkc wkc-cr --type merge --patch '{"spec": {"ignoreForMaintenance": true}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
Make sure the WKC put into the maintenance mode successfully.
```
oc get wkc wkc-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

### 2.2.Change the ReclaimPolicy to be "Retain" for the existing PVs (the ones with the wrong SC ocs-storagecluster-cephfs)

1.Patch the c-db2oltp-wkc-db2u PVs.
```
for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc|wkc-db2u-backups" | awk '{print $3}') ;do oc patch pv $p -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS};done
```

Make sure the ReclaimPolicy of the c-db2oltp-wkc-db2u PVs are changed to be "Retain".

```
oc get pv | egrep "c-db2oltp-wkc|wkc-db2u-backups"
pvc-0706f3af-ccd7-420f-840d-4cfdd56988de   243Gi      RWX            Retain           Bound    hptv-prodcloudpak/c-db2oltp-wkc-data                                            ocs-storagecluster-cephfs              385d
pvc-d070ece6-7c0f-4419-8293-a3e48d084717   40Gi       RWX            Retain           Bound    hptv-prodcloudpak/wkc-db2u-backups                                              ocs-storagecluster-cephfs              385d
pvc-fbe8fe5b-8c7e-42b6-a5ed-5e2aec25f2fd   20Gi       RWX            Retain           Bound    hptv-prodcloudpak/c-db2oltp-wkc-meta                                            ocs-storagecluster-cephfs              385d
```

### 2.3.Migrate for ElasticSearch
Reference: https://github.ibm.com/wdp-gov/global-search-wiki/wiki/Migrate-ES-between-storage-types 

### 2.4 Migration for CouchDB
#### 2.4.1 Preparation
- Get old PVC name and volume name.

```

oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep -i wdp-couchdb

```

Sample output looks like this:

```
NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS     AGE
database-storage-wdp-couchdb-0                     Bound    pvc-e8eed9f7-7bb6-4b5d-ab8d-21d49c4ecf35   30Gi       RWO            ocs-storagecluster-cephfs   89d
database-storage-wdp-couchdb-1                     Bound    pvc-14d811c3-b4d8-42c5-b6d9-1c3a44c25534   30Gi       RWO            ocs-storagecluster-cephfs   89d
database-storage-wdp-couchdb-2                     Bound    pvc-fb73ce1c-36b0-4358-a66d-9142bf0ce7b7   30Gi       RWO            ocs-storagecluster-cephfs   89d
```

- Note the mount path of the data volume `/opt/couchdb/data` by checking the volumeMounts definition in wdp-couchdb sts yaml file. 

```
          volumeMounts:
            - name: database-storage
              mountPath: /opt/couchdb/data
```

- Make sure that the replicas of wdp-couchdb sts has been scaled down to zero.

```
oc scale sts wdp-couchdb -n ${PROJECT_CPD_INST_OPERANDS} --replicas=0
```

```
oc get sts -n ${PROJECT_CPD_INST_OPERANDS} | grep -i wdp-couchdb
```
#### 2.4.2 Start a new temporary deployment using the rhel-tools image
```
oc -n ${PROJECT_CPD_INST_OPERANDS} create deployment sleep --image=registry.access.redhat.com/rhel7/rhel-tools -- tail -f /dev/null
```
#### 2.4.3 Migration for the database-storage-wdp-couchdb-0 pvc
- Create a new PVC by referencing the database-storage-wdp-couchdb-0 pvc. 
```
oc get pvc database-storage-wdp-couchdb-0 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-database-storage-wdp-couchdb-0-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC

```
tmp=$(mktemp)
jq '.metadata.name = "database-storage-wdp-couchdb-0-new"' pvc-database-storage-wdp-couchdb-0-new.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-0-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-database-storage-wdp-couchdb-0-new.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-0-new.json

```
Create the new PVC.

```
oc apply -f pvc-database-storage-wdp-couchdb-0-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep database-storage-wdp-couchdb-0-new
```

- Mount the old database-storage-wdp-couchdb-0 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=database-storage-wdp-couchdb-0 --mount-path=/old-claim
```
- Mount the new database-storage-wdp-couchdb-0-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=database-storage-wdp-couchdb-0-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```
**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$ du -sh old-claim/
38M	old-claim/
sh-4.2$ du -sh new-claim/
25M	new-claim/

sh-4.2$ cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
_dbs.couch                : 1
_nodes.couch              : 1
search_indexes            : 1749
shards                    : 297

sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
_dbs.couch                : 1
_nodes.couch              : 1
search_indexes            : 1749
shards                    : 297
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the database-storage-wdp-couchdb-0-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep wdp-couchdb-0-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```

Make sure the ReclaimPolicy was change to be "Retain" successfully.

```
oc get pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep wdp-couchdb-0-new | awk '{print $3}')
```

- Recreate original database-storage-wdp-couchdb-0 PVC
<br>
The database-storage-wdp-couchdb-0 PVC points to new PV created earlier by the database-storage-wdp-couchdb-0-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the database-storage-wdp-couchdb-0-new PVC.

```
export PV_NAME_WDP_COUCHDB_0=$(oc get pvc database-storage-wdp-couchdb-0-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new database-storage-wdp-couchdb-0 PVC.

```
oc get pvc database-storage-wdp-couchdb-0 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-database-storage-wdp-couchdb-0-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-database-storage-wdp-couchdb-0-recreate.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-0-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_WDP_COUCHDB_0 "$PV_NAME_WDP_COUCHDB_0" '.spec.volumeName = $PV_NAME_WDP_COUCHDB_0' pvc-database-storage-wdp-couchdb-0-recreate.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-0-recreate.json
```

Remove the old and new PVCs for wdp-couchdb-0
```
oc delete pvc database-storage-wdp-couchdb-0-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc database-storage-wdp-couchdb-0 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_WDP_COUCHDB_0 -p '{"spec":{"claimRef": null}}'
```

Recreate the database-storage-wdp-couchdb-0 PVC.

```
oc apply -f pvc-database-storage-wdp-couchdb-0-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep database-storage-wdp-couchdb-0
```

#### 2.4.4 Migration for the database-storage-wdp-couchdb-1 pvc
- Create a new PVC by referencing the database-storage-wdp-couchdb-1 pvc. 
```
oc get pvc database-storage-wdp-couchdb-1 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-database-storage-wdp-couchdb-1-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "database-storage-wdp-couchdb-1-new"' pvc-database-storage-wdp-couchdb-1-new.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-1-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-database-storage-wdp-couchdb-1-new.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-1-new.json

```

```
oc apply -f pvc-database-storage-wdp-couchdb-1-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep database-storage-wdp-couchdb-1-new
```

- Mount the old database-storage-wdp-couchdb-1 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=database-storage-wdp-couchdb-1 --mount-path=/old-claim
```
- Mount the new database-storage-wdp-couchdb-1-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=database-storage-wdp-couchdb-1-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$ cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
_dbs.couch                : 1
_nodes.couch              : 1
search_indexes            : 1749
shards                    : 297

sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
_dbs.couch                : 1
_nodes.couch              : 1
search_indexes            : 1749
shards                    : 297
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the database-storage-wdp-couchdb-1-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep wdp-couchdb-1-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original database-storage-wdp-couchdb-1 PVC
<br>
The database-storage-wdp-couchdb-1 PVC points to new PV created earlier by the database-storage-wdp-couchdb-1-new PVC we created and copied the data to.
<br>
<br>

Get the volume name created by the database-storage-wdp-couchdb-1-new PVC.

```
export PV_NAME_WDP_COUCHDB_1=$(oc get pvc database-storage-wdp-couchdb-1-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new database-storage-wdp-couchdb-1 PVC.

```
oc get pvc database-storage-wdp-couchdb-1 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-database-storage-wdp-couchdb-1-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-database-storage-wdp-couchdb-1-recreate.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-1-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_WDP_COUCHDB_1 "$PV_NAME_WDP_COUCHDB_1" '.spec.volumeName = $PV_NAME_WDP_COUCHDB_1' pvc-database-storage-wdp-couchdb-1-recreate.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-1-recreate.json
```

Remove the old and new PVCs for wdp-couchdb-1
```
oc delete pvc database-storage-wdp-couchdb-1-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc database-storage-wdp-couchdb-1 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_WDP_COUCHDB_1 -p '{"spec":{"claimRef": null}}'
```

Recreate the database-storage-wdp-couchdb-1 PVC.

```
oc apply -f pvc-database-storage-wdp-couchdb-1-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep database-storage-wdp-couchdb-1
```

#### 2.4.5 Migration for the database-storage-wdp-couchdb-2 pvc
- Create a new PVC by referencing the database-storage-wdp-couchdb-2 pvc. 
```
oc get pvc database-storage-wdp-couchdb-2 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-database-storage-wdp-couchdb-2-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "database-storage-wdp-couchdb-2-new"' pvc-database-storage-wdp-couchdb-2-new.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-2-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-database-storage-wdp-couchdb-2-new.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-2-new.json

```

Create the wdp-couchdb-2-new pvc. 

```
oc apply -f pvc-database-storage-wdp-couchdb-2-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep database-storage-wdp-couchdb-2-new
```

- Mount the old database-storage-wdp-couchdb-2 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=database-storage-wdp-couchdb-2 --mount-path=/old-claim
```
- Mount the new database-storage-wdp-couchdb-2-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=database-storage-wdp-couchdb-2-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$ cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
_dbs.couch                : 1
_nodes.couch              : 1
search_indexes            : 1749
shards                    : 297

sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
_dbs.couch                : 1
_nodes.couch              : 1
search_indexes            : 1749
shards                    : 297
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the database-storage-wdp-couchdb-2-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep wdp-couchdb-2-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original database-storage-wdp-couchdb-2 PVC
<br>
The database-storage-wdp-couchdb-2 PVC points to new PV created earlier by the database-storage-wdp-couchdb-2-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the database-storage-wdp-couchdb-2-new PVC.

```
export PV_NAME_WDP_COUCHDB_2=$(oc get pvc database-storage-wdp-couchdb-2-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new database-storage-wdp-couchdb-2 PVC.

```
oc get pvc database-storage-wdp-couchdb-2 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-database-storage-wdp-couchdb-2-recreate.json
```

Change the storage class to be `ocs-storagecluster-ceph-rbd`.

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-database-storage-wdp-couchdb-2-recreate.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-2-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_WDP_COUCHDB_2 "$PV_NAME_WDP_COUCHDB_2" '.spec.volumeName = $PV_NAME_WDP_COUCHDB_2' pvc-database-storage-wdp-couchdb-2-recreate.json > "$tmp" && mv -f "$tmp" pvc-database-storage-wdp-couchdb-2-recreate.json
```

Remove the old and new PVCs for wdp-couchdb-2
```
oc delete pvc database-storage-wdp-couchdb-2-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc database-storage-wdp-couchdb-2 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_WDP_COUCHDB_2 -p '{"spec":{"claimRef": null}}'
```

Recreate the database-storage-wdp-couchdb-2 PVC.

```
oc apply -f pvc-database-storage-wdp-couchdb-2-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep database-storage-wdp-couchdb-2
```

#### 2.4.6 Scale the wdp-couchdb statefulset back
```
oc scale sts wdp-couchdb --replicas=3 -n ${PROJECT_CPD_INST_OPERANDS}
```

### 2.5 Migration for Redis
#### 2.5.1 Preparation
- Get old PVC name and volume name.

```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep -i redis-ha-server
```

Sample output looks like this:

```
NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS     AGE
data-redis-ha-server-0                             Bound    pvc-227f0fe0-7c81-47c8-aa6c-1ee2258351f6   10Gi       RWO            ocs-storagecluster-cephfs   90d
data-redis-ha-server-1                             Bound    pvc-5357a48c-0b3e-40b5-9c80-c8fe6492a5f0   10Gi       RWO            ocs-storagecluster-cephfs   90d
data-redis-ha-server-2                             Bound    pvc-08d70302-c02d-4d6c-8685-c8e2db36f160   10Gi       RWO            ocs-storagecluster-cephfs   90d
```

- Note the mount path of the data volume `/data` by checking the volumeMounts definition in redis-ha-server sts yaml file. 

```
      volumeMounts:
        - mountPath: /data
          name: data
```

- Make sure that the replicas of redis-ha-server stst has been scaled down to zero.
```
oc scale sts redis-ha-server -n ${PROJECT_CPD_INST_OPERANDS} --replicas=0
```

```
oc get sts -n ${PROJECT_CPD_INST_OPERANDS} | grep -i redis-ha-server
```
#### 2.5.2 Migration for the data-redis-ha-server-0 pvc
- Create a new PVC by referencing the data-redis-ha-server-0 pvc. 
```
oc get pvc data-redis-ha-server-0 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-redis-ha-server-0-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "data-redis-ha-server-0-new"' pvc-data-redis-ha-server-0-new.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-0-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-redis-ha-server-0-new.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-0-new.json

```

```
oc apply -f pvc-data-redis-ha-server-0-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-redis-ha-server-0-new
```

- Mount the old data-redis-ha-server-0 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=data-redis-ha-server-0 --mount-path=/old-claim
```
- Mount the new data-redis-ha-server-0-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=data-redis-ha-server-0-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$ cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
conf                      : 3
dump.rdb                  : 1
sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
conf                      : 3
dump.rdb                  : 1
lost+found                : 1
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the data-redis-ha-server-0-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep redis-ha-server-0-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original data-redis-ha-server-0 PVC
<br>
The data-redis-ha-server-0 PVC points to new PV created earlier by the data-redis-ha-server-0-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the data-redis-ha-server-0-new PVC.

```
export PV_NAME_REDIS_0=$(oc get pvc data-redis-ha-server-0-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new data-redis-ha-server-0 PVC.

```
oc get pvc data-redis-ha-server-0 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-redis-ha-server-0-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-redis-ha-server-0-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-0-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_REDIS_0 "$PV_NAME_REDIS_0" '.spec.volumeName = $PV_NAME_REDIS_0' pvc-data-redis-ha-server-0-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-0-recreate.json
```

Remove the old and new PVCs for redis-ha-server-0
```
oc delete pvc data-redis-ha-server-0-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc data-redis-ha-server-0 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_REDIS_0 -p '{"spec":{"claimRef": null}}'
```

Recreate the data-redis-ha-server-0 PVC.

```
oc apply -f pvc-data-redis-ha-server-0-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-redis-ha-server-0
```

#### 2.5.3 Migration for the data-redis-ha-server-1 pvc
- Create a new PVC by referencing the data-redis-ha-server-1 pvc. 
```
oc get pvc data-redis-ha-server-1 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-redis-ha-server-1-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "data-redis-ha-server-1-new"' pvc-data-redis-ha-server-1-new.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-1-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-redis-ha-server-1-new.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-1-new.json

```

```
oc apply -f pvc-data-redis-ha-server-1-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-redis-ha-server-1-new
```

- Mount the old data-redis-ha-server-1 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=data-redis-ha-server-1 --mount-path=/old-claim
```
- Mount the new data-redis-ha-server-1-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=data-redis-ha-server-1-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$ cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
conf                      : 3
dump.rdb                  : 1
sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
conf                      : 3
dump.rdb                  : 1
lost+found                : 1
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the data-redis-ha-server-1-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep redis-ha-server-1-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original data-redis-ha-server-1 PVC
<br>
The data-redis-ha-server-1 PVC points to new PV created earlier by the data-redis-ha-server-1-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the data-redis-ha-server-1-new PVC.

```
export PV_NAME_REDIS_1=$(oc get pvc data-redis-ha-server-1-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new data-redis-ha-server-1 PVC.

```
oc get pvc data-redis-ha-server-1 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-redis-ha-server-1-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-redis-ha-server-1-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-1-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_REDIS_1 "$PV_NAME_REDIS_1" '.spec.volumeName = $PV_NAME_REDIS_1' pvc-data-redis-ha-server-1-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-1-recreate.json
```

Remove the old and new PVCs for redis-ha-server-1
```
oc delete pvc data-redis-ha-server-1-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc data-redis-ha-server-1 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_REDIS_1 -p '{"spec":{"claimRef": null}}'
```

Recreate the data-redis-ha-server-1 PVC.

```
oc apply -f pvc-data-redis-ha-server-1-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-redis-ha-server-1
```

#### 2.5.4 Migration for the data-redis-ha-server-2 pvc
- Create a new PVC by referencing the database-storage-wdp-couchdb-2 pvc. 
```
oc get pvc data-redis-ha-server-2 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-redis-ha-server-2-new.json
```

```
tmp=$(mktemp)
jq '.metadata.name = "data-redis-ha-server-2-new"' pvc-data-redis-ha-server-2-new.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-2-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-redis-ha-server-2-new.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-2-new.json

```

```
oc apply -f pvc-data-redis-ha-server-2-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-redis-ha-server-2-new
```

- Mount the old data-redis-ha-server-2 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=data-redis-ha-server-2 --mount-path=/old-claim
```
- Mount the new data-redis-ha-server-2-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=data-redis-ha-server-2-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$ cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
conf                      : 3
dump.rdb                  : 1
sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
conf                      : 3
dump.rdb                  : 1
lost+found                : 1
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the data-redis-ha-server-2-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep redis-ha-server-2-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original data-redis-ha-server-2 PVC
<br>
The data-redis-ha-server-2 PVC points to new PV created earlier by the data-redis-ha-server-2-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the data-redis-ha-server-2-new PVC.

```
export PV_NAME_REDIS_2=$(oc get pvc data-redis-ha-server-2-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new data-redis-ha-server-2 PVC.

```
oc get pvc data-redis-ha-server-2 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-redis-ha-server-2-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-redis-ha-server-2-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-2-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_REDIS_2 "$PV_NAME_REDIS_2" '.spec.volumeName = $PV_NAME_REDIS_2' pvc-data-redis-ha-server-2-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-redis-ha-server-2-recreate.json
```

Remove the old and new PVCs for redis-ha-server-2
```
oc delete pvc data-redis-ha-server-2-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc data-redis-ha-server-2 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_REDIS_2 -p '{"spec":{"claimRef": null}}'
```

Recreate the data-redis-ha-server-2 PVC.

```
oc apply -f pvc-data-redis-ha-server-2-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-redis-ha-server-2
```

#### 2.5.5 Scale the redis-ha-server statefulset back
```
oc scale sts redis-ha-server --replicas=3 -n ${PROJECT_CPD_INST_OPERANDS}
```

### 2.6 Migration for Rabbitmq
#### 2.6.1 Preparation
- Get old PVC name and volume name.

```

oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep -i rabbitmq-ha

```

Sample output looks like this:

```
NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS     AGE
data-rabbitmq-ha-0                                 Bound    pvc-f1c63139-b65e-4474-b2b5-25c2a53955fb   10Gi       RWO            ocs-storagecluster-cephfs   89d
data-rabbitmq-ha-1                                 Bound    pvc-4bd167e4-7df0-418c-a0bb-ce99eb04dc61   10Gi       RWO            ocs-storagecluster-cephfs   89d
data-rabbitmq-ha-2                                 Bound    pvc-85868288-5963-4703-840b-f78f033f34ce   10Gi       RWO            ocs-storagecluster-cephfs   89d
```

- Note the mount path of the data volume `/var/lib/rabbitmq` by checking the volumeMounts definition in rabbitmq-ha sts yaml file. 

```
        volumeMounts:
        - mountPath: /var/lib/rabbitmq
          name: data
```

- Make sure that the replicas of rabbitmq-ha stst has been scaled down to zero.

```
oc scale sts rabbitmq-ha --replicas=0 -n ${PROJECT_CPD_INST_OPERANDS}
```

```
oc get sts -n ${PROJECT_CPD_INST_OPERANDS} | grep -i rabbitmq-ha
```
#### 2.6.2 Migration for the data-rabbitmq-ha-0 pvc
- Create a new PVC by referencing the data-rabbitmq-ha-0 pvc. 
```
oc get pvc data-rabbitmq-ha-0 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-0-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "data-rabbitmq-ha-0-new"' pvc-data-rabbitmq-ha-0-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-0-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-0-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-0-new.json

```

```
oc apply -f pvc-data-rabbitmq-ha-0-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-0-new
```

- Mount the old data-rabbitmq-ha-0 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=data-rabbitmq-ha-0 --mount-path=/old-claim
```
- Mount the new data-rabbitmq-ha-0-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=data-rabbitmq-ha-0-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$  cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
mnesia                    : 64
sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
lost+found                : 1
mnesia                    : 64
```
- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the data-rabbitmq-ha-0-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep rabbitmq-ha-0-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original data-rabbitmq-ha-0 PVC
<br>
The data-rabbitmq-ha-0 PVC points to new PV created earlier by the data-rabbitmq-ha-0-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the data-rabbitmq-ha-0-new PVC.

```
export PV_NAME_RABBITMQ_0=$(oc get pvc data-rabbitmq-ha-0-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new data-rabbitmq-ha-0 PVC.

```
oc get pvc data-rabbitmq-ha-0 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-0-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-0-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-0-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_RABBITMQ_0 "$PV_NAME_RABBITMQ_0" '.spec.volumeName = $PV_NAME_RABBITMQ_0' pvc-data-rabbitmq-ha-0-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-0-recreate.json
```

Remove the old and new PVCs for rabbitmq-ha-0
```
oc delete pvc data-rabbitmq-ha-0-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc data-rabbitmq-ha-0 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_RABBITMQ_0 -p '{"spec":{"claimRef": null}}'
```

Recreate the data-rabbitmq-ha-0 PVC.

```
oc apply -f pvc-data-rabbitmq-ha-0-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-0
```

#### 2.6.3 Migration for the data-rabbitmq-ha-1 pvc
- Create a new PVC by referencing the data-rabbitmq-ha-1 pvc. 
```
oc get pvc data-rabbitmq-ha-1 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-1-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "data-rabbitmq-ha-1-new"' pvc-data-rabbitmq-ha-1-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-1-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-1-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-1-new.json

```

```
oc apply -f pvc-data-rabbitmq-ha-1-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-1-new
```

- Mount the old data-rabbitmq-ha-1 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=data-rabbitmq-ha-1 --mount-path=/old-claim
```
- Mount the new data-rabbitmq-ha-1-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=data-rabbitmq-ha-1-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
Ensure the number of files between the old-claim and the new-claim folder is same. 
For example:<br>

```
sh-4.2$  cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
mnesia                    : 64
sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
lost+found                : 1
mnesia                    : 64
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the data-rabbitmq-ha-1-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep rabbitmq-ha-1-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original data-rabbitmq-ha-1 PVC
<br>
The data-rabbitmq-ha-1 PVC points to new PV created earlier by the data-rabbitmq-ha-1-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the data-rabbitmq-ha-1-new PVC.

```
export PV_NAME_RABBITMQ_1=$(oc get pvc data-rabbitmq-ha-1-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new data-rabbitmq-ha-1 PVC.

```
oc get pvc data-rabbitmq-ha-1 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-1-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-1-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-1-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_RABBITMQ_1 "$PV_NAME_RABBITMQ_1" '.spec.volumeName = $PV_NAME_RABBITMQ_1' pvc-data-rabbitmq-ha-1-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-1-recreate.json
```

Remove the old and new PVCs for rabbitmq-ha-1
```
oc delete pvc data-rabbitmq-ha-1-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc data-rabbitmq-ha-1 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_RABBITMQ_1 -p '{"spec":{"claimRef": null}}'
```

Recreate the data-rabbitmq-ha-1 PVC.

```
oc apply -f pvc-data-rabbitmq-ha-1-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-1
```

#### 2.6.4 Migration for the data-rabbitmq-ha-2 pvc
- Create a new PVC by referencing the data-rabbitmq-ha-2 pvc. 
```
oc get pvc data-rabbitmq-ha-2 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-2-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "data-rabbitmq-ha-2-new"' pvc-data-rabbitmq-ha-2-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-2-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-2-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-2-new.json

```

```
oc apply -f pvc-data-rabbitmq-ha-2-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-2-new
```

- Mount the old data-rabbitmq-ha-2 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=data-rabbitmq-ha-2 --mount-path=/old-claim
```
- Mount the new data-rabbitmq-ha-2-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=data-rabbitmq-ha-2-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
For example:

```
sh-4.2$  cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
mnesia                    : 69
sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
lost+found                : 1
mnesia                    : 69
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the data-rabbitmq-ha-2-new PVC for chaning the ReclaimPolicy to be `Retain` 

```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-2-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original data-rabbitmq-ha-2 PVC
<br>
The data-rabbitmq-ha-2 PVC points to new PV created earlier by the data-rabbitmq-ha-2-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the data-rabbitmq-ha-2-new PVC.

```
export PV_NAME_RABBITMQ_2=$(oc get pvc data-rabbitmq-ha-2-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new data-rabbitmq-ha-2 PVC.

```
oc get pvc data-rabbitmq-ha-2 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-2-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-2-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-2-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_RABBITMQ_2 "$PV_NAME_RABBITMQ_2" '.spec.volumeName = $PV_NAME_RABBITMQ_2' pvc-data-rabbitmq-ha-2-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-2-recreate.json
```

Remove the old and new PVCs for rabbitmq-ha-2
```
oc delete pvc data-rabbitmq-ha-2-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc data-rabbitmq-ha-2 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_RABBITMQ_2 -p '{"spec":{"claimRef": null}}'
```

Recreate the data-rabbitmq-ha-2 PVC.

```
oc apply -f pvc-data-rabbitmq-ha-2-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-2
```

#### 2.6.5 Migration for the data-rabbitmq-ha-3 pvc
- Create a new PVC by referencing the data-rabbitmq-ha-3 pvc. 
```
oc get pvc data-rabbitmq-ha-3 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-3-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC.

```
tmp=$(mktemp)
jq '.metadata.name = "data-rabbitmq-ha-3-new"' pvc-data-rabbitmq-ha-3-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-3-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-3-new.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-3-new.json

```

```
oc apply -f pvc-data-rabbitmq-ha-3-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-3-new
```

- Mount the old data-rabbitmq-ha-3 PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=data-rabbitmq-ha-3 --mount-path=/old-claim
```
- Mount the new data-rabbitmq-ha-3-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=data-rabbitmq-ha-3-new --mount-path=/new-claim
```
- Make sure the sleep pod is up and running
```
oc project ${PROJECT_CPD_INST_OPERANDS}
oc get pod | grep sleep
```
- rsh into the sleep pod
```
oc rsh $(oc get pod | grep sleep | awk '{print $1}')
```

- Migrate data to the new storage:
```
rsync -avxHAX --progress /old-claim/* /new-claim
```

**Note:** Make sure the termial session will not be closed or expired during this step.

- Validate the migration
<br>
For example:

```
sh-4.2$  cd old-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
mnesia                    : 69
sh-4.2$ cd ../new-claim/
sh-4.2$ ls | while read dir; do printf "%-25.45s : " "$dir"; ls -R "$dir" | sed '/^[[:space:]]*$/d' | wc -l; done
lost+found                : 1
mnesia                    : 69
```

- Remove the volume mounts from the sleep deployment
```
oc set volume deployment sleep --remove --name=old-claim
oc set volume deployment sleep --remove --name=new-claim
```

- Patch the PV of the data-rabbitmq-ha-3-new PVC for chaning the ReclaimPolicy to be `Retain` 

```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-3-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
- Recreate original data-rabbitmq-ha-3 PVC
<br>
The data-rabbitmq-ha-3 PVC points to new PV created earlier by the data-rabbitmq-ha-3-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the data-rabbitmq-ha-3-new PVC.

```
export PV_NAME_RABBITMQ_3=$(oc get pvc data-rabbitmq-ha-3-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new data-rabbitmq-ha-3 PVC.

```
oc get pvc data-rabbitmq-ha-3 -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-data-rabbitmq-ha-3-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-data-rabbitmq-ha-3-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-3-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_RABBITMQ_3 "$PV_NAME_RABBITMQ_3" '.spec.volumeName = $PV_NAME_RABBITMQ_3' pvc-data-rabbitmq-ha-3-recreate.json > "$tmp" && mv -f "$tmp" pvc-data-rabbitmq-ha-3-recreate.json
```

Remove the old and new PVCs for rabbitmq-ha-3
```
oc delete pvc data-rabbitmq-ha-3-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc data-rabbitmq-ha-3 -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_RABBITMQ_3 -p '{"spec":{"claimRef": null}}'
```

Recreate the data-rabbitmq-ha-3 PVC.

```
oc apply -f pvc-data-rabbitmq-ha-3-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep data-rabbitmq-ha-3
```

#### 2.6.6 Scale the rabbitmq-ha statefulset back
```
oc scale sts rabbitmq-ha --replicas=4 -n ${PROJECT_CPD_INST_OPERANDS}
```

### 2.7.Change the ReclaimPolicy back to be "Delete" for the PVs

1.Patch the c-db2oltp-wkc-db2u PVs.
```
for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc|wkc-db2u-backups" | awk '{print $3}') ;do oc patch pv $p -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}' -n ${PROJECT_CPD_INST_OPERANDS};done
```

-- ### 2.8.Make sure the correct storage type is specified in WKC cr db2ucluster db2oltp-wkc
```
oc patch wkc wkc-cr --type merge --patch '{"spec": {"blockStorageClass": "ocs-storagecluster-ceph-rbd"}}' -n ${PROJECT_CPD_INST_OPERANDS}
oc patch db2ucluster db2oltp-wkc --type merge --patch '{"spec": {"blockStorageClass": "ocs-storagecluster-ceph-rbd"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```

```
oc get wkc wkc-cr -oyaml
oc get db2ucluster db2oltp-wkc -oyaml
``` 

### 2.9.Make changes to the k8s resources if needed (optional)

### 2.10.Get the WKC cr out of the maintenance mode

Get the WKC cr out of the maintenance mode to trigger the operator reconcilation.

```
oc patch wkc wkc-cr --type merge --patch '{"spec": {"ignoreForMaintenance": false}}' -n ${PROJECT_CPD_INST_OPERANDS}
```

### 2.11 Validation
- Make sure the CCS custom resource is in 'Completed' status and also with the right storage classes.
```
oc get wkc wkc-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

- Make sure all the services are in 'Completed' status.
<br>
Run the cpd-cli manage login-to-ocp command to log in to the cluster.

```
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}
```

Get all services' status.

```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

- Make sure the migration relevant pods are up and running.
```
oc get pods -n ${PROJECT_CPD_INST_OPERANDS}| grep -E "c-db2oltp-wkc-db2u-0"
```

- Make sure the migration relevant PVC are in 'Bound' status and also with the right storage classes.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS}| egrep "c-db2oltp-wkc|wkc-db2u-backups"
```

- Conduct user acceptance tests

- Clean up
```
oc -n ${PROJECT_CPD_INST_OPERANDS} delete deployment sleep 
```

## Reference
- [How to migrate data between PVs in OpenShift 4](https://access.redhat.com/solutions/5794841)
- [Internal discussion](https://ibm-analytics.slack.com/archives/C07E81S6FD1/p1722624208506629?thread_ts=1722453586.457679&cid=C07E81S6FD1)
