# CPD Upgrade Runbook - v.4.8.5 to 5.1.1

---
## Upgrade documentation
[Upgrading from IBM Cloud Pak for Data Version 4.8 to Version 5.1](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=upgrading-from-cloud-pak-data-version-48)

## Upgrade context
From

```
OCP: 4.14
CPD: 4.8.5
Storage: Storage Fusion 2.7.2
Componenets: cpd_platform,wkc,analyticsengine,mantaflow,datalineage,ws,ws_runtimes,wml,openscale,db2wh
```

To

```
OCP: 4.14
CPD: 5.1.1
Storage: Storage Fusion 2.7.2
Componenets: cpd_platform,wkc,analyticsengine,mantaflow,datalineage,ws,ws_runtimes,wml,openscale,db2wh
```

## Pre-requisites
#### 1. Backup of the cluster is done.
Backup your Cloud Pak for Data cluster before the upgrade.
For details, see [Backing up and restoring Cloud Pak for Data](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=administering-backing-up-restoring-software-hub).

**Note:**
Make sure there are no scheduled backups conflicting with the scheduled upgrade.
  
#### 2. The image mirroring completed successfully
If a private container registry is in-use to host the IBM Cloud Pak for Data software images, you must mirror the updated images from the IBM® Entitled Registry to the private container registry. <br>
Reference: <br>
[Mirroring images to private image registry](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=prufpcr-mirroring-images-private-container-registry) 
<br>
#### 3. The permissions required for the upgrade is ready

- Openshift cluster permissions
<br>
An Openshift cluster administrator can complete all of the installation tasks.

<br>

However, if you want to enable users with fewer permissions to complete some of the installation tasks, follow the steps in this documentation and get the roles with required permission prepared.

[Reauthorizing the instance administrator](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=hub-reauthorizing-instance-administrator)

<br>

- Cloud Pak for Data permissions

<br>
The Cloud Pak for Data administrator role or permissions is required for upgrading the service instances.

- Permission to access the private image registry for pushing or pull images
  
- Access to the Bastion node for executing the upgrade commands

#### 4. Migrate environments based on Watson Studio Runtime 22.2 and Runtime 23.1 from IBM Cloud Pak® for Data 4.8 (optional)
The Watson Studio Runtime 22.2 and Runtime 23.1 are not included in IBM® Software Hub. If you want to continue using environments that are based on Runtime 22.2 or Runtime 23.1, you must migrate them.
<br>
[Migrating environments based on Runtime 22.2 and Runtime 23.1 from IBM Cloud Pak® for Data 4.8](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=u-migrating-environments-based-runtime-222-runtime-231-from-cloud-pak-data-48-50)

#### 5. Collect the number of profiling records to be migrated
Collect profiling records information

```
oc project ${PROJECT_CPD_INST_OPERANDS}

oc rsh $(oc get pods --no-headers | grep -i asset-files | head -n 1 | awk '{print $1}')

nohup ls -alRt /mnt/asset_file_api | egrep -i 'REF_|ARES_' > /tmp/profiling_records_ref.txt &

nohup ls -alRt /mnt/asset_file_api | egrep -i 'REF_|ARES_' | wc -l > /tmp/profiling_records_ref_number.txt &

```

#### 6. Collect the number about Neo4J database size of Manta Automated Data Lineage

```
oc rsh $(oc get pods --no-headers | grep -i manta-dataflow | head -n 1 | awk '{print $1}')
nohup du -hs /opt/mantaflow/server/manta-dataflow-server-dir/data/neo4j/data > /tmp/neo4j_db_size.txt &

```

#### 7. A pre-upgrade health check is made to ensure the cluster's readiness for upgrade.
- The OpenShift cluster, persistent storage and Cloud Pak for Data platform and services are in healthy status.

## Table of Content

```
Part 1: Pre-upgrade
1.1 Collect information and review upgrade runbook
1.1.1 Review the upgrade runbook
1.1.2 Backup before upgrade
1.1.3 Uninstall all hotfixes and apply preventative measures
1.1.4 Uninstall the old RSI pathch
1.2 Set up client workstation 
1.2.1 Prepare a client workstation
1.2.2 Update cpd_vars.sh for the upgrade to Version 5.1.1
1.2.3 Obtain the olm-utils-v3 available
1.2.4 Ensure the cpd-cli manage plug-in has the latest version of the olm-utils image
1.2.5 Ensure the images were mirrored to the private container registry
1.2.6 Creating a profile for upgrading the service instances
1.3 Health check OCP & CPD

Part 2: Upgrade
2.1 Upgrade CPD to 5.1.1
2.1.1 Upgrading shared cluster components
2.1.2 Preparing to upgrade the CPD instance to IBM Software Hub
2.1.3 Upgrading to IBM Software Hub
2.1.4 Upgrading the operators for the services
2.1.5 Applying the RSI patches
2.2 Upgrade CPD services
2.2.1 Upgrading IBM Knowledge Catalog service and apply hot fixes
2.2.2 Upgrading MANTA service
2.2.3 Upgrading Analytics Engine service
2.2.4 Upgrading Watson Studio, Watson Studio Runtimes, Watson Machine Learning and OpenScale
2.2.5 Upgrading Db2 Warehouse

Part 3: Post-upgrade
3.1 Validate the external vault connection setting 
3.2 CCS post-upgrade tasks
3.3 WKC post-upgrade tasks

Part 4: Maintenance
4.1 Migrating from MANTA Automated Data Lineage to IBM Manta Data Lineage
4.2 Changing Db2 configuration settings
4.3 Configure the idle session timeout
4.4 Increase the number of nginx worker connections
4.5 Increase ephemeral storage for zen-watchdog-serviceability-job
4.6 Update wdp-lineage deployment for addressing the potential Db2 high CPU and Memory usage issue
4.7 Apply the workaround for MDE Job
4.8 Upgrade the Backup & Restore service and application

Summarize and close out the upgrade

```

## Part 1: Pre-upgrade
### 1.1 Collect information and review upgrade runbook

#### 1.1.1 Review the upgrade runbook

Review upgrade runbook

#### 1.1.2 Backup before upgrade
Note: Create a folder for 4.8.5 and maintain below created copies in that folder. <br>
Login to the OCP cluster for cpd-cli utility.

```
cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}
```

Capture data for the CPD 4.8.5 instance. No sensitive information is collected. Only the operational state of the Kubernetes artifacts is collected.The output of the command is stored in a file named collect-state.tar.gz in the cpd-cli-workspace/olm-utils-workspace/work directory.

```
cpd-cli manage collect-state \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

Make a copy of existing custom resources (Recommended)

```
oc project ${PROJECT_CPD_INST_OPERANDS}

oc get ibmcpd ibmcpd-cr -o yaml > ibmcpd-cr.yaml

oc get zenservice lite-cr -o yaml > lite-cr.yaml

oc get CCS ccs-cr -o yaml > ccs-cr.yaml

oc get wkc wkc-cr -o yaml > wkc-cr.yaml

oc get analyticsengine analyticsengine-sample -o yaml > analyticsengine-cr.yaml

oc get DataStage datastage -o yaml > datastage-cr.yaml

oc get mantaflow -o yaml > mantaflow-cr.yaml

oc get db2ucluster db2oltp-wkc -o yaml > db2ucluster-db2oltp-wkc.yaml

for i in $(oc get crd | grep cpd.ibm.com | awk '{ print $1 }'); do echo "---------$i------------"; oc get $i $(oc get $i | grep -v "NAME" | awk '{ print $1 }') -o yaml > cr-$i.txt; if grep -q "image_digests" cr-$i.txt; then echo "Hot fix detected in cr-$i"; fi; done

```

Backup the routes.

```
oc get routes -o yaml > routes.yaml
```

Backup the RSI patches.
```
cpd-cli manage get-rsi-patch-info \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--all
```

Backup the SSO configuration:
```
oc get configmap saml-configmap -o yaml > saml-configmap-cm.yaml
```

#### 1.1.3 Uninstall all hotfixes and apply preventative measures 
Remove the hotfixes by removing the images or configurations from the CRs.
<br>

- 1.Uninstall WKC hot fixes.

<br>

1)Edit the wkc-cr with below command.
```
oc edit WKC wkc-cr
```
2)Remove the hot fix images from the WKC custom resource

```
  image_digests:
    finley_public_image: sha256:e89b59e16c4c10fce5ae07774686d349d17b2d21bf9263c50b49a7a290499c6d
    metadata_discovery_image: sha256:9b1811703c2639a822e0d3a2c466ee2a6378bbd4f706da66ed1b61cb96971610
    wdp_kg_ingestion_service_image: sha256:bb6c382edf1da01335152da98b803f44b424e8651c862eaf96b6394d8e735e6f
    wdp_lineage_image: sha256:9eda6aaf3dd2581fc7a85746e4b559192b4b00aa5cd7bc227cb29e7873a3cea1
    wdp_profiling_image: sha256:d5491cc8c8c8bd45f2605f299ecc96b9461cd5017c7861f22735e3a4d0073abd
    wkc_mde_service_manager_image: sha256:35e6f6ede3383df5c0b2a3d27c146cc121bed32d26ab7fa8870c4aa4fbc6e993
    wkc_metadata_imports_ui_image: sha256:a1997d9a9cde9ecc9f16eb02099a272d7ba2e8d88cb05a9f52f32533e4d633ef
