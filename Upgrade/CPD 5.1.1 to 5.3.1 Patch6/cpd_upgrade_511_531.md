
# CPD Upgrade From 5.1.1 to 5.3.1 Patch 6

## Upgrade Context
- **OCP:** 4.16
- **CPD:** 5.1.1 → 5.3.1 Patch 6
- **Storage:** ODF
- **Components:** cpd_platform,wkc,analyticsengine,datastage,datalineage,ws,ws_runtimes,wml,openscale,db2wh
- **Airgapped:** Yes

# Table of Contents
- 1. Pre-upgrade
- 2. Upgrade
- 3. Post-upgrade tasks

# Pre-requisites

### 1. Backup of the cluster is done.

Backup your Cloud Pak for Data cluster before the upgrade.

**Note:**
Make sure there are no scheduled backups conflicting with the scheduled upgrade.

### 2. The image mirroring completed successfully

If a private container registry is in-use to host the IBM Software Hub software images, you must mirror the updated images from the IBM® Entitled Registry to the private container registry. 

### 3. The CASE files and cluster resource files downloaded successfully

Before upgrading IBM Software Hub platform or any services, you must download the required cluster‑scoped resources, such as ClusterRoles and ClusterRoleBindings—for the components you plan to upgrade. Ensure that these files are available on the bastion node for use during the upgrade.

### 4. The permissions required for the upgrade is ready

- Openshift cluster permissions
<br>An Openshift cluster administrator can complete all of the installation tasks.

- IBM Software Hub permissions
<br>The Cloud Pak for Data administrator role or permissions is required for upgrading the service instances.

- Permission to access the private image registry for pushing or pull images

- Red Hat pull secret for mirroring images of Red Hat Cert Manager

- Access to the Bastion node for executing the upgrade commands

### 5. A pre-upgrade health check is made to ensure the cluster's readiness for upgrade.

The OpenShift cluster, persistent storage, IBM Software Hub platform and services are in healthy status.

### 6. Migrating to Red Hat OpenShift certificate manager

The IBM Certificate manager is deprecated.

If the IBM Certificate manager (ibm-cert-manager) is installed on your cluster, refer to IBM Documentation to migrate your certificates from the IBM Certificate manager to the Red Hat OpenShift certificate manager (cert-manager Operator).

[Migrating from the IBM Certificate manager to the Red Hat OpenShift certificate manager](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading-migrating-red-hat-openshift-certificate-manager)

### 7. SAML provider should sign both SAML response and SAML assertion
This can avoid below error during logging in the CPD web console.
```
Error: Invalid document signature
    at SAML.validatePostResponseAsync (/usr/src/server-src/node_modules/@node-saml/node-saml/lib/saml.js:528:23)
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
```
### 8. Have a backup of the current LDAP configuration
- Find out the local admin user and password to prepare for the LDAP reconfiguration in the post-upgrade step
- Backup the current LDAP configuration because it will be unset as part of the upgrade.

# 1. Pre-upgrade

**Note:**
Sourcing the latest environment variables used this environment before proceeding with the following procedures. Here's an example:
```
source ./cpd_vars.sh
```

## 1.1 Pre-upgrade check

### 1.1.1 Checking the health of your cluster
#### Overall health check
```
${OC_LOGIN}
oc get nodes,co,mcp

${CPDM_OC_LOGIN}
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
cpd-cli health cluster
cpd-cli health nodes
cpd-cli health operators --operator_ns=${PROJECT_CPD_INST_OPERATORS} --control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
cpd-cli health operands --control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

#### Check the service instance status
```
ZEN_METASTORE_EDB_POD="$(
  oc get pods -n "${PROJECT_CPD_INST_OPERANDS}" \
    -l 'k8s.enterprisedb.io/instanceRole=primary,component=zen-metastore-edb' \
    --no-headers 2>/dev/null | awk 'NR==1{print $1}'
)"

if [[ -n "${ZEN_METASTORE_EDB_POD}" ]] && oc -n "${PROJECT_CPD_INST_OPERANDS}" get pod "${ZEN_METASTORE_EDB_POD}" >/dev/null 2>&1; then
  oc -n "${PROJECT_CPD_INST_OPERANDS}" exec -i "${ZEN_METASTORE_EDB_POD}" -- bash -lc \
    "PGPASSWORD='admin-password' psql -d zen -U postgres -c \"SELECT * FROM service_instances;\""
