# CPD storage class migration

---

## Migration context

### Environment info
```
OCP: 4.12
CPD: 4.8.5
ODF: 4.12
```

### PVCs to be migrated from ocs-storagecluster-cephfs to ocs-storagecluster-ceph-rbd
```
### Db2u PVs related to IKC. The c-db2oltp-wkc-meta and c-db2oltp-wkc-meta PVCs should be on cephfs sorageclass.

NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  AGE
c-db2oltp-wkc-data     Bound    pvc-0706f3af-ccd7-420f-840d-4cfdd56988de   243Gi      RWX            ocs-storagecluster-cephfs     385d
```
~~c-db2oltp-wkc-meta     Bound    pvc-fbe8fe5b-8c7e-42b6-a5ed-5e2aec25f2fd   20Gi       RWX            ocs-storagecluster-cephfs     385d~~

~~wkc-db2u-backups       Bound    pvc-d070ece6-7c0f-4419-8293-a3e48d084717   40Gi       RWX            ocs-storagecluster-cephfs     385d~~


## 1 Pre-migration tasks
### 1.1 Have a cluster level backup
Backup your Cloud Pak for Data installation before you upgrade.
For details, see Backing up and restoring Cloud Pak for Data (https://www.ibm.com/docs/en/SSQNUZ_4.8.x/cpd/admin/backup_restore.html).

### 1.2 Have backup for the statefulsets relevant to the PV migration
#### 1.2.1 Create a backup dir.
```
mkdir -p /opt/ibm/cpd_pv_migration
export CPD_PV_MIGRATION_DIR=/opt/ibm/cpd_pv_migration
```

#### 1.2.2 Bakup for the WKC, db2ucluster CR.
```
oc get wkc -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/wkc-cr.yaml
oc get db2ucluster db2oltp-wkc -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/db2uclusters-cr.yaml
```

#### 1.2.3 Bakup for c-db2oltp-wkc-db2u.
```
oc get db2ucluster db2oltp-wkc -n ${PROJECT_CPD_INST_OPERANDS} -o yaml > ${CPD_PV_MIGRATION_DIR}/cr-db2ucluster.yaml

oc get sts -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc-db2u" | awk '{print $1}'| xargs oc get sts -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/sts-c-db2oltp-wkc-db2u-bak.yaml

for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc-data" | awk '{print $1}') ;do oc get pvc $p -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/pvc-$p-bak.yaml;done

for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc-data" | awk '{print $3}') ;do oc get pv $p -o yaml -n ${PROJECT_CPD_INST_OPERANDS} > ${CPD_PV_MIGRATION_DIR}/pv-$p-bak.yaml;done
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
Image is available on :
```
hptv-docker-icp4d-np.oneartifactoryci.verizon.com/rhel7/rhel-tools:latest
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
### 2.1 Put db2uclusters CR into maintenance mode
Put wkc and db2uclusters into maintenance mode for preventing the migration work from being impacted by the operator reconciliation.
```
oc patch wkc wkc-cr --type merge --patch '{"spec": {"ignoreForMaintenance": true}}' -n ${PROJECT_CPD_INST_OPERANDS}
oc patch db2ucluster db2oltp-wkc --type merge --patch '{"spec": {"ignoreForMaintenance": true}}' -n ${PROJECT_CPD_INST_OPERANDS}
```
Make sure the db2uclusters put into the maintenance mode successfully.
```
oc get wkc wkc-cr -n ${PROJECT_CPD_INST_OPERANDS}
oc get db2ucluster db2oltp-wkc -n ${PROJECT_CPD_INST_OPERANDS}
```

**We should put all _db2uclusters related Deployment and Statefulset to 0_.**

### 2.2 Change the ReclaimPolicy to be "Retain" for the existing PVs (the ones with the wrong SC ocs-storagecluster-cephfs)

1.Patch the c-db2oltp-wkc-db2u PVs.
```
for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc-data" | awk '{print $3}') ;do oc patch pv $p -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS};done
```

Make sure the ReclaimPolicy of the c-db2oltp-wkc-db2u PVs are changed to be "Retain".

```
oc get pv | egrep "c-db2oltp-wkc-data"
pvc-0706f3af-ccd7-420f-840d-4cfdd56988de   243Gi      RWX            Retain           Bound    hptv-prodcloudpak/c-db2oltp-wkc-data                                            ocs-storagecluster-cephfs              385d
```

### 2.4 Migration for DB2OLTP
#### 2.4.1 Preparation
- Get old PVC name and volume name.

```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc-data"
```

Sample output looks like this:

```
NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  AGE
c-db2oltp-wkc-data     Bound    pvc-0706f3af-ccd7-420f-840d-4cfdd56988de   243Gi      RWX            ocs-storagecluster-cephfs     385d
```

- Note the mount path of the meta, data and backup volumes are `/mnt/blumeta0` and `/mnt/backup` by checking the volumeMounts definition in c-db2oltp-wkc-db2u sts yaml file. 

```
        volumeMounts:
        - mountPath: /mnt/bludata0
          name: data
```

- Make sure that the replicas of c-db2oltp-wkc-db2u sts has been scaled down to zero.

```
oc scale sts c-db2oltp-wkc-db2u -n ${PROJECT_CPD_INST_OPERANDS} --replicas=0
```

```
oc get sts -n ${PROJECT_CPD_INST_OPERANDS} | grep -i c-db2oltp-wkc-db2u
```
#### 2.4.2 Start a new temporary deployment using the rhel-tools image
```
oc -n ${PROJECT_CPD_INST_OPERANDS} create deployment sleep --image=registry.access.redhat.com/rhel7/rhel-tools -- tail -f /dev/null
```
#### 2.4.3 Migration for the c-db2oltp-wkc-data pvc
- Create a new PVC by referencing the c-db2oltp-wkc-data pvc. 
```
oc get pvc c-db2oltp-wkc-data -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-c-db2oltp-wkc-data-new.json
```

Specify a new name and the right storage class (ocs-storagecluster-ceph-rbd) for the new PVC

```
tmp=$(mktemp)
jq '.metadata.name = "c-db2oltp-wkc-data-new"' pvc-c-db2oltp-wkc-data-new.json > "$tmp" && mv -f "$tmp" pvc-c-db2oltp-wkc-data-new.json

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' c-db2oltp-wkc-data-new.json > "$tmp" && mv -f "$tmp" pvc-c-db2oltp-wkc-data-new.json

```
Create the new PVC.

```
oc apply -f pvc-c-db2oltp-wkc-data-new.json

```

Make sure the new PVC is created successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep c-db2oltp-wkc-data-new
```

- Mount the old c-db2oltp-wkc-data PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=old-claim --claim-name=c-db2oltp-wkc-data --mount-path=/old-claim
```
- Mount the new c-db2oltp-wkc-data-new PVC to the sleep pod
```
oc set volume deployment/sleep --add -t pvc --name=new-claim --claim-name=c-db2oltp-wkc-data-new --mount-path=/new-claim
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

- Patch the PV of the c-db2oltp-wkc-data-new PVC for chaning the ReclaimPolicy to be "Retain" 
```
oc patch pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep c-db2oltp-wkc-data-new | awk '{print $3}') -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' -n ${PROJECT_CPD_INST_OPERANDS}
```

Make sure the ReclaimPolicy was change to be "Retain" successfully.

```
oc get pv $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep c-db2oltp-wkc-data-new | awk '{print $3}')
```

- Recreate original c-db2oltp-wkc-data PVC
<br>
The c-db2oltp-wkc-data PVC points to new PV created earlier by the c-db2oltp-wkc-data-new PVC we created and copied the data to.
<br>
<br>
Get the volume name created by the c-db2oltp-wkc-data-new PVC.

```
export PV_NAME_C_DB2OLTP_WKC_DATA=$(oc get pvc c-db2oltp-wkc-data-new --output jsonpath={.spec.volumeName} -n ${PROJECT_CPD_INST_OPERANDS})
```

Create the yaml file of the new c-db2oltp-wkc-data PVC.

```
oc get pvc c-db2oltp-wkc-data -o json | jq 'del(.status)'| jq 'del(.metadata.annotations)' | jq 'del(.metadata.creationTimestamp)'|jq 'del(.metadata.resourceVersion)'|jq 'del(.metadata.uid)'| jq 'del(.spec.volumeName)' > pvc-c-db2oltp-wkc-data-recreate.json
```

```
tmp=$(mktemp)