```

3)Add or update below entry for setting the number of wkc_bi_data_service replicas to be 3

```
wkc_bi_data_service_max_replicas: 3
wkc_bi_data_service_min_replicas: 3
```

4)Remove the `ignoreForMaintenance: true` from the WKC custom resource

```
ignoreForMaintenance: true
```

5)Save and Exit. Wait untile the WKC Operator reconcilation completed and also the wkc-cr in 'Completed' status. 

```
oc get WKC wkc-cr -o yaml
```

- 2.Uninstall the AnalyticsEngine hot fixes if any.
<br>
1)Edit the analyticsengine-sample with below command.
  
```
oc edit AnalyticsEngine analyticsengine-sample
```

2)Remove the hot fix images from the AnalyticsEngine custom resource if any.

3)Make change for skipping SELinux Relabeling
```
  serviceConfig:
    skipSELinuxRelabeling: true
```

4)Save and Exit. Wait untile the AnalyticsEngine Operator reconcilation completed and also the analyticsengine-sample in 'Completed' status. 

```
oc get AnalyticsEngine analyticsengine-sample -o yaml
```

- 3.Patch the CCS and uninstall the CCS hot fixes.
<br>

1)Edit the CCS cr with below command.
  
```
oc edit CCS ccs-cr
```

2)Remove the hot fix images from the CCS custom resource

```
  image_digests:
    asset_files_api_image: sha256:bfa820ffebcf55b87f7827037daee7ec074d0435139e57acbb494df19aee0e98
    catalog_api_image: sha256:d64c61cbc010d7535b33457439b5cb65c276346d4533963a9a5165471840beb4
    portal_catalog_image: sha256:33e51a0c7eb16ac4b5dbbcd57b2ebe62313435bab2c0c789a1801a1c2c00c77d
    portal_projects_image: sha256:93c38bf9870a5e8f9399b1e90e09f32e5f556d5f6e03b4a447a400eddb08dc4e
    wkc_search_image: sha256:64e59002617d48428cd59a55bbad5ebf0ccf68644fd627fd1e33f6558dbc8b68
```
3)Apply preventative measures for OpenSearch pvc customization problem
<br>
This step is for applying the preventative measures for OpenSearch problem. Applying the preventative measures in this timing can also help to minimize the number of CCS operator reconcilations.
<br>
List OpenSearch PVC sizes, and make sure to preserve the type, and the size of the largest one (PVC names may be different depending on client environment):
<br>

```
oc get pvc | grep elasticsea
dev                        data-elasticsea-0ac3-ib-6fb9-es-server-esnodes-0           Bound     pvc-b25946d2-aa35-4ca9-af1d-9dd65e002cce   187Gi      RWO            ocs-storagecluster-ceph-rbd   265d
dev                        data-elasticsea-0ac3-ib-6fb9-es-server-esnodes-1           Bound     pvc-6bbc7d80-e21f-447b-bc29-22273ee4d91b   187Gi      RWO            ocs-storagecluster-ceph-rbd   265d
dev                        data-elasticsea-0ac3-ib-6fb9-es-server-esnodes-2           Bound     pvc-c3aa19cf-4aa4-456d-a56d-4a2ac3a482ef   187Gi      RWO            ocs-storagecluster-ceph-rbd   265d
dev                        elasticsea-0ac3-ib-6fb9-es-server-snap                     Bound     pvc-6d0ce71f-fd7c-4f27-bbbb-be6d64e52ab2   187Gi      RWX            ocs-storagecluster-cephfs     265d
dev                        elasticsearch-master-backups                               Bound     pvc-5e989b0d-6d82-42d5-8c7f-949143725172   187Gi      RWX            ocs-storagecluster-cephfs     505d

```

In the above example, `187Gi` is the OpenSearch pvc size. `187Gi` is also the backup/snapshot storage size. 
<br>
**Note** if PVCs are of different sizes, we want to make sure to take the biggest one. 
<br>

In CCS CR make sure to set the following properties, with above values used as example:

```
elasticsearch_persistence_size: "187Gi"
elasticsearch_backups_persistence_size: "187Gi"
```

This will make sure that the Opensearch operator will properly reconcile, - as provided values will match the state of the cluster. 

4)Disable bulk resync during the upgrade. This job can be run separately (if its needed) after upgrade has completed. Set the following properties in the spec section of CCS CR.
```
run_reindexer_with_resource_key: false
```

5)Increasing the resource limits for the `search` container of the CouchDb. Set the following property in the spec section of CCS CR.
```
couchdb_search_resources:
  limits:
    cpu: "4"
    memory: 8Gi
  requests:
    cpu: 250m
    memory: 256Mi
 ```

6)Remove the `ignoreForMaintenance: true` from the CCS custom resource

7)Save and Exit. Wait untile the CCS Operator reconcilation completed and also the ccs-cr in 'Completed' status. 

```
oc get CCS ccs-cr -o yaml
```

8)Wait untile the WKC Operator reconcilation completed and also the wkc-cr in 'Completed' status. 

```
oc get WKC wkc-cr -o yaml
```

- 4.Edit the ZenService custom resource.

```
oc edit ZenService lite-cr
```

1)Remove the hot fix images from the ZenService custom resource
```
  image_digests:
    icp4data_nginx_repo: sha256:2ab2c0cfecdf46b072c9b3ec20de80a0c74767321c96409f3825a1f4e7efb788
    icpd_requisite: sha256:5a7082482c1bcf0b23390d36b0800cc04cfaa32acf7e16413f92304c36a51f02
    privatecloud_usermgmt: sha256:e7b0dda15fa3905e4f242b66b18bc9cf2d27ea46e267e5a8d6a3d7da011bddb1
    zen_audit: sha256:ccf61039298186555fd18f568e715ca9e12f07805f42eb39008f851500c0f024
    zen_core: sha256:67f4d92a6e1f39675856fe3b46b36b34e9f0ae25679f75a1628c9d7d44790bad
    zen_core_api: sha256:b3ba3250a228d5f1ba3ea93ccf8b0f018e557f0f4828ed773b57075b842c30e9
    zen_iam_config: sha256:5abf2bf3f29ca28c72c64ab23ee981e8ad122c0de94ca7702980e1d40841d91a
    zen_minio: sha256:f66e6c17d1ed9d90a90e9a1280a18aacb9012bbdb604c5230d97db4cffcb4b48
    zen_utils: sha256:6d906104a8bd8b15f3ebcb2c3ae6a5f93c8d88ce6cfcae4b3eed6657562dc9f3
    zen_watchdog: sha256:4f73b382687bd4de6754292670f6281a7944b6b0903396ed78f1de2da54bc8c0
```

2)Add the `gcMemoryLimit` configurtion under the ZenMinio in the spec which looks like below.
<br>

```
  ZenMinio:
    name: zen-minio
    gcMemoryLimit: 1000MiB
```

3)Save and Exit. Wait untile the ZenService Operator reconcilation completed and also the lite-cr in 'Completed' status. 
<br>

- 5.Edit the mantaflow custom resource.

```
oc edit mantaflow mantaflow-wkc
```

Remove the migration section from the cr.
```
 migrations: 
     h2-format-3: true