fi
```

### 1.1.2 Uninstall all hot fixes or customization if any

#### 1.1.2.1 Uninstal the CCS hotfix and update customization
<br>

Edit the CCS custom resource

```
oc edit ccs ccs-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

1)Remove the hot fix.

```
    image_digests:
      catalog_api_image: sha256:6ac5cb00390d96a66540029b08e5abb47cf52e6142d7613757b1c252b6a6ecb0
      catalog_api_jobs_image: sha256:29dbaa7d9b4e6c19424b05e35e31db7cee1d66c06a0d633e56f5ad96f5786dab
      portal_catalog_image: sha256:1259d1d359bf04008ca2c6de56d5d0cdada36bcb4fe711170de29924e974c3ae
      wdp_connect_connection_image: sha256:02826fa27eed4813f62bce2eccd66ee8ab17c2ee56df811551746d683aa7ae0f
      wdp_connect_connector_image: sha256:c85fcfadda98e2f7d193b12234dbec013105e50b9f59f157505c28f5e572edcc
      wdp_connect_flight_image: sha256:cda30760185008c723a87bd251f60cb6402f4814ee1523c99a167ad979c5919b
```

2)Patch for the catalog-api migration (add under the spec section)
```
use_semi_auto_catalog_api_migration: true
catalog_api_postgres_migration_threads: 8
catalog_api_migration_job_resources:
  requests:
    cpu: 6
    ephemeral-storage: 10Mi
    memory: 6Gi
  limits:
    cpu: 10
    ephemeral-storage: 6Gi
    memory: 10Gi
```
3)Patch for addressing the OpenSearch legacy index ((add under the spec section)
```
"opensearch_specify_image": true
"opensearch_base_image": "cp.icr.io/cp/opencontent-ibm-opensearch-base-9@sha256:90cf0fe4eae545a0edb7d9a7e1938ab8614878a6aae15e1c646d9889d9bb8e36"
"opensearch_min_image": "cp.icr.io/cp/opencontent-ibm-opensearch-min-2.19.5@sha256:3727b0dbb62a45b23bf5ef1875e31fdd1703678d7d0cf98c33fd1140f0b8b122"
"opensearch_plugins_image": "cp.icr.io/cp/opencontent-ibm-opensearch-plugins-2.19.5@sha256:13807cdfae122b69d05bb842cee75f481bab2b176db6c1fd34887e84ef51963b"
"opensearch_knn_image": "cp.icr.io/cp/opencontent-ibm-opensearch-plugin-knn-2.19.5.0@sha256:63308f465cce0ab70fc7772630d40178a7b229d351a3bb705315af3f2e217858"
"opensearch_security_image": "cp.icr.io/cp/opencontent-ibm-opensearch-plugin-security-2.19.5.0@sha256:6183b3387094aec682539e88e2ef501779cd2e2c9ce5bb1a911029d1972a180e"
"opensearch_legacy_core_version": "2.19.5"
"opensearch_legacy_plugin_version": "2.19.5.0"
"opensearch_core_version": "2.19.5"
"opensearch_plugin_version": "2.19.5.0"
```
4)Remove from maintenance mode.
```
    ignoreForMaintenance: false
```

Save and exit.

<br>

Wait until the CCS Operator reconcilation completed and also the ccs-cr in 'Completed' status.

```
oc get ccs ccs-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

#### 1.1.2.2 Remove Db2aaserviceService from the maintenance mode

<br>

Edit the Db2aaserviceService db2aaservice-cr.

```
oc edit Db2aaserviceService db2aaservice-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove below section.

```
ignoreForMaintenance: true
```

Save and Exit. Wait until the Db2aaserviceService Operator reconcilation completed and also the db2aaservice-cr in 'Completed' status.

```
oc get Db2aaserviceService db2aaservice-cr -o yaml -n ${PROJECT_CPD_INST_OPERANDS}
```

#### 1.1.2.3 Take the AnalyticsEngine service out of maintenance mode

```
oc patch AnalyticsEngine analyticsengine-sample -p "{\"spec\":{\"ignoreForMaintenance\": false}}" --type=merge -n ${PROJECT_CPD_INST_OPERANDS}
```