jq '.spec.storageClassName = "ocs-storagecluster-ceph-rbd"' pvc-c-db2oltp-wkc-data-recreate.json > "$tmp" && mv -f "$tmp" pvc-c-db2oltp-wkc-data-recreate.json
```

Refer to the new PV.

```
jq --arg PV_NAME_C_DB2OLTP_WKC_DATA "$PV_NAME_C_DB2OLTP_WKC_DATA" '.spec.volumeName = $PV_NAME_C_DB2OLTP_WKC_DATA' pvc-c-db2oltp-wkc-data-recreate.json > "$tmp" && mv -f "$tmp" pvc-c-db2oltp-wkc-data-recreate.json
```

Remove the old and new PVCs for c-db2oltp-wkc-data
```
oc delete pvc c-db2oltp-wkc-data-new -n ${PROJECT_CPD_INST_OPERANDS}

oc delete pvc c-db2oltp-wkc-data -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove the `claimRef` section from the new PV.
```
oc patch pv $PV_NAME_C_DB2OLTP_WKC_DATA -p '{"spec":{"claimRef": null}}'
```

Recreate the c-db2oltp-wkc-data PVC.

```
oc apply -f pvc-c-db2oltp-wkc-data-recreate.json

```

Make sure the new PVC is created and bound successfully.
```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep c-db2oltp-wkc-data
```

#### 2.4.4 Scale the c-db2oltp-wkc-db2u statefulset back
```
oc scale sts c-db2oltp-wkc-db2u --replicas=1 -n ${PROJECT_CPD_INST_OPERANDS}
```

### 2.7.Change the ReclaimPolicy back to be "Delete" for the PVs

1.Patch the c-db2oltp-wkc-db2u PVs.
```
for p in $(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | egrep "c-db2oltp-wkc-data" | awk '{print $3}') ;do oc patch pv $p -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}' -n ${PROJECT_CPD_INST_OPERANDS};done
```

### 2.8.Make sure the correct storage type is specified in WKC cr db2ucluster db2oltp-wkc
**_NEED to pay attension_**
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
**We should put all _WKC related Deployment and Statefulset to regular number_.**
Get the db2ucluster db2oltp-wkc cr out of the maintenance mode to trigger the operator reconcilation.

```
oc patch db2ucluster db2oltp-wkc --type merge --patch '{"spec": {"ignoreForMaintenance": false}}' -n ${PROJECT_CPD_INST_OPERANDS}
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