```

Save and Exit. Wait untile the Mantaflow Operator reconcilation completed and also the mantaflow-wkc in 'Completed' status. 

<br>

Restart the deployment.

```
oc delete deploy manta-admin-gui manta-configuration-service manta-dataflow -n ${PROJECT_CPD_INST_OPERANDS}
```

- 6.Remove stale secret of global search
Check if the elasticsearch-master-ibm-elasticsearch-cred-secret exists.
```
oc get secret -n ${PROJECT_CPD_INST_OPERANDS} | grep elasticsearch-master-ibm-elasticsearch-cred-secret
```
If yes, then delete this stale secret.
```
oc delete elasticsearch-master-ibm-elasticsearch-cred-secret -n ${PROJECT_CPD_INST_OPERANDS}
```

#### 1.1.4 Uninstall the old RSI patch
1.Run the cpd-cli manage login-to-ocp command to log in to the cluster as a user with sufficient permissions.
```
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}
```
2.Delete the finley-public-env-patch-1-may2024 patch
<br>
Inactivate:
```
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=finley-public-env-patch-1-may2024 \
--state=inactive
```

Delete:
```
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=finley-public-env-patch-1-may2024
```

3.Delete the finley-public-service-patch patch
<br>
Inactivate:
```
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=finley-public-service-patch \
--state=inactive
```

Delete:
```
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=finley-public-service-patch
```

4.Delete the mde-service-manager-env-patch-publish-batch-size patch
<br>
Inactivate:
```
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=mde-service-manager-env-patch-publish-batch-size \
--state=inactive
```

Delete:
```
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=mde-service-manager-env-patch-publish-batch-size
```

5.Delete the mde-service-manager-patch patch
<br>
Inactivate:
```
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=mde-service-manager-patch \
--state=inactive
```

Delete:
```
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=mde-service-manager-patch
```

6.Delete the mde-service-manager-patch-2 patch
<br>
Inactivate:
```
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=mde-service-manager-patch-2 \
--state=inactive
```

Delete:
```
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=mde-service-manager-patch-2
```

7.Delete the rsi-env-term-assignment-4.6.5-patch-2-april2024 patch
<br>
Inactivate:
```
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=rsi-env-term-assignment-4.6.5-patch-2-april2024 \
--state=inactive
```

Delete:
```
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=rsi-env-term-assignment-4.6.5-patch-2-april2024
```

8.Delete the term-assignment-env-patch-1-march2024 patch
<br>
Inactivate:
```
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=term-assignment-env-patch-1-march2024 \
--state=inactive
```

Delete:
```
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch_name=term-assignment-env-patch-1-march2024
```

### 1.2 Set up client workstation

#### 1.2.1 Prepare a client workstation

1. Prepare a RHEL 9 machine with internet

Create a directory for the cpd-cli utility.
```
export CPD511_WORKSPACE=/ibm/cpd/511
mkdir -p ${CPD511_WORKSPACE}
cd ${CPD511_WORKSPACE}