Wait until the AnalyticsEngine Operator reconcilation completed and also the analyticsengine-sample in 'Completed' status.

```
oc get AnalyticsEngine analyticsengine-sample -n ${PROJECT_CPD_INST_OPERANDS}
```

#### 1.1.2.4 Uninstal the WKC hotfix & customization
1)Remove the image_digests section.
```
    image_digests:
      metadata_discovery_image: sha256:b89559cea54616a530557956dd806895b454bd5180cb7ce3656c440325f92591
      wdp_kg_ingestion_service_image: sha256:0b77632e2406dff9b2bb6bbcdbf6a06f7748f5aa702a021fde1eeeebf44bda9b
      wkc_bi_data_service_image: sha256:df96efc9d94cb6e335ce6ea1815b4c29867eee6fbd91f7ba78b11561dbfcb2ad
      wkc_data_lineage_service_image: sha256:bc0a37a460f383f9a5fce0f7decd0a074db83b9df56d541f61835ea32a486c88
      wkc_mde_service_manager_image: sha256:a7a3ea48d72baaae484c6dde0ff910a89164993795cf530054e2a39ee9bf90ce
      wkc_metadata_imports_ui_image: sha256:1487c666890f13494a9d2fe14453cd0c46234bc0b799b354ca9526f090404506
```

2)Remove the wkc_gov_ui_image section.
```
    wkc_gov_ui_image:
      name: wkc-gov-ui@sha256
      tag: f88bbdee4c723e96ba72584f186da8a1618bd1234d5e7dc32a007af3b250a5e6
```

3)Edit the wkc-cr and add the `ephemeral-storage` under the `wkc_gov_ui_resources` customization section.

<br>

For example:

```
wkc_gov_ui_resources:
  requests:
    cpu: 50m
    memory: 300Mi
    ephemeral-storage: 50Mi
  limits:
    cpu: 1000m
    memory: 1024Mi
    ephemeral-storage: 1Gi
```

4)Remove from maintenance mode.
```
    ignoreForMaintenance: false
```

Save and exit.

<br>

**Note:** 
<br>

Check whether the `image_digests` property exists in the custom resources of WKC components. 

```
for crd in $(oc get crd | grep wkc | awk '{print $1}'); do
  oc get "$crd" -n ${PROJECT_CPD_INST_OPERANDS} -o yaml
done
```
Review the custom resource content one by one. If it contains the `image_digests` property, then remove it from the custom resource. 

<br>

Wait until the WKC Operator reconcilation completed and also the wkc-cr in 'Completed' status.

```
oc get wkc wkc-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

### 1.1.2.5 Take the DataLineage service out of maintenance mode

Edit the DataLineage datalineage-cr.
```
oc edit DataLineage datalineage-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

1)Remove the hotfix images from the DataLineage datalineage-cr.

```
    datalineage_scanner_service_image_tag: 3a851c76cde46def29f2e489338a040d1e430034982fa6d6c87f5b95ae99b4e8
    datalineage_scanner_service_image_tag_metadata: 2.3.1
    datalineage_scanner_worker_image_tag: 1c731288ca446c22df24d4062a1ed15ac6a69305af0ecc5288d3d44fba92d2b1
    datalineage_scanner_worker_image_tag_metadata: 2.3.4
```

2)Remove DataLineage datalineage-cr from maintenance mode.
```
    ignoreForMaintenance: false
```

Save and exit.

<br>

Wait until the DataLineage Operator reconcilation completed and also the datalineage-cr in 'Completed' status.

