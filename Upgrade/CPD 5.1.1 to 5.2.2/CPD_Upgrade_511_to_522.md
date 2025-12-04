# CPD Upgrade Runbook - v.5.1.1 to 5.2.2

Table of Content
- [Preface](#preface)
- [Part 1: Pre-upgrade](#part-1-pre-upgrade)
- [Part 2: Upgrade prerequisite software](#part-2-upgrade-prerequisite-software)
- [Part 3: Upgrading CDP services](#part-3-upgrading-cdp-services)
  
## Preface
### Upgrade documentation
* [Upgrading from IBM Cloud Pak for Data Version 5.1.1 to Version 5.2.2](https://www.ibm.com/docs/en/software-hub/5.2.x?topic=upgrading-from-version-51)

### CPD/Services Installed on v.5.1.1
Components|CR Kind|CR Name|Namespace|Expected Version|Reconciled Version|Progress|Status
---------------|--------------|----------------------|-----------|------------------|------------------|----------|-------------
datalineage|DataLineage|datalineage-cr|dev|5.1.1|5.1.1|100%|InMaintenance
cpd_platform|Ibmcpd|ibmcpd-cr|dev|5.1.1|5.1.1|100%|Completed
wkc|WKC|wkc-cr|dev|5.1.1|5.1.1|0%|InMaintenance
zen|ZenService|lite-cr|dev|6.1.1|6.1.1|100%|Completed
db2wh|Db2whService|db2wh-cr|dev|5.1.0|5.1.0+11.5.9.0-cn3+2667|N/A|Completed
analyticsengine|AnalyticsEngine|analyticsengine-sample|dev|5.1.1|5.1.1|100%|InMaintenance
ws|WS|ws-cr|dev|10.1.0|10.1.0|100%|Completed
ibm_redis_cp|Rediscp|mdm-redis-cp-1715194012081921|dev|1.2.5|1.2.5|100%|Completed
ccs|CCS|ccs-cr|dev|10.1.0|10.1.0|100%|Completed
datastage_ent|DataStage|datastage|dev|5.1.1|5.1.1|100%|Completed
wml|WmlBase|wml-cr|dev|5.1.1|5.1.1|100%|Completed
openscale|WOService|aiopenscale|dev|5.1.1|5.1.1|100%|Completed
ws_runtimes|NotebookRuntime|ibm-cpd-ws-runtime-241-py|dev|10.1.0|10.1.0|100%|Completed
db2aaservice|Db2aaserviceService|db2aaservice-cr|dev|5.1.0|5.1.0+11.5.9.0-cn3+2667|N/A|Completed
match360|MasterData Management|mdm-cr|dev|4.4.21|4.4.21|100%|Completed

### Upgrade context
From

```
OCP: 4.16
CPD: 5.1.1
Storage: Fusion 2.9.0
Componenets: ibm-cert-manager,scheduler,ibm-licensing,cpfs,cpd_platform,zen,ccs,wkc,datalineage,db2wh,analyticsengine,ws,ibm_redis_cp,datastage_ent,wml,openscale,ws_runtimes,db2aaservice,match360
```

To
```
OCP: 4.16
CPD: 5.2.2
Storage: Fusion 2.9.0
Componenets: ibm-cert-manager,scheduler,ibm-licensing,cpfs,cpd_platform,zen,ccs,wkc,datalineage,db2wh,analyticsengine,ws,ibm_redis_cp,datastage_ent,wml,openscale,ws_runtimes,db2aaservice,match360
```

## Part 1: Pre-upgrade
### 1. Set up client workstation

#### 1.1 Prepare the client workstation
1. Prepare a RHEL 9 machine with internet 

* 1.1 Download the cpd-cli for 5.2.2.

```bash
wget https://github.com/IBM/cpd-cli/releases/download/v14.2.2/cpd-cli-linux-EE-14.2.2.tgz
```

2. Install the tool.

* 2.1 Untar content.

```bash
tar xvf cpd-cli-linux-EE-14.2.2.tgz
```

* 2.2 Make cpd-cli utility executable anywhere.

```bash
 vi ~/.bashrc
 ```
 
* 2.3 Add the following line at the bottom of the file.

 ```bash
 export PATH=<fully-qualified-path-to-the-cpd-cli>:$PATH
 ```

 * 2.4 After editing the `.bashrc` file, in order to load this change, we need to close the current session and login back to the terminal, or do `bash`.

* 2.5 Check out with this command.

```bash
cpd-cli version
```

* 2.6 Output should be like this.

```bash
cpd-cli
   	Version: 14.2.2
   	Build Date: 2025-10-25T13:04:21
   	Build Number: 2727
   	SWH Release Version: 5.2.2
```

<!-- 5. Update the OpenShift CLI

* 5.1 Check the OpenShift CLI version.

```
oc version
```

**NOTE:**
<br>If the version doesn't match the OpenShift cluster version, update it accordingly. -->

#### 1.2 Update Environment Variables for the upgrade to Version 5.2.2

1. Locate the VERSION entry and update the environment variable for VERSION.

```bash
vi cpd_vars.sh
export VERSION=5.2.2
```

2. Locate the COMPONENTS entry and confirm the COMPONENTS entry is accurate.

```bash
COMPONENTS=ibm-cert-manager,scheduler,ibm-licensing,cpfs,cpd_platform,zen,ccs,wkc,datalineage,db2wh,analyticsengine,ws,ibm_redis_cp,datastage_ent,wml,openscale,ws_runtimes,db2aaservice,match360
```

3. Save the changes.

4. Confirm that the script does not contain any errors.

```bash
bash ./cpd_vars.sh
```

5. Run this command to apply `cpd_vars.sh`.

```bash
source cpd_vars.sh
```

#### 1.3 Ensure the cpd-cli manage plug-in the latest version of the olm-utils image

1. Run the following command to ensure that the cpd-cli is installed and running and that the cpd-cli manage plug-in has the latest version of the olm-utils image.

```bash
cpd-cli manage restart-container
```

2. Check and confirm the olm-utils-v3 container is up and running.

```bash
podman ps | grep olm-utils-v3
```

#### 1.4 Mirroring images directly to the private container registry
1. Log in to the IBM Entitled Registry registry
```
cpd-cli manage login-entitled-registry ${IBM_ENTITLEMENT_KEY}
```

2. Log in to the private container registry
```
cpd-cli manage login-private-registry \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PUSH_USER} \
${PRIVATE_REGISTRY_PUSH_PASSWORD}
```

3. Download CASE packages from GitHub (github.com/IBM) and check for any errors
```
export COMPONENTS=<component-ID>
export VERSION=5.2.2

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--inspect_source_registry=true

grep "level=fatal" list_images.csv
```

4. Mirror the images to the private container registry and check for any errors that occurred.
```
cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--arch=${IMAGE_ARCH} \
--case_download=false

grep "error" mirror_*.log
```

5. Confirm that the images were mirrored to the private container registry and check for any errors that occurred
```
cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--case_download=false

grep "level=fatal" list_images.csv
```

#### 1.5 Health Check

1. Check OCP status

* 1.1 Login Bastion node and log in to OCP cluster.
```bash
${CPDM_OC_LOGIN}
```

* 1.2 Make sure All the cluster operators should be in `AVAILABLE` status, and not in `PROGRESSING` or `DEGRADED` status.

```bash
oc get co
```

* 1.3 Review nodes status, make sure all the nodes are in `READY` status.

```bash
oc get nodes
```

* 1.4 Review the machine configure pool are in healthy status.

```bash
oc get mcp
```

2. Check CPD status

* 2.1 Login Bastion node and log in to OCP cluster. Ensure `cli-cpd`command-line interface is installed properly.

```bash
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}
```

* 2.2 Review Services are in `READY` status.

```bash
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

* 2.3 Review pods are healthy.

```bash
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[:digit:]])/\1.*R' | grep -v 'Completed'
```

3. Check private container registry status if installed

* 3.1 Login Bastion node, where the private container registry is usually installed, as root. Run this command in terminal and make sure it can succeed.

```bash
podman login --username $PRIVATE_REGISTRY_PULL_USER --password $PRIVATE_REGISTRY_PULL_PASSWORD $PRIVATE_REGISTRY_LOCATION --tls-verify=false
```

* 3.2 You can run this command to verify the images in private container registry.

```bash
curl -k -u ${PRIVATE_REGISTRY_PULL_USER}:${PRIVATE_REGISTRY_PULL_PASSWORD} https://${PRIVATE_REGISTRY_LOCATION}/v2/_catalog?n=6000 | jq .
```

## Part 2: Upgrade prerequisite software

### 2.1 Upgrading Red Hat OpenShift Serverless Knative Eventing

1. Check the version of the Red Hat OpenShift Serverless Operator on your cluster

```bash
oc get csv -n=openshift-serverless | grep serverless-operator
```

2. Determine whether you need to upgrade the IBM Events Operator:

* 2.1 Run the following command to check the version of the IBM Events Operator on your cluster.

```bash
oc get csv -n=${PROJECT_IBM_EVENTS} | grep ibm-events
```

* 2.2 Compare the information returned by the preceding command with the information in the following table.

| IBM® Software Hub version      | Operator version |
| ----------- | ----------- |
| 5.2.1      | 5.2.0       |
| 5.2.0   | 5.1.2        |

**NOTE:**
<br>
If you are running the correct version of the IBM Events Operator based on the version of IBM Software Hub that is installed, no action is required. 
<br>
If you are not running the required version, you must upgrade the IBM Events Operator.

3. Upgrade IBM Events Operator.

```bash
${CPDM_OC_LOGIN}
```

```bash
cpd-cli manage authorize-instance-topology \
--release=${VERSION} \
--cpd_operator_ns=ibm-knative-events \
--cpd_instance_ns=knative-eventing
```

```bash
cpd-cli manage setup-instance-topology \
--release=${VERSION} \
--cpd_operator_ns=ibm-knative-events \
--cpd_instance_ns=knative-eventing \
--block_storage_class=${STG_CLASS_BLOCK} \
--license_acceptance=true
```

### Known issue:
https://github.ibm.com/PrivateCloud-analytics/CPD-Quality/issues/42294

Review `${STG_CLASS_BLOCK}` is set in the `cpd_vars.sh` file

```bash
cpd-cli manage deploy-knative-eventing \
--release=${VERSION} \
--block_storage_class=${STG_CLASS_BLOCK} \
--upgrade=true
```

Potential issue during `manage deploy-knative-eventing`.

```
Delete kafka-kafka pod
knative-eventing-kafka-kafka-0
knative-eventing-kafka-kafka-1
knative-eventing-kafka-kafka-2
```

### 2.2 Upgrading shared cluster components

1. Run the cpd-cli manage login-to-ocp command to log in to the cluster.

```bash
${CPDM_OC_LOGIN}
```

2. Verify Certificate manager:

```bash
oc get csv | grep ibm-cert-manager
```

3. Confirm the project which the License Service is in, run the following command.

```bash
oc get deployment -A |  grep ibm-licensing-operator
```

**NOTE:**
<br>Make sure the project returned by the command matches the environment variable `PROJECT_LICENSE_SERVICE` in your environment variables script `cpd_vars.sh`.

4. Confirm the scheduler services project is installed on the cluster, run the following command.

```bash
oc get scheduling -A
```

**Note:**
<br>Make sure the project returned by the command matches the environment variable `PROJECT_SCHEDULING_SERVICE` in your environment variables script `cpd_vars.sh`.

5. Upgrade the Certificate Manager and License Service.

```bash
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```

6. Confirm License Service pods are Running or Completed.

```bash
oc get pods --namespace=${PROJECT_LICENSE_SERVICE}
```

7. Confirm IBM Certificate Manager pods are Running or Completed.

```bash
oc get pods --namespace=${PROJECT_CERT_MANAGER}
```

8. Upgrade Scheduling Service.

```bash
cpd-cli manage apply-scheduler \
--release=${VERSION} \
--license_acceptance=true \
--scheduler_ns=${PROJECT_SCHEDULING_SERVICE}
```

9. Confirm Scheduling service pods are Running or Completed.

```bash
oc get pods --namespace=${PROJECT_SCHEDULING_SERVICE}
```

### 2.3 Preparing to upgrade instance of IBM Software Hub

1. Applying Entitlements.

```bash
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=cpd-enterprise
```

```bash
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=watson-discovery
```

```bash
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=watson-assistant
```

### 2.4 Upgrade IBM Software Hub

1. Review License Term.

```bash
cpd-cli manage get-license \
--release=${VERSION} \
--license-type=EE
```

2. Upgrade operators and custom resources.

```bash
cpd-cli manage setup-instance \
--release=${VERSION} \
--license_acceptance=true \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

3. Upgrade operators for services

```bash
cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--upgrade=true
```

4. Confirm all the operators pods are Running or Completed.

```bash
oc get pods --namespace=${PROJECT_CPD_INST_OPERATORS}
```

5. Validate the upgrade.

```bash
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

## Part 3: Upgrading CDP Services



### 3.1 Upgrading IBM Knowledge Catalog service and apply customizations
Check if the IBM Knowledge Catalog service was installed with the custom install options. 
#### 1. For custom installation, check the previous install-options.yaml or wkc-cr yaml, make sure to keep original custom settings
Specify the following options in the `install-options.yml` file in the `work` directory. Create the `install-options.yml` file if it doesn't exist in the `work` directory.

```
################################################################################
# IBM Knowledge Catalog parameters
################################################################################
custom_spec:
  wkc:
    enableKnowledgeGraph: True
    enableDataQuality: True
    useFDB: False    
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

#### 2.Upgrade WKC with custom installation

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

#### 3.Validate the upgrade
```
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=wkc
```

#### 4.Apply the customizations 
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

### 3.2 Upgrading Analytics Engine service
#### 3.2.1 Upgrading the service

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

#### 3.2.2 Upgrading the service instances

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

### 3.3 Upgrading Watson Studio, Watson Studio Runtimes, Watson Machine Learning and OpenScale
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

### 3.4 Upgrading Db2 Warehouse
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





### 3.5 Updating cpdbr service

1. Upgrade the cpdbr-tenant component for the instance. 

**NOTE:**
<br>This can be doing in a maintenance window. <br>It needs Fusion version above 2.10

```bash
export OADP_OPERATOR_NS=<oadp-operator-project>
```

```bash
cpd-cli oadp install \
--component=cpdbr-tenant \
--cpdbr-hooks-image-prefix=${PRIVATE_REGISTRY_LOCATION} \
--tenant-operator-namespace=${PROJECT_CPD_INST_OPERATORS} \
--skip-recipes=true \
--upgrade=true \
--log-level=debug \
--verbose
```

2. Configure the ibmcpd-tenant parent recipe.

```bash
cpd-cli oadp generate plan fusion parent-recipe \
--tenant-operator-namespace=${PROJECT_CPD_INST_OPERATORS} \
--log-level=debug \
--verbose
```