```

Download the cpd-cli for 5.1.1

```
wget https://github.com/IBM/cpd-cli/releases/download/v14.1.1/cpd-cli-linux-EE-14.1.1.tgz
```

2. Install tools.

```
yum install openssl httpd-tools podman skopeo wget -y
```

The version in below commands may need to be updated accordingly.

```
tar xvf cpd-cli-linux-EE-14.1.1.tgz
mv cpd-cli-linux-EE-14.1.1-1650/* .
rm -rf cpd-cli-linux-EE-14.1.1-1650
```

3. Copy the cpd_vars.sh file used by the CPD 4.8.5 to the folder ${CPD511_WORKSPACE}.

```
cd ${CPD511_WORKSPACE}
cp <the file path of the cpd_vars.sh file used by the CPD 4.8.5 > cpd_vars_511.sh
```
4. Make cpd-cli executable anywhere
```
vi cpd_vars_511.sh
```

Add below two lines into the head of cpd_vars_511.sh

```
export CPD511_WORKSPACE=/ibm/cpd/511
export PATH=${CPD511_WORKSPACE}:$PATH
```

Update the CPD_CLI_MANAGE_WORKSPACE variable

```
export CPD_CLI_MANAGE_WORKSPACE=${CPD511_WORKSPACE}
```

Run this command to apply cpd_vars_511.sh

```
source cpd_vars_511.sh
```

Check out with this commands

```
cpd-cli version
```

Output like this

```
cpd-cli
	Version: 14.1.1
	Build Date: 2025-02-20T18:45:49
	Build Number: 1650
	CPD Release Version: 5.1.1
```
5.Update the OpenShift CLI
<br>
Check the OpenShift CLI version.

```
oc version
```

If the version doesn't match the OpenShift cluster version, update it accordingly.

#### 1.2.2 Update environment variables for the upgrade to Version 5.1.1

```
vi cpd_vars_511.sh
```

1.Locate the VERSION entry and update the environment variable for VERSION. 

```
export VERSION=5.1.1
```

2.Locate the COMPONENTS entry and confirm the COMPONENTS entry is accurate.
```
export COMPONENTS=ibm-cert-manager,ibm-licensing,cpfs,cpd_platform,ws,ws_runtimes,wml,wkc,datastage_ent,datastage_ent_plus,analyticsengine,mantaflow,datalineage,openscale,db2wh
```

Save the changes. <br>

Confirm that the script does not contain any errors. 
```
bash ./cpd_vars_511.sh
```

Run this command to apply cpd_vars_511.sh
```
source cpd_vars_511.sh
```
3.Locate the Cluster section of the script and add the following environment variables.
```
export SERVER_ARGUMENTS="--server=${OCP_URL}"
export LOGIN_ARGUMENTS="--username=${OCP_USERNAME} --password=${OCP_PASSWORD}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${OCP_URL} ${LOGIN_ARGUMENTS}"
```

#### 1.2.3 Obtaining the olm-utils-v3 image
**Note:** If the bastion node is internet connected, then you can ignore below steps in this section.

```
podman pull icr.io/cpopen/cpd/olm-utils-v3:latest --tls-verify=false

podman login ${PRIVATE_REGISTRY_LOCATION} -u ${PRIVATE_REGISTRY_PULL_USER} -p ${PRIVATE_REGISTRY_PULL_PASSWORD}

podman tag icr.io/cpopen/cpd/olm-utils-v3:latest ${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v3:latest

podman push ${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v3:latest --remove-signatures 

export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v3:latest
export OLM_UTILS_LAUNCH_ARGS=" --network=host"

```
For details please refer to IBM documentation [Obtaining the olm-utils-v3 image](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=pruirn-obtaining-olm-utils-v3-image)

#### 1.2.4 Ensure the cpd-cli manage plug-in has the latest version of the olm-utils image
```
cpd-cli manage restart-container
```
**Note:**
<br>Check and confirm the olm-utils-v3 container is up and running.
```
podman ps | grep olm-utils-v3
```

#### 1.2.5 Ensure the images were mirrored to the private container registry
- Check the log files in the work directory generated during the image mirroring
```
grep "error" ${CPD_CLI_MANAGE_WORKSPACE}/work/mirror_*.log
```
- Log in to the private container registry.
```
cpd-cli manage login-private-registry \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PULL_USER} \
${PRIVATE_REGISTRY_PULL_PASSWORD}
```
- Confirm that the images were mirrored to the private container registry:
Inspect the contents of the private container registry:
```
cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--case_download=false
```
The output is saved to the list_images.csv file in the work/offline/${VERSION} directory.<br>
Check the output for errors:
```
grep "level=fatal" ${CPD_CLI_MANAGE_WORKSPACE}/work/offline/${VERSION}/list_images.csv
```
The command returns images that are missing or that cannot be inspected which needs to be addressed.

#### 1.2.6 Creating a profile for upgrading the service instances
Create a profile on the workstation from which you will upgrade the service instances. <br>

The profile must be associated with a Cloud Pak for Data user who has either the following permissions:

- Create service instances (can_provision)
- Manage service instances (manage_service_instances)

Click this link and follow these steps for getting it done. 

[Creating a profile to use the cpd-cli management commands](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=cli-creating-cpd-profile)


### 1.3 Health check OCP & CPD

1. Check OCP status

Log onto bastion node, in the termial log into OCP and run this command.

```
oc get co
```

Make sure All the cluster operators should be in AVAILABLE status. And not in PROGRESSING or DEGRADED status.

Run this command and make sure all nodes in Ready status.

```
oc get nodes
```

Run this command and make sure all the machine configure pool are in healthy status.

```
oc get mcp
```

2. Check Cloud Pak for Data status

Log onto bastion node, and make sure IBM Cloud Pak for Data command-line interface installed properly.

Run this command in terminal and make sure the Lite and all the services' status are in Ready status.
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

3. Check private container registry status if installed

Log into bastion node, where the private container registry is usually installed, as root.
Run this command in terminal and make sure it can succeed.

```
podman login --username $PRIVATE_REGISTRY_PULL_USER --password $PRIVATE_REGISTRY_PULL_PASSWORD $PRIVATE_REGISTRY_LOCATION --tls-verify=false
```

You can run this command to verify the images in private container registry.

```
curl -k -u ${PRIVATE_REGISTRY_PULL_USER}:${PRIVATE_REGISTRY_PULL_PASSWORD} https://${PRIVATE_REGISTRY_LOCATION}/v2/_catalog?n=6000 | jq .
```

## Part 2: Upgrade
### 2.1 Upgrade CPD to 5.1.1

#### 2.1.1 Upgrading shared cluster components
1.Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```
2.Confirm the project which the License Service is in.
Run the following command:
```
oc get deployment -A |  grep ibm-licensing-operator
```
Make sure the project returned by the command matches the environment variable PROJECT_LICENSE_SERVICE in your environment variables script `cpd_vars_511.sh`.
<br>

3.Upgrade the Certificate manager and License Service.
```
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--cert_manager_ns=${PROJECT_CERT_MANAGER} \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```
**Note**:
<br><br>Monitor the install plan and approved them as needed.
<br>
In another terminal, keep running below command and monitoring "InstallPlan" to find which one need manual approval.
```
watch "oc get ip -n ${PROJECT_CPD_INST_OPERATORS} -o=jsonpath='{.items[?(@.spec.approved==false)].metadata.name}'"
```
Approve the upgrade request and run below command as soon as we find it.
```
oc patch installplan $(oc get ip -n ${PROJECT_CPD_INST_OPERATORS} -o=jsonpath='{.items[?(@.spec.approved==false)].metadata.name}') -n ${PROJECT_CPD_INST_OPERATORS} --type merge --patch '{"spec":{"approved":true}}'
```

<br>Confirm that the Certificate manager pods in the ${PROJECT_CERT_MANAGER} project are Running:
```
oc get pod -n ${PROJECT_CERT_MANAGER}
```
Confirm that the License Service pods are Running or Completed::
```
oc get pods --namespace=${PROJECT_LICENSE_SERVICE}
```

#### 2.1.2 Preparing to upgrade the CPD instance to IBM Software Hub
1.Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```
2.Applying your entitlements to monitor and report use against license terms
<br>
**Non-Production enironment**
<br>
Apply the IBM Cloud Pak for Data Enterprise Edition for the non-production environment.

```
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=cpd-enterprise \
--production=false
```

Reference: <br>

[Applying your entitlements](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=puish-applying-your-entitlements)

#### 2.1.3 Upgrading to IBM Software Hub

1.Run the cpd-cli manage login-to-ocp command to log in to the cluster.
```
${CPDM_OC_LOGIN}
```
2.Review the license terms for the software that is installed on this instance of IBM Software Hub.
<br>
The licenses are available online. Run the appropriate commands based on the license that you purchased:
```
cpd-cli manage get-license \
--release=${VERSION} \
--license-type=EE
```
3.Upgrade the required operators and custom resources for the instance.
```
cpd-cli manage setup-instance \
--release=${VERSION} \
--license_acceptance=true \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--run_storage_tests=true
```
In another terminal, keep running below command and monitoring "InstallPlan" to find which one need manual approval.
```
watch "oc get ip -n ${PROJECT_CPD_INST_OPERATORS} -o=jsonpath='{.items[?(@.spec.approved==false)].metadata.name}'"
```
Approve the upgrade request and run below command as soon as we find it.
```
oc patch installplan $(oc get ip -n ${PROJECT_CPD_INST_OPERATORS} -o=jsonpath='{.items[?(@.spec.approved==false)].metadata.name}') -n ${PROJECT_CPD_INST_OPERATORS} --type merge --patch '{"spec":{"approved":true}}'
```

Once the above command `cpd-cli manage setup-instance` complete, make sure the status of the IBM Software Hub is in 'Completed' status.
```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \ 
--components=cpd_platform
```

4.Create a custom route

<br>

- Changing the hostname of the route

<br>

Ensure the `custom_hostname` and `route_secret` are set properly before running belwo command.

```
cpd-cli manage setup-route \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--custom_hostname=datacatalog-test.ebiz.verizon.com \
--route_type=passthrough \
--route_secret=cpd-tls-secret
```

[Create a custom route using cpd-cli](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=manage-setup-route)

#### 2.1.4 Upgrade the operators for the services

```
cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--upgrade=true
```

In another terminal, keep running below command and monitoring "InstallPlan" to find which one need manual approval.
```
watch "oc get ip -n ${PROJECT_CPD_INST_OPERATORS} -o=jsonpath='{.items[?(@.spec.approved==false)].metadata.name}'"
```
Approve the upgrade request and run below command as soon as we find it.
```
oc patch installplan $(oc get ip -n ${PROJECT_CPD_INST_OPERATORS} -o=jsonpath='{.items[?(@.spec.approved==false)].metadata.name}') -n ${PROJECT_CPD_INST_OPERATORS} --type merge --patch '{"spec":{"approved":true}}'
```

Confirm that the operator pods are Running or Copmleted:
```
oc get pods --namespace=${PROJECT_CPD_INST_OPERATORS}
```
Check the version for both CSV and Subscription and ensure the CPD Operators have been upgraded successfully.
```
oc get csv,sub -n ${PROJECT_CPD_INST_OPERATORS}
```

[Operator and operand versions](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=planning-operator-operand-versions)

<br>

Increase the resource limits of the CCS operator for avoiding potention problems when dealing with large data volume.

<br>

Have a backup of the CCS CSV yaml file.

```
oc get csv ibm-cpd-ccs.v10.1.0 -n ${PROJECT_CPD_INST_OPERATORS} -o yaml > ibm-cpd-ccs-csv-511.yaml
```

Edit the CCS CSV:

```
oc edit csv ibm-cpd-ccs.v10.1.0 -n ${PROJECT_CPD_INST_OPERATORS} 
```

Make changes to the limits like below.

```
    resources:
      limits:
        cpu: 4
        ephemeral-storage: 5Gi
        memory: 8Gi
```

This change can be reverted after the upgrade completed successfully.

#### 2.1.5 Applying the RSI patches

1).Log the cpd-cli in to the Red Hat OpenShift Container Platform cluster.
```
${CPDM_OC_LOGIN}
```
2).Run the following command to re-apply your existing custom patches.
```
cpd-cli manage apply-rsi-patches \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
3).Creat new patches required for migrating profiling results
<br>
a).Identify the location of the `work` directory and create the `rsi` folder under it.

```
podman inspect olm-utils-play-v3 | grep -i -A5  mounts
```

The `Source` property value in the output is the location of the `work` directory.

```
  "Mounts": [
       {
            "Type": "bind",
            "Source": "/ibm/cpd/511/work",
            "Destination": "/tmp/work",
            "Driver": "",
```

For example, `/ibm/cpd/511/work` is the location of the `work` directory.

<br>

Create the `rsi` folder. **Note: Change the value for the environment variable `CPD_CLI_WORK_DIR` based on the location of the `work` directory.** 
```
export CPD_CLI_WORK_DIR=/ibm/cpd/511/work
mkdir -p $CPD_CLI_WORK_DIR/rsi
```

b).Create a json patch file named `annotation-spec.json` under the `rsi` directory with the following content:

```
[{"op":"add","path":"/metadata/annotations/io.kubernetes.cri-o.TrySkipVolumeSELinuxLabel","value":"true"}]
```

c).Create a json patch file named `specpatch.json` under the `rsi` directory with the following content:

```
[{"op":"add","path":"/spec/runtimeClassName","value":"selinux"}]
```

d).Create the annotation patch for wdp profiling postgres migration pods.

```
cpd-cli manage create-rsi-patch --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --patch_type=rsi_pod_annotation --patch_name=prof-pg-migration-annotation-selinux --description="This is annotation patch is for selinux relabeling disabling on CSI based storages for wdp profiling postgres migration pods" --include_labels=job-name:wdp-profiling-postgres-migration --state=active --spec_format=json --patch_spec=/tmp/work/rsi/annotation-spec.json
```

e).Create the spec patch for wdp profiling postgres migration pods.

```
cpd-cli manage create-rsi-patch --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --patch_type=rsi_pod_spec --patch_name=prof-pg-migration-runtimes-pod-spec-selinux --description="This is spec patch is for selinux relabeling disabling on CSI based storages for wdp profiling postgres migration pods" --include_labels=job-name:wdp-profiling-postgres-migration --state=active --spec_format=json --patch_spec=/tmp/work/rsi/specpatch.json
```
4).Creat new CouchDB patches for addressing time-consuming PVC mounting issue.
<br>
a).Create the annotation patch for CouchDb.

```
cpd-cli manage create-rsi-patch --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
  --patch_type=rsi_pod_annotation \
  --patch_name=couchdb-pod-annotation-selinux \
  --description="This annotation patch is for selinux relabeling disabling on CSI based storages for couchdb" \
  --include_labels=app:couchdb \
  --state=active \
  --spec_format=json \
  --patch_spec=/tmp/work/rsi/annotation-spec.json
```

b).Create the spec patch for CouchDb.

```
cpd-cli manage create-rsi-patch --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
  --patch_type=rsi_pod_spec \
  --patch_name=couchdb-pod-spec-selinux \
  --description="This spec patch is for selinux relabeling disabling on CSI based storages for couchdb" \
  --include_labels=app:couchdb \
  --state=active \
  --spec_format=json \
  --patch_spec=/tmp/work/rsi/specpatch.json
```

5).Check the RSI patches status again:
```
cpd-cli manage get-rsi-patch-info --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --all

cat $CPD_CLI_WORK_DIR/get_rsi_patch_info.log
```

### 2.2 Upgrade CPD services to 5.1.1
#### 2.2.1 Upgrading IBM Knowledge Catalog service and apply customizations
Check if the IBM Knowledge Catalog service was installed with the custom install options. 
##### 1. For custom installation, check the previous install-options.yaml or wkc-cr yaml, make sure to keep original custom settings
Specify the following options in the `install-options.yml` file in the `work` directory. Create the `install-options.yml` file if it doesn't exist in the `work` directory.

```
################################################################################
# IBM Knowledge Catalog parameters
################################################################################
custom_spec:
  wkc:
    enableKnowledgeGraph: True
    enableDataQuality: True
    useFDB: True
```

**Note:**
<br>
1)Make sure you edit or create the `install-options.yml` file in the right `work` folder. 

<br>

Identify the location of the `work` folder using below command.

```
podman inspect olm-utils-play-v3 | grep -i -A5  mounts
```

The `Source` property value in the output is the location of the `work` folder.

<br>

2)Make sure the `useFDB` is set to be `True` in the install-options.yml file.
<br>

##### 2.Upgrade WKC with custom installation

Run the cpd-cli manage login-to-ocp command to log in to the cluster.

```
${CPDM_OC_LOGIN}
```

Update the custom resource for IBM Knowledge Catalog.
```
cpd-cli manage apply-cr \
--components=wkc \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--param-file=/tmp/work/install-options.yml \
--license_acceptance=true \
--upgrade=true
```

##### 3.Validate the upgrade
```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

##### 4.Apply the customizations 
**1).Apply the change for supporting CyberArk Vault with a private CA signed certificate**: <br>

```
oc patch ZenService lite-cr -n ${PROJECT_CPD_INST_OPERANDS} --type merge -p '{"spec":{"vault_bridge_tls_tolerate_private_ca": true}}'
```

**2)Combined CCS patch command** (Reducing the number of operator reconcilations): <br>

- Configuring reporting settings for IBM Knowledge Catalog.

```
oc patch configmap ccs-features-configmap -n ${PROJECT_CPD_INST_OPERANDS} --type=json -p='[{"op": "replace", "path": "/data/enforceAuthorizeReporting", "value": "false"},{"op": "replace", "path": "/data/defaultAuthorizeReporting", "value": "true"}]'
```

- Apply the patch for 1)asset-files-api deployment tuning and 2)Couchdb search container resource tuning

```
oc patch ccs ccs-cr -n ${PROJECT_CPD_INST_OPERANDS} --type=merge -p '{"spec":{"asset_files_call_socket_timeout_ms": 60000,"asset_files_api_resources": {"limits": {"cpu": "4", "memory": "32Gi", "ephemeral-storage": "1Gi"}, "requests": {"cpu": "200m", "memory": "256Mi", "ephemeral-storage": "10Mi"}}, "asset_files_api_replicas": 6,"asset_files_api_command":["/bin/bash"], "asset_files_api_args":["-c","cd /home/node/${MICROSERVICENAME}; source /scripts/exportSecrets.sh; export npm_config_cache=~node; node --max-old-space-size=12288 --max-http-header-size=32768 index.js"]}}'
```

**3)Combined WKC patch command** (Reducing the number of operator reconcilations): <br>

- Figure out a proper PVC size for the PostgreSQL used by profiling migration.
<br>
Check the asset-files-api pvc size. Specify the same or a bigger storage size for preparing the postgresql with the proper storage size to accomendate the profiling migration.
<br>
Get the file-api-claim pvc size.

```
oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} | grep file-api-claim | awk '{print $4}'
```

Specify the same or a bigger storage size for postgres storage accordingly in next step.

- Patch the WKC : a)Setting a proper PVC size for PostgreSQL (profiling db) and b) WKC BI Data hotfix
  
```
oc patch wkc wkc-cr -n ${PROJECT_CPD_INST_OPERANDS} --type=merge -p '{"spec":{"wdp_profiling_edb_postgres_storage_size":"100Gi","image_digests":{"wkc_bi_data_service_image":"sha256:34d2c0977dfa7de1f8efed425eb2bca2ec2b4bd0188454c799b081013af4c34f"}}}'

```

#### 2.2.2 Upgrading MANTA service
```
export COMPONENTS=mantaflow

```

- Run the cpd-cli manage login-to-ocp command to log in to the cluster.

```
${CPDM_OC_LOGIN}
```

- Run the command for upgrading MANTA service.

```
cpd-cli manage apply-cr \
--components=mantaflow \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true \
--upgrade=true
```

Validating the upgrade.
```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=mantaflow
```

#### 2.2.3 Upgrading Analytics Engine service
##### 2.2.3.1 Upgrading the service

Check the Analytics Engine service version and status. 
```
export COMPONENTS=analyticsengine

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}
```

The Analytics Engine serive should have been upgraded as part of the WKC service upgrade. If the Analytics Engine service version is **not 5.1.1**, then run below commands for the upgrade. <br>

Check if the Analytics Engine service was installed with the custom install options. <br>

```
cpd-cli manage apply-cr \
--components=analyticsengine \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true \
--upgrade=true
```

Validate the service upgrade status.
```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}
```

##### 2.2.3.2 Upgrading the service instances

**Note:**  cpd profile api key may expire after upgrade. If we are not able to list the instances, should be attempted once the Custom route is created so that the Admin can login. 
<br>
Find the proper CPD user profile to use.
```
cpd-cli config profiles list
```

Upgrade the Spark service instance
```
cpd-cli service-instance upgrade \
--service-type=spark \
--profile=${CPD_PROFILE_NAME} \
--all
```

Validate the service instance upgrade status.
```
cpd-cli service-instance list \
--service-type=spark \
--profile=${CPD_PROFILE_NAME}
```
#### 2.2.4 Upgrading Watson Studio, Watson Studio Runtimes, Watson Machine Learning and OpenScale
```
export COMPONENTS=ws,ws_runtimes,wml,openscale
```
Run the cpd-cli manage login-to-ocp command to log in to the cluster.

```
${CPDM_OC_LOGIN}
```

Run the upgrade command.
```
cpd-cli manage apply-cr \
--components=${COMPONENTS}  \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true \
--upgrade=true
```

Validate the service upgrade status.
```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}
```

#### 2.2.5 Upgrading Db2 Warehouse
```
export COMPONENTS=db2wh
```
Run the cpd-cli manage login-to-ocp command to log in to the cluster.

```
${CPDM_OC_LOGIN}
```

Run the upgrade command.
```
cpd-cli manage apply-cr \
--components=db2wh \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true \
--upgrade=true
```

Validate the service upgrade status.
```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}
```

Upgrading Db2 Warehouse service instances:
<br>
- Get a list of your Db2 Warehouse service instances

```
cpd-cli service-instance list \
--service-type=db2wh \
--profile=${CPD_PROFILE_NAME}
```

- Upgrade Db2 Warehouse service instances
<br>
Run the following command to check whether your Db2 Warehouse service instances is in running state(You can refer to the web console for getting the service instance name) :

```
cpd-cli service-instance status ${INSTANCE_NAME} \ 
--profile=${CPD_PROFILE_NAME} \ 
--service-type=db2wh
```

Upgrade the service instance:
```
cpd-cli service-instance upgrade --profile=${CPD_PROFILE_NAME} --instance-name=${INSTANCE_NAME} --service-type=${COMPONENTS}
```

Verifying the service instance upgrade

```
oc get db2ucluster <instance_id> -o jsonpath='{.status.state} {"\n"}'
```

Repeat the preceding steps to upgrade each service instance associated with this instance of IBM Software Hub.

- Check the service instances have updated

```
cpd-cli service-instance list \ 
--profile=${CPD_PROFILE_NAME} \
--service-type=db2wh
```

## Part 3: Post-upgrade

### 3.1 Validate the external vault connection setting 
1)Validate and ensure the patch for external vault connection applied.

<br>

Found out the following variables set to false
```
oc set env deployment/zen-core-api --list | grep -i vault
```
The values are true like this:
```
VAULT_BRIDGE_TOLERATE_SELF_SIGNED=true
VAULT_BRIDGE_TLS_RENEGOTIATE=true
```

2)Add Verizon logo on CPD homepage

<br>

[Customizing the branding of the web client](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=users-customizing-branding-web-client)

### 3.2 CCS post-upgrade tasks
**1.Check if uploading JDBC drivers enabled**
```
oc get ccs ccs-cr -o yaml | grep -i wdp_connect_connection_jdbc_drivers_repository_mode
```
Make sure the `wdp_connect_connection_jdbc_drivers_repository_mode` parameter set to be enabled.

**2.Check the heap size in asset-files-api deployment**
<br>
Check if the heap size 12288 is set as expected.
```
oc get deployment asset-files-api -o yaml | grep -i -A5 'max-old-space-size=12288'
```

### 3.3 WKC post-upgrade tasks

**1.Validate the 'Allow Reporting' settings for Catalogs and Projects**
<br>
1)Check the Reporting settings in the ccs-features-configmap.

```
oc get configmaps ccs-features-configmap -o yaml -n ${PROJECT_CPD_INST_OPERANDS} | grep -i reporting
```

The following output is expected:
```
defaultAuthorizeReporting: "true"
enforceAuthorizeReporting: "false"
```

2)Verify that the environemnt variable is set for ngp-projects-api.

```
oc set env -n ${PROJECT_CPD_INST_OPERANDS} deployment/ngp-projects-api --list | grep -i reporting
```

The following output is expected:

```
DEFAULT_AUTHORIZE_REPORTING=True
ENFORCE_AUTHORIZE_REPORTING=False
```

3)Verify that the environment variable is set for catalog-api

```
oc exec -it $(oc get pods --no-headers | grep -i catalog-api- | head -n 1 | awk '{print $1}') -- env | grep -i reporting

```

The following output is expected:

```
defaultAuthorizeReporting=true
enforceAuthorizeReporting=false
```

If any of the above output inconsistent with the expected ones, then follow below documentation for applying 'Allow Reporting' settings. 

<br>

[Configuring reporting settings for IBM Knowledge Catalog](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=administering-configuring-reporting-settings)

**2.Bulk sync assets for global search**
<br>
As we aim to have bulk re-sync run in the background of the day to day operations, let's tweak concurrency to a level that allows for adequate throughput for the rest of the wkc-search clients.

<br>

1)Switch to the CPD instance project.

```
oc project ${PROJECT_CPD_INST_OPERANDS}
```

2)Create a script named `wkc-search-reindexing-concurrency-tweak.sh` with the following content.

```
# Modify these parameters to tweak the degree of concurrency #
export writer_max_concurrency_threshold=1
export writer_average_concurrency_threshold=0
export elasticsearch_bulk_size=1000
export max_processing_rate=1000
##############################################################

# Extracts CM as json, extracts json config as pure json
oc get cm wkc-search-search-sync-columns-cm -ojson > wkc-search-search-sync-columns-cm.json
cat wkc-search-search-sync-columns-cm.json | jq '.data["config.json"]' > config.json
cat config.json | sed "s/\\\n//g" | sed 's/\\"/TTT/g' | sed 's/"//g' | sed 's/TTT/"/g' | sed 's/\\t//g' | jq > config.json_tmp
mv config.json_tmp config.json

# Modify json config with desired parameters
jq ".asset_flow.processors.asset_processor.configuration.writer_max_concurrency_threshold = \"$writer_max_concurrency_threshold\" | .asset_flow.processors.asset_processor.configuration.writer_average_concurrency_threshold = \"$writer_average_concurrency_threshold\" | .asset_flow.processors.asset_processor.configuration.max_processing_rate = \"$max_processing_rate\" | .asset_flow.processors.asset_processor.writer.configuration.elasticsearch_bulk_size = \"$elasticsearch_bulk_size\"" config.json > config2.json
mv config2.json config.json

# Prepare original CM with updated data
export config_json=$(cat config.json | jq --compact-output | sed 's/"/\\"/g')
jq ".data[\"config.json\"]=\"$config_json\"" wkc-search-search-sync-columns-cm.json > wkc-search-search-sync-columns-cm.json_tmp
mv wkc-search-search-sync-columns-cm.json_tmp wkc-search-search-sync-columns-cm.json

# Update CM
oc apply -f wkc-search-search-sync-columns-cm.json

```

3)Run the `wkc-search-reindexing-concurrency-tweak.sh` script

```
chmod +x wkc-search-reindexing-concurrency-tweak.sh

./wkc-search-reindexing-concurrency-tweak.sh
```

4)Run bulk script cpd_gs_sync.sh following this documentation [Bulk sync assets for global search](https://www.ibm.com/docs/en/SSNFH6_5.1.x/wsj/admin/admin-bulk-sync.html).
<br>

**Note**

<br>
- If there are a large number of assets, the wkc-search-reindexing-job may take a few hours to complete. You can monitor the status with below command.

```
oc logs $(oc get pods --no-headers | grep -i wkc-search-reindexing-job- | head -n 1 | awk '{print $1}') | grep "CAMSStatisticsCollector reports" -A10
```

<br>

- Be aware that the changes will be overwritten after a CCS reconcile cycle, so if you are planning to run bulk with tweaked concurrency parameters - its adviced to always apply the above script beforehand.
  
<br>

**3.Add potential missing permissions for the pre-defined Data Quality Analyst and Data Steward roles**
<br>

```
oc delete pod $(oc get pod -n ${PROJECT_CPD_INST_OPERANDS} -o custom-columns="Name:metadata.name" -l app.kubernetes.io/component=zen-watcher --no-headers) -n ${PROJECT_CPD_INST_OPERANDS}
```

**4. Migrating profiling results after upgrading**
<br>
In Cloud Pak for Data 5.1.1, profiling results are stored in a PostgreSQL database instead of the asset-files storage. To make existing profiling results available after upgrading from an earlier release, migrate the results following this IBM documentation.
[Migrating profiling results after upgrading](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=administering-migrating-profiling-results)

<br>

Sample override.yaml file:

```
namespace: cpd
blockStorageClass: ocs-storagecluster-ceph-rbd
fileStorageClass: ocs-storagecluster-cephfs
docker_registry_prefix: cp.icr.io/cp/cpd
use_dynamic_provisioning: true
ansible_python_interpreter: /usr/bin/python3
allow_reconcile: true
wdp_profiling_postgres_action: MIGRATE
```

**Note**
<br>
1).The nohup command is recommended for the migration of a large number of records.
```
nohup ansible-playbook /opt/ansible/5.1.1/roles/wkc-core/wdp_profiling_postgres_migration.yaml --extra=@/tmp/override.yaml -vvvv &
```

2).Validate the job log for successful migration of profiling data; then run the `CLEAN` option.
<br>
**Important:** The data is permanently deleted and can't be restored. Therefore, use this option only after all results are copied successfully and you do no longer need the results in the asset-files storage. So recommend taking a note of this procedure and run it after the tests passed from the end-users.

## Part 4: Maintenance
This part is beyond the upgrade scope. And we are not commited to complete them in the two days time window.
### 4.1 Migrating from MANTA Automated Data Lineage to IBM Manta Data Lineage
#### 4.1.1 Uninstall MANTA Automated Data Lineage
- Log the cpd-cli in to the Red Hat® OpenShift® Container Platform cluster.

```
${CPDM_OC_LOGIN}
```

- Delete the custom resource for MANTA Automated Data Lineage.

```
cpd-cli manage delete-cr \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=mantaflow \
--include_dependency=true
```

Wait for the cpd-cli to return the following message before you proceed to the next step:
```
[SUCCESS]... The delete-cr command ran successfully
```

- Delete the OLM objects for MANTA Automated Data Lineage:
```
cpd-cli manage delete-olm-artifacts \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--components=mantaflow
```

Wait for the cpd-cli to return the following message:

```
[SUCCESS]... The delete-olm-artifacts command ran successfully
```

#### 4.1.2 Install the IBM Manta Data Lineage

- Log the cpd-cli in to the Red Hat® OpenShift® Container Platform cluster.

```
${CPDM_OC_LOGIN}
```

- Run the following command to create the required OLM objects for IBM Manta Data Lineage .

```
cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--components=datalineage
```

Wait for the cpd-cli to return the following message before you proceed to the next step:

```
[SUCCESS]... The apply-olm command ran successfully
```

- Create the custom resource for IBM Manta Data Lineage.

```
cpd-cli manage apply-cr \
--components=datalineage \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true
```

Validating the upgrade.
```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=datalineage
```

Set the scale to be `Large`.
```
export SCALE=level_4
```

Run the following command to scale the component by updating the custom resource.
```
cpd-cli manage apply-scale-config \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=datalineage \
--scale=${SCALE}
```

- Make IBM Knowledge Catalog using Neo4j as the knowledge graph database

<br>
Delete the fdbcluster.

```
oc delete fdbcluster wkc-foundationdb-cluster -n ${PROJECT_CPD_INST_OPERANDS}
```
Patch the wkc-cr to deploy the Neo4j cluster.

```
oc patch wkc wkc-cr -n ${PROJECT_CPD_INST_OPERANDS} --type=merge -p '{"spec":{"useFDB":false}}'
```

Wait until the WKC operator reconcilation fineshed and wkc-cr becomes 'Completed'.

```
watch -n 60 "cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=wkc,datalineage"
```

Ensure the Neo4jCluster is in 'Completed' status.

```
oc get Neo4jCluster data-lineage-neo4j -n ${PROJECT_CPD_INST_OPERANDS}
```

- Apply the workaround for addressing the issue "TS018466973 - Lineage Tab page is keep on spinning."
Refer to the detailed steps updated by Sanjit 2/17/2025 in the ticket.


#### 4.1.3 Migrating from MANTA Automated Data Lineage to IBM Manta Data Lineage

**Note** 
<br>

- Migration needs to be run as root or by a user with sudo access.

[Migrating from MANTA Automated Data Lineage to IBM Manta Data Lineage](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=lineage-migrating)

### 4.2 Changing Db2 configuration settings
1.Run the following command to edit the Db2uCluster custom resource:
```
oc edit db2ucluster db2oltp-wkc -n ${PROJECT_CPD_INST_OPERANDS}
```
2.Change the following database configuration parameters.
<br>
To find your database configuration parameters, see the yaml path `spec.environment.database.dbConfig`.
Under the key dbConfig, you can add or edit below key-value pairs. Values must be enclosed in quotation marks.
```
spec:
  environment:
    database:
      dbConfig:
        LOGFILSIZ: "30000"
        LOGPRIMARY: "40"
        LOGSECOND: "60"
        CATALOGCACHE_SZ: "567"
```

**Note**
<br>
It's recommended getting this done by following the configuration settings in the Production environment.
<br>
[Changing Db2 configuration settings](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=configuration-changing-db2-settings)

### 4.3 Configure the idle session timeout
Update TOKEN_EXPIRY_TIME and TOKEN_REFRESH_PERIOD variables from 4 to 12 hours.
 - oc edit configmap product-configmap ......
 - Restart the usermgmt pods

[Setting the idle session timeout](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=environment-setting-idle-session-timeout)

### 4.4 Increasing the number of nginx worker connections

```
export WORKER_CONNECTIONS=4096

oc patch configmap product-configmap \
--namespace ${PROJECT_CPD_INST_OPERANDS} \
--type=merge \
--patch "{\"data\": {\"GATEWAY_WORKER_CONNECTIONS\":\"${WORKER_CONNECTIONS}\"}}"
```

[Reference](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=platform-increasing-number-nginx-worker-connections)

### 4.5 Increase ephemeral storage for zen-watchdog-serviceability-job
1)Keep a copy of the product-configmap CM.
2)Update the product-configmap for zen_diagnostics with below command.
```
oc edit configmap product-configmap
```
Add the zen_diagnostics sections as follows.
```
data:
  zen_diagnostics: |
    name: zen-diagnostics
    kind: Job
    container: zen-watchdog-serviceability-job-container
    resources:
      limits:
        cpu: 1
        ephemeral-storage: 35000Mi
        memory: 4Gi
      requests:
        cpu: 500m
        ephemeral-storage: 500Mi
        memory: 512Mi
```
3)Restart zen-watchdog pod

### 4.6 Update wdp-lineage deployment for addressing the potential Db2 high CPU and Memory usage issue.

1)Put wkc-cr in maintenance mode.
```
oc patch wkc wkc-cr --type=merge --patch='{"spec":{"ignoreForMaintenance":true}}'
```

2)Edit the wdp-lineage deployment.

```
oc edit deploy wdp-lineage
```

Modify the property for `LS_IGNORED_ASSET_TYPES`. Append the value with:
```
,data_asset,connection,term_assignment_profile,directory_asset,data_definition,parameter_set,data_rule,data_rule_definition,data_intg_subflow,orchestration_flow,data_intg_build_stage,data_intg_cff_schema,data_intg_wrapped_stage,ds_match_specification,standardization_rule,ds_xml_schema_library,environment,data_intg_project_settings,data_intg_custom_stage,data_intg_data_set,physical_constraint,data_intg_java_library,data_intg_parallel_function,data_intg_ilogjrule,data_intg_file_set,data_intg_message_handler,notebook,data_transformation 
```

### 4.7 Apply the workaround for the problem - MDE Job failed with error "Deployment not found with given id"
<br>

1)Put analyticsengine-sample in maintenance mode.

```
oc patch analyticsengine analyticsengine-sample --type=merge --patch='{"spec":{"ignoreForMaintenance":true}}'
```

2)Edit the `spark-hb-deployment-properties` config map and add the property `deploymentStatusRetryCount=6`

```
oc edit cm spark-hb-deployment-properties
```

3)Make sure the property `deploymentStatusRetryCount=6` added successfully

```
oc get cm spark-hb-deployment-properties -o yaml | grep -i deploymentStatusRetryCount
```
### 4.8 Enable Data Lineage in UI and remove old "lineage" tab under asset (from TS018466973).
1) Take a backup of kg-config-map: `oc get cm kg-config-map -oyaml`
2) Edit kg-config-map: `oc edit cm kg-config-map`
```
apiVersion: v1
data:
  add-ons.json: |
    {
       "wkc-knowledgegraph":{    <=== change from "wkc-knowledgegraph-neo4j" to "wkc-knowledgegraph"
          "add_on_type": "component",
          "details":{
             "internal": true
          },
          "versions":{
             "5.1.0":{
                "state":"enabled"
             }
          }
       }
    }
kind: ConfigMap
metadata:
  creationTimestamp: "2024-02-05T00:37:53Z"
  labels:
    app: wdp-kg-ingestion-service
    app.kubernetes.io/instance: 0075-wkc-lite
    app.kubernetes.io/managed-by: Tiller
    app.kubernetes.io/name: wdp-kg-ingestion-service
    chart: wdp-kg-ingestion-service-chart
    helm.sh/chart: wdp-kg-ingestion-service-chart
    heritage: Tiller
    icpdata_addon: "true"
    icpdata_addon_version: 5.1.0-fdb       <=== change version from "5.1.0" to "5.1.0-fdb"
    icpdsupport/addOnId: wkc
    icpdsupport/app: api
    icpdsupport/module: wdp-kg-ingestion-service
    release: 0075-wkc-lite
  name: kg-config-map
  namespace: wkc
  ownerReferences:
  - apiVersion: wkc.cpd.ibm.com/v1beta1
    kind: Knowledgegraph
    name: knowledgegraph-cr
    uid: 1540d451-5736-45e2-9b9b-f6db88d7fcae
  - apiVersion: wkc.cpd.ibm.com/v1beta1
    kind: WKC
    name: wkc-cr
    uid: 3282e11f-3ef0-472b-948c-9d0098f2ca64
  resourceVersion: "1332043077"
  uid: bd8f77d0-4861-4cad-b84a-6e36d2368e3b
```
3) Delete the configmap: `oc delete cm kg-config-map`
4) Edit the backup copy of the yaml file
```
apiVersion: v1
data:
  add-ons.json: |
    {
       "wkc-knowledgegraph":{    <=== change from "wkc-knowledgegraph" to "wkc-knowledgegraph-neo4j"
          "add_on_type": "component",
          "details":{
             "internal": true
          },
          "versions":{
             "5.1.0":{
                "state":"enabled"
             }
          }
       }
    }
kind: ConfigMap
metadata:
  creationTimestamp: "2024-02-05T00:37:53Z"
  labels:
    app: wdp-kg-ingestion-service
    app.kubernetes.io/instance: 0075-wkc-lite
    app.kubernetes.io/managed-by: Tiller
    app.kubernetes.io/name: wdp-kg-ingestion-service
    chart: wdp-kg-ingestion-service-chart
    helm.sh/chart: wdp-kg-ingestion-service-chart
    heritage: Tiller
    icpdata_addon: "true"
    icpdata_addon_version: 5.1.0-fdb       <=== change version from "5.1.0-fdb" to "5.1.0"
    icpdsupport/addOnId: wkc
    icpdsupport/app: api
    icpdsupport/module: wdp-kg-ingestion-service
    release: 0075-wkc-lite
  name: kg-config-map
  namespace: wkc
  ownerReferences:
  - apiVersion: wkc.cpd.ibm.com/v1beta1
    kind: Knowledgegraph
    name: knowledgegraph-cr
    uid: 1540d451-5736-45e2-9b9b-f6db88d7fcae
  - apiVersion: wkc.cpd.ibm.com/v1beta1
    kind: WKC
    name: wkc-cr
    uid: 3282e11f-3ef0-472b-948c-9d0098f2ca64
  resourceVersion: "1332043077"
  uid: bd8f77d0-4861-4cad-b84a-6e36d2368e3b
```
5) Apply the changed yaml file: `oc apply -f <backup yaml>`
6) Restart the portal-catalog pods
7) Verify in CPD UI - Lineage "tab" and "button" status

### 4.9 Resync of lineage metadata
[Resynchronize your catalog metadata to start seeing the Knowledge Graph](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=administering-resync-lineage-metadata).

Complete catalog resynchronization after you upgrade to Version 5.1 from Version 4.7.3.

### 4.10 Resync for glossary assets
1) Get the token
```
curl -X POST \
  'https://<instance_route>/icp4d-api/v1/authorize'\
  -H 'Content-Type: application/json' \
  -d' { \
    "username":"<username>", \
    "password":"<password>" \
  }'
```

2) Run the resync for glossary assets
```
curl -k -X POST  -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" "https://$CPD_URL/v3/glossary_terms/admin/resync?artifact_type=all&sync_destinations=KNOWLEDGE_GRAPH" -d '{}'
```

### 4.11 Update default project list view from 200 to 5000 projects (SF TS018467023)
1) Put CCS  into maintenance mode:
```
oc patch -n ${CPD_INSTANCE_PROJECT} ccs ccs-cr --type merge --patch '{"spec": {"ignoreForMaintenance": true}}'
```
2) Edit the `portal-projects` deployment with new environment variable `TOTAL_PROJECT_THRESHOLD` values `5000`.
```
oc edit deploy -n ${CPD_INSTANCE_PROJECT} portal-projects
<add relevant env var to `env` section>
```

### 4.12 Configure dedicated nodes for CouchDB
Previously IBM Engineering suggested providing dedicated nodes for CouchDB to enhance performance. CPD 5.x offers greater control over placing CCS pods on specific nodes.
- Worker node size:
 CPU: 16
 Memory: 64Gi

- Current CouchDB resource:
 CouchDB container
  CPU: 8
  Memory: 12Gi

 Search container
  CPU: 2
  Memory: 4Gi
- Need to leave resource for OpenShift, Instana, Rock-ceph pods to be scheduled on dedicated nodes.

Here is the step for configuration:
1) Retrieve the name of the worker nodes that you want to dedicate to couchDb pods: `oc get nodes`
2) Taint 3 nodes with the "NoSchedule" effect and safely evict all of the pods from those nodes:
```
oc adm taint node <node_name> icp4data=dedicated-wdp-couchdb:NoSchedule --overwrite
oc adm cordon <node_name>
oc adm drain <node_name>
oc adm uncordon <node_name>
```
3) Label 3 nodes:
```
oc label node <node_name> icp4data=dedicated-wdp-couchdb --overwrite
```
4) Verify that nodes are labeled: `oc get node --show-labels`
5) Add tolerations to any pods that must run on all nodes. In this case,
IBM Storage Ceph must run on all nodes to provide the platform for software-defined storage.
The value for tolerations used is `dedicated-wdp-couchdb`.
Similarly need to add tolerations for Instana.
```
-------
oc edit cm -n openshift-storage rook-ceph-operator-config

...
apiVersion: v1
data:
...
 CSI_PLUGIN_TOLERATIONS: |-
  - key: icp4data
   operator: Equal
   value: "dedicated-wdp-couchdb"
   effect: NoSchedule
-------
```
6) Change CCS CR for use dedicated CouchDB resources.
```
oc patch ccs ccs-cr --type merge -p '{
 "spec": {
  "couchdb_node_selector": { "icp4data": "dedicated-wdp-couchdb"},
  "couchdb_tolerations": [{
    "effect": "NoSchedule",
    "key": "icp4data",
    "operator": "Equal",
    "value": "dedicated-wdp-couchdb"
   }
  ]
 }
}'
```
7) Change CPU and memory limit for couchdb pod:
```
oc patch ccs ccs-cr --type merge --patch '{"spec": {
"couchdb_resources":{
"requests":{"cpu": "3", "memory": "256Mi"}, "limits":{"cpu": "10", "memory": "40Gi"}
}}}'
```
### 4.13 Migrating Image Content Source Policy (ICSP) to an Image Digest Mirror Set
Starting in Red Hat OpenShift Container Platform Version 4.14, the image content source policy (ISCP) is replaced by the image digest mirror set. If you upgrade your environment from Red Hat OpenShift Container Platform Version 4.12 to Version 4.14 or Version 4.15 and you mirror images to a private container registry, you must migrate your existing IBM Cloud Pak for Data (CPD) image content source policy to an image digest mirror set.

1) Login to RedHat OpenShift Container Platform asauser withsuVicient permissions to complete the task.
2) Runthefollowingcommandtogetthenameoftheimagecontentsourcepolicies on your cluster: `oc get -A icsp`

The default name for the Cloud Pak for Data image content source policy is cloud- pak-for-data-mirror.

3) SettheCPD_ICSPenvironmentvariabletothenameoftheCloudPakfor Data image content source policy. The following command uses the default name as an example. Change it according to your environemnt: `export CPD_ICSP=cloud-pak-for-data-mirror`
4) SavetheimagecontentsourcepolicyasaYAMLfileonthecluster.Thefollowing command saves the YAML file to the current directory: `oc get icsp ${CPD_ICSP} -o yaml > ${CPD_ICSP}.yaml`

Use the following command to convert one or more ImageContentSourcePolicy YAML files to an ImageDigestMirrorSet YAML file:
```
oc adm migrate icsp <file_name>.yaml <file_name>.yaml <file_name>.yaml --dest-dir <path_to_the_directory>
```
where:
`<file_name>` - Specifies the name of the source ImageContentSourcePolicy YAML. You can list multiple file names.
`--dest-dir` - Optional: Specifies a directory for the output ImageDigestMirrorSet YAML. If unset, the file is written to the current directory.

Example: `oc adm migrate icsp ${CPD_ICSP}.yaml --dest-dir idms-files`
5) Converttheimagecontentsourcepolicytoanimagedigestmirrorset: `oc create -f idms-files/<file-name>.yaml`
6) Testthepullofanimagefromtheprivatecontainerregistry. 
7) Deletetheimagecontentsourcepolicy: `oc delete icsp ${CPD_ICSP}`

### 4.14 Predefined roles are missing permissions - SF TS018667576
After the upgrade from IBM Knowledge Catalog 4.7.x or 4.8.x to IBM Knowledge Catalog 5.1.x or IBM Knowledge Catalog Premium 5.1.x, some permissions are missing from Data Engineer, Data Quality Analyst, and Data Steward roles. Users with these roles might not be able to run metadata imports or access any governance artifacts.

Workaround: To add any missing permissions to the Data Engineer, Data Quality Analyst, and Data Steward roles, restart the zen-watcher pod by running the following command:
```
oc delete pod $(oc get pod -n ${PROJECT_CPD_INST_OPERANDS} -o custom-columns="Name:metadata.name" -l app.kubernetes.io/component=zen-watcher --no-headers) -n ${PROJECT_CPD_INST_OPERANDS}
```
### 4.15 Installing license key for Manta
#### Instructions for installing license key:
1) Choose the appropriate key for your installation.  If you are using 4.6.3 or later, use "license-IBM-unlimited-non-expiring-FIPS-compliant.key".  This will apply to most customers. If you are using 4.6.2 or older, use "license-IBM-unlimited-non-expiring-FIPS-non-compliant.key".
2) Rename your key to ìlicense.keyî
3) Install the license key

#### To input the license key into the Cloud Pak for Data config map.
1) Log into the infrastructure node of the openshift cluster 
2) Run the following command: `oc set data secret/manta-keys -n test --from-file=license.key=./license.key`
   where: license.key is the license file 
   <namespace> is the namespace where MANTA is deployed 

### 4.16 Gathering diagnostic job for CCS component fails with error 400
When running a diagnostic job for the Common Core Services component, it fails with error 400.
The problem is caused by conflicting versions of CCS being enabled in the internal metastore database.
As a workaround, connect to any zen-metastore-edb pod and perform a similar steps as follows: 
```
$ oc rsh zen-metastore-edb-1 bash

bash-5.1$ psql -U postgres -d zen
psql (14.11)
Type "help" for help.

zen=# select state,id from add_ons where type='ccs';
     state     |     id
---------------+-------------
 not_installed | ccs/2.5.0.0
 not_installed | ccs/3.5.1
 not_installed | ccs/3.5.2
 not_installed | ccs/3.5.3
 not_installed | ccs/3.5.5
 not_installed | ccs/4.0.2
 not_installed | ccs/4.0.4
 not_installed | ccs/4.0.6
 not_installed | ccs/4.0.7
 not_installed | ccs/4.5.1
 not_installed | ccs/4.5.3
 enabled       | ccs/6.5.0
 enabled       | ccs/8.5.0
(13 rows)

zen=# update add_ons set state='not_installed' where type='ccs' and id='ccs/6.5.0';
UPDATE 1

zen=# select state,id from add_ons where type='ccs';
     state     |     id
---------------+-------------
 not_installed | ccs/2.5.0.0
 not_installed | ccs/3.5.1
 not_installed | ccs/3.5.2
 not_installed | ccs/3.5.3
 not_installed | ccs/3.5.5
 not_installed | ccs/4.0.2
 not_installed | ccs/4.0.4
 not_installed | ccs/4.0.6
 not_installed | ccs/4.0.7
 not_installed | ccs/4.5.1
 not_installed | ccs/4.5.3
 not_installed | ccs/6.5.0
 enabled       | ccs/8.5.0
(13 rows)

zen=# \q

In the above scenario problem was related CCS but similar problem could happen with other services also. 

```


### 4.17 Upgrade the Backup & Restore service and application
**Note:** This will be done as a separate task in another maintenance time window.

**1.Updating the cpdbr service**
<br>

If you use IBM Fusion to back up and restore your IBM® Software Hub deployment, you must upgrade the cpdbr service after you upgrade IBM Cloud Pak® for Data Version 4.8 to IBM Software Hub Version 5.1.

[Updating the cpdbr service](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=data-updating-cpdbr-service)

<br>

**2.Upgrade the IBM Fusion application**
<br>
IBM Fusion team can help on this task.

## Summarize and close out the upgrade

1)Schedule a wrap-up meeting and review the upgrade procedure and lessons learned from it.

2)Evaluate the outcome of upgrade with pre-defined goals.

---

End of document