```
oc get DataLineage datalineage-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

#### 1.1.2.6 Remove Db2whService from the maintenance mode

<br>

Edit the Db2whService db2wh-cr.

```
oc edit Db2whService db2wh-cr -n ${PROJECT_CPD_INST_OPERANDS}
```

Remove below section.

```
ignoreForMaintenance: true
```

Save and Exit. Wait until the Db2whService Operator reconcilation completed and also the db2wh-cr in 'Completed' status.

```
oc get Db2whService db2wh-cr -o yaml -n ${PROJECT_CPD_INST_OPERANDS}
```

### 1.1.3 Checking the Common Core services before the upgrade

- 1. Check whether Global Search configured properly
- 2. Run the `precheck_migration.sh` to determine whether you can run an automatic migration of the common core services or whether you need to configure common core services to run a semi-automatic migration.

Complete the above two checks by following the steps of the `Before you begin` section in this documentation [Pre-upgrade check for CCS](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=hub-upgrading-software#taskupgrade-instance__prereq__1_)

### 1.1.4 Calculate the required storage for the migration from Db2 to PostgreSQL
[Check the sizes of the current Db2 databases to calculate the storage that is required for the PostgreSQL instances](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading-post-upgrade-setup-knowledge-catalog#ikc_post_upgrade__expand-pvc__title__1)

## 1.2 Updating the IBM Software Hub command-line interface
### 1.2.1 Obtaining the olm-utils-v4 image

```
podman pull icr.io/cpopen/cpd/olm-utils-v4:${VERSION}.amd64 --tls-verify=false

podman login ${PRIVATE_REGISTRY_LOCATION} -u ${PRIVATE_REGISTRY_PUSH_USER} -p ${PRIVATE_REGISTRY_PUSH_PASSWORD}

podman tag icr.io/cpopen/cpd/olm-utils-v4:${VERSION}.amd64 ${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v4:${VERSION}.amd64

podman push ${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
```

### 1.2.2 Updating the IBM Software Hub command-line interface

[Update the cpd-cli utility](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=workstations-updating-software-hub-cli)

## 1.3 Installing Helm CLI

[Installing Helm](https://www.ibm.com/links?url=https%3A%2F%2Fhelm.sh%2Fdocs%2Fintro%2Finstall%2F)

## 1.4 Updating your environment variables script
Make a copy of the environment variables script used by the existing 5.1.1 variables with the name like `cpd_vars_531.sh`.

Update the environment variables script `cpd_vars_531.sh` as follows.
```
vi cpd_vars_531.sh
```
1. Locate the VERSION entry and update the environment variable for VERSION.
```
export VERSION=5.3.1
```
2. Locate the COMPONENTS entry and confirm the COMPONENTS entry is accurate.
```
export COMPONENTS=ibm-licensing,cpfs,cpd_platform,wkc,analyticsengine,datastage_ent,datalineage,ws,ws_runtimes,wml,openscale,db2wh
```
3. Add a new section called Image pull configuration to your script and add the following environment variables
```
export IMAGE_PULL_SECRET=<the name of the namespace-scoped pull secret that will contain the base64 encoded credentials for pulling images>
export IMAGE_PULL_CREDENTIALS=$(echo -n "$PRIVATE_REGISTRY_PULL_USER:$PRIVATE_REGISTRY_PULL_PASSWORD" | base64 -w 0)
export IMAGE_PULL_PREFIX=${PRIVATE_REGISTRY_LOCATION}
```
4. Locate the OLM_UTILS_IMAGE entry and update the value
```
export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
export OLM_UTILS_LAUNCH_ARGS=" --network=host"
```
5. Add the environment variable `PATCH_ID` to the environment variables script
```bash
export PATCH_ID=6
```
6. Save the changes. 

7. Confirm that the script does not contain any errors.
```
bash ./cpd_vars_531.sh
```
8. Run this command to apply cpd_vars_531.sh
```
source ./cpd_vars_531.sh
```

Reference: [Updating your environment variables script](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=information-updating-your-environment-variables-script)

# 2. Upgrade
## 2.1 Upgrading the License Service

### 2.1.1 Get the project of the License service

If you're not sure which project the License Service is in, run the following command:
```
oc get deployment -A | grep ibm-licensing-operator
```

### 2.1.2  Log in to the Red Hat OpenShift Container Platform cluster
```
${CPDM_OC_LOGIN}
```

### 2.1.3 Upgrading the License Service

```
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--license_acceptance=true \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```
Confirm that the License Service pods are Running or Completed:

```
oc get pods --namespace=${PROJECT_LICENSE_SERVICE}
```

## 2.2 Preparing to upgrade IBM Software Hub

### 2.2.1 Updating the cluster-scoped resources for the platform and services

1.Generate cluster-scoped resources for platform and services
<br>

**Note:** Remove the `scheduler` from the the `COMPONENTS` list as it has been covered in the step 2.2.
```
cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cluster_resources=true
```

2.Log in to Red Hat® OpenShift® Container Platform as a cluster administrator
```
${OC_LOGIN}
```

3.Apply the cluster-scoped resources for the platform and services
<br>
Get the work directory.
```
WORK_DIR=$(podman inspect "olm-utils-play-v4" 2>/dev/null | jq -r '.[0].Mounts[] | select(.Destination == "/tmp/work") | .Source' | head -n 1)
echo "Detected olm-utils-play-v3 /tmp/work mount: ${WORK_DIR}"
```
Apply the cluster-scoped resources  for the platform and services.
```
oc apply -f $WORK_DIR/cluster_scoped_resources.yaml \
--server-side \
--force-conflicts
```

## 2.3 Upgrading IBM Software Hub
## 2.3.1 Creating image pull secrets for an instance of IBM Software Hub
1.Log in to Red Hat® OpenShift® Container Platform as a user with sufficient permissions to complete the task.
```
${OC_LOGIN}
```

2.Create a file named dockerconfig.json based on where your cluster pulls images from.
```
cat <<EOF > dockerconfig.json 
{
  "auths": {
    "${PRIVATE_REGISTRY_LOCATION}": {
      "auth": "${IMAGE_PULL_CREDENTIALS}"
    }
  }
}
EOF
```

3.Create the image pull secret in the operators project for the instance.

```
oc create secret docker-registry ${IMAGE_PULL_SECRET} \
--from-file ".dockerconfigjson=dockerconfig.json" \
--namespace=${PROJECT_CPD_INST_OPERATORS}
```

4.Create the image pull secret in the operands project for the instance:
```
oc create secret docker-registry ${IMAGE_PULL_SECRET} \
--from-file ".dockerconfigjson=dockerconfig.json" \
--namespace=${PROJECT_CPD_INST_OPERANDS}
```

### 2.3.2 Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```

### 2.3.3 Update the saml-secret to avoid TypeError 
1)Back up the saml-secret

<br>

2)Update the saml-secret to avoid TypeError `value is set but not boolean` during the IBM Software Hub upgrade.
<br>

Find the `saml-secret` in OpenShift Web console and make change to the value of the property `disableRequestedAuthnContext`. Change the value from `"true"` to `true`.
<br>
From:

```
# samlConfig.json
{
    ......
    "disableRequestedAuthnContext": "true"
}
```

To:

```
# samlConfig.json
{
    ......
    "disableRequestedAuthnContext": true
}
```

### 2.3.4 Upgrading the required operators and custom resources for the instance
```
cpd-cli manage install-components \
--license_acceptance=true \
--components=cpd_platform \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--run_storage_tests=true \
--upgrade=true
```

Once the above command `cpd-cli manage install-components` is completed, make sure the status of the IBM Software Hub is in 'Completed' status.
```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \ 
--components=cpd_platform
```

## 2.4 Applying the RSI patches
Run the following command to re-apply your existing custom patches.
```
cpd-cli manage apply-rsi-patches --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

Check the RSI patches status again: 
```
cpd-cli manage get-rsi-patch-info --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --all
```

## 2.5 Upgrading WKC

### 2.5.1 Preparing to upgrade IBM Knowledge Catalog

Before you can upgrade IBM Knowledge Catalog to Version 5.3 and migrate all IBM Knowledge Catalog data to the EDB Native PostgreSQL database that is used in Version 5.3, complete several checks and preparation tasks.
<br>
[Pre-upgrade tasks](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading-preparing-upgrade-knowledge-catalog)

### 2.5.2 Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```

### 2.5.3 Upgrading the operator and custom resource for IBM Knowledge Catalog

```
cpd-cli manage install-components \
--license_acceptance=true \
--components=wkc \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--upgrade=true
```

**Note:** When CCS upgrade is in progress, make changes to the `asset_files_api_args` customization section in the CCS cr as follows.
<br>
`index.js` -> `index.mjs`.

<br>

The updated `asset_files_api_args` customization looks like below:

```
asset_files_api_args:
    - '-c'
    - |
      cd /home/node/${MICROSERVICENAME}
      source /scripts/exportSecrets.sh
      export npm_config_cache=~node
      node --max-old-space-size=12288 --max-http-header-size=32768 index.mjs
```

Once the above command `cpd-cli manage install-components` completed successfully, you can run the `cpd-cli manage get-cr-status` command for the validation.

```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=wkc
```

## 2.6 Upgrading DataStage, IBM Data Lineage

### 2.6.1 Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```

### 2.6.2 Upgrading the operator and custom resource
```
cpd-cli manage install-components \
--license_acceptance=true \
--components=datastage_ent,datalineage \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--upgrade=true
```

### 2.6.3 Increase the `idle_in_transaction_session_timeout` of the lineage Postgres cluster (e.g. datalineage-cloud-native-postgresql)
<br>
1)Confirm the Postgres cluster is up and running and accepting connections

<br>

2)Connect to the **Primary** replica of the lineage Postgres cluster and increase the idle_in_transaction_session_timeout.

<br>

```
psql -d scannerservice -U postgres
ALTER DATABASE scannerservice SET idle_in_transaction_session_timeout = '10h';
```
<br>

3)Scale down datalineage-operator

<br>

4)Edit the lineage-scanner-service deployment, and change `failureThreshold` in the readiness and liveness probes.

<br>
e.g. use value 600 - this will mean 10 hours before the app is restarted4

5)Monitor the log of the lineage-scanner-service pod and wait until it finishes the migrations.

<br>

6)Return the timeout to the previous value of 2 minutes
<br>
```
ALTER DATABASE scannerservice SET idle_in_transaction_session_timeout = '2m';
```

7)Revert the failureThreshold changed in lineage-scanner-service deployment.

8)Scale the datalineage-operator back up

<br>

- Validating the upgrade

```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=datalineage
```

## 2.7 Upgrading Watson Studio, Watson Machine Learning, OpenScale

### 2.7.1 Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```

### 2.7.2 Upgrading the operator and custom resource
```
cpd-cli manage install-components \
--license_acceptance=true \
--components=ws,ws_runtimes,wml,openscale \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--upgrade=true
```

Once the above command `cpd-cli manage install-components` completed successfully, run the `cpd-cli manage get-cr-status` command for the validation.

```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=ws,ws_runtimes,wml,openscale
```

## 2.8 Upgrading Db2 Warehouse

### 2.8.1 Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```

### 2.8.2 Upgrading the operator and custom resource
```
cpd-cli manage install-components \
--license_acceptance=true \
--components=db2wh \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--upgrade=true
```

Once the above command `cpd-cli manage install-components` completed successfully, run the `cpd-cli manage get-cr-status` command for the validation.

```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=db2wh,match360
```

# 3. Post-upgrade tasks

## 3.1 Creating a profile to use the cpd-cli management commands
Create a profile on the workstation from which you will upgrade the service instances.
<br>
[Creating a profile to use the cpd-cli management commands](https://www.ibm.com/docs/en/SSNFH6_5.3.x/cpd-cli/cpd-profile-mgmt.html)
<br>
**Note:**
The profile must be associated with a IBM Software Hub user who has either the following permissions:
<br>
- Create service instances (can_provision)
- Manage service instances (manage_service_instances)


## 3.2 Post-upgrade of WKC

### 3.2.1 Upgrading Analytics Engine service instance

- Set the environment variable `CPD_PROFILE_NAME`.
<br>

```
export CPD_PROFILE_NAME=<the profile name created in the Step 3.1>
```

- Upgrading the Spark service instance

```
cpd-cli service-instance upgrade \
--service-type=spark \
--profile=${CPD_PROFILE_NAME} \
--all
```

- Validating the service instance upgrade status.

```
cpd-cli service-instance list \
--service-type=spark \
--profile=${CPD_PROFILE_NAME}
```

### 3.2.2 Completing the catalog-api service migration to PostgreSQL
[Complete the catalog-api service migration to PostgreSQL](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/admin/post-install-services-catalog-api-migration.html)

### 3.2.3 Completing the Db2 migration to PostgreSQL
Migrate IBM Knowledge Catalog data from the previously used Db2 and CouchDB databases to the EDB Native PostgreSQL database that is used starting in Version 5.3. 
<br>
[Db2 migration to PostgreSQL](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading-post-upgrade-setup-knowledge-catalog)

### 3.2.4 Apply the patch for ccs-cams-postgres to improve the performance

```
 oc patch clusters.postgresql.k8s.enterprisedb.io ccs-cams-postgres \
  -n ${PROJECT_CPD_INST_OPERANDS} \
  --type merge \
  --patch '
spec:
  primaryUpdateMethod: restart
  postgresql:
    parameters:
      wal_keep_size: "4GB"
      wal_receiver_timeout: "30s"
      wal_sender_timeout: "30s"
      wal_compression: "on"
'
```

Make sure it is Healthy and replica is up to date (current LSN of the Primary and Standby are the same).

```
oc cnp status ccs-cams-postgres
```

Put CCS into maintenance mode.
```
oc patch -n wkc ccs ccs-cr --type merge --patch '{"spec": {"ignoreForMaintenance": true}}'
```

### 3.2.5 Day 0 tuning list (tune CAMS Postgres performance):

1. [Enable GS filter for portal catalog](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/Upgrade/CPD%205.2.2%20to%205.3.1%20Patch4/UPDATE_CONFIGMAP_INSTRUCTIONS-CATALOG_FILTERS_FROM_GLOBAL_SEARCH.md)

2. Increase cams postgres resources and set ccs in maintenance mode
```
oc patch ccs ccs-cr \
  -n ${PROJECT_CPD_INST_OPERANDS} \
  --type merge \
  --patch '{
    "spec": {
      "cams_postgres_resources": {
        "requests": {
          "cpu": "100m",
          "memory": "24Gi",
          "ephemeral-storage": "128Mi"
        },
        "limits": {
          "cpu": "20",
          "memory": "96Gi",
          "ephemeral-storage": "10Gi"
        }
      },
      "cams_postgres_sql_param_shared_buffers": "24GB",
      "ignoreForMaintenance": true
    }
  }'
```

3. Install pg_buffer_cache, pg_stat_statment extensions [install_pg_extensions.sh.txt](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/Upgrade/CPD%205.2.2%20to%205.3.1%20Patch4/install_pg_extensions.sh.txt) for future diagnostics.

4. Change ccs-cams-postgres parameters, to enable pg_stat_statement and adjust other resource parameters:
```
oc patch \
  -n ${PROJECT_CPD_INST_OPERANDS} \
  clusters.postgresql.k8s.enterprisedb.io ccs-cams-postgres \
  --type merge \
  --patch '
spec:
  postgresql:
    parameters:
      shared_preload_libraries: "pg_stat_statements"
      pg_stat_statements.track: "all"
      pg_stat_statements.max: "10000"
      pg_stat_statements.track_utility: "on"
      work_mem: "120MB"
      maintenance_work_mem: "256MB"
      max_parallel_workers_per_gather: "8"
```

Verify these parameters are added to the cluster by running from inside the cams postgres pod:
```
SHOW work_mem; 
SHOW max_parallel_workers_per_gather; 
SHOW maintenance_work_mem; 
SHOW shared_preload_libraries;
SHOW shared_buffers;
```

5. Add list of indexes to camsdb

Connect to the primary ccs-cams-postgres database.
```
oc -n ${PROJECT_CPD_INST_OPERANDS} exec -it ccs-cams-postgres-1 sh
sh-5.1$psql -h ccs-cams-postgres-rw -p 5432 -U cams_user -d camsdb
```

Create Indexes:
```
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_asset_default_index_text_gin_trgm 
ON cams.asset USING gin (default_index_text gin_trgm_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_asset_query_covering 
ON cams.asset USING btree (catalog_id, state, is_revision, model_version, id, set_id) 
INCLUDE (unshared_attributes, attributes, mode, member_and_owner_user_ids, member_and_owner_group_ids, 
         project_id, asset_category, asset_type, description, sub_container_id) 
WHERE is_revision = false 
  AND model_version < 3.0 
  AND project_id IS NULL 
  AND sub_container_id IS NULL 
  AND state = 'available';

CREATE INDEX CONCURRENTLY IF NOT EXISTS asset_search_untyped_idx 
ON cams.asset USING btree (catalog_id, state, is_revision, project_id, mode, created_at);

CREATE INDEX CONCURRENTLY IF NOT EXISTS catalog_bss_subtype_state_idx 
ON cams.catalog(bss_account, subtype, state, is_public, is_consolidated_db) 
WHERE bss_account IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS asset_catalog_id_name 
ON cams.asset (catalog_id, name NULLS FIRST);

CREATE INDEX CONCURRENTLY IF NOT EXISTS asset_catalog_id_name_set_id 
ON cams.asset (catalog_id, name, set_id) 
WHERE set_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS asset_type_state_id_idx 
ON cams.asset_type(asset_type_state_state, id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS asset_count_idx
 ON cams.asset (catalog_id, state, is_revision, model_version, project_id, sub_container_id,
   mode, asset_type, asset_category, id)
 INCLUDE (name, description, member_and_owner_user_ids, member_and_owner_group_ids,
  owner_user_group_and_profile_ids)
 WHERE is_revision = false AND model_version < 3.0
   AND project_id IS NULL AND sub_container_id IS NULL
   AND state = 'available';

----- Request from Krishna Sheth on 6/15 -----
CREATE INDEX CONCURRENTLY asset_catalog_created_idx
  ON cams.asset (catalog_id, created_at DESC NULLS LAST)
  WHERE is_revision = false AND state = 'available' AND project_id IS NULL;
-- This should already be there but just in case it was missed
CREATE INDEX asset_search_typed_idx
ON cams.asset USING btree (catalog_id, asset_type, state, is_revision, project_id, mode);

----- Request from Krishna Sheth on 6/16 -----
--- Index 1: account_asset_metric_stdpremium_idx 
--- Not used by ui operations low priortiy but creating it to keep it in sync with ROKS
CREATE INDEX account_asset_metric_stdpremium_idx ON cams.asset
USING btree (id, catalog_id)
WHERE ((attributes_and_asset_type && '{discovered_asset,ibm_bi_report,cobol_copybook}'::text[])
  AND (is_revision = false) AND (asset_category <> 'SYSTEM'::text))

-- Index2: account_asset_metric_trialessential_idx
--- Not used by ui operations low priortiy but creating it to keep it in sync with ROKS
CREATE INDEX account_asset_metric_trialessential_idx ON cams.asset
USING btree (id, catalog_id)
WHERE ((attributes_and_asset_type && '{discovered_asset}'::text[])
  AND (is_revision = false) AND (asset_category <> 'SYSTEM'::text))

-- Index3: asset_catalog_state_created_at_idx
CREATE INDEX asset_catalog_state_created_at_idx ON cams.asset
USING btree (catalog_id, is_revision, state, project_id, created_at DESC NULLS LAST)
WHERE ((is_revision = false) AND (state = 'available'::text) AND (project_id IS NULL))
```

### 3.2.6 Run the global search bulk sync utility
If you didn't synchronize the global search index in version 5.1, complete these tasks:
- To be able to use the global search indexed data for relationships, see [Bulk sync relationships for global search](https://www.ibm.com/docs/en/SSNFH6_5.3.x/wsj/admin/admin-bulk-sync-rel.html).
- To be able to use the global search indexed data for assets, see [Bulk sync assets for global search](https://www.ibm.com/docs/en/SSNFH6_5.3.x/wsj/admin/admin-bulk-sync.html).

## 3.3 Post-upgrade of Db2Wh
[Upgrading existing service instances](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=u-upgrading-from-version-52-41#cli-upgrade__svc-inst__title__1)

## 3.4 Reconfigure the LDAP

### 3.4.1 Unset the LDAP config

- Option 1: Unset the LDAP config from web console.

- Option 2: Unset the LDAP config from database.

```
oc rsh <zen-metastoredb-primarypod>
sh-5.1$ psql -U postgres -d zen
zen=# UPDATE platform_config SET data = '{"comment":"this is the default out of the box settings - n o ldap or policy setup. auto signup disabled","auto_signup":false,"externalLDAPHost":"","externalLDAPPort":"","externalLDAPSuffix":"","externalLDAPMechanism":"search"}' WHERE id = 'ldap';
```
    
### 3.4.2 Reconfigure the LDAP
Log in the IBM Software Hub web console using the local admin and then configure the LDAP referring to this documentation.

<br>

[Configure a connection to an existing identity provider](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=users-connecting-your-identity-provider)

## 3.5 Upgrade the cpdbr service
If IBM Fusion application in use, upgrade it before upgrading the cpdbr service.
[Updating the cpdbr service](https://www.ibm.com/docs/en/SSNFH6_5.3.x/hub/upgrade/v52/upgrade-platform-bar-recipe.html)
