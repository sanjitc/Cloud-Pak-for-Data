# CPD Upgrade Runbook - v.5.1.1 to 5.2.2

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

#### 1.4 Health Check

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

## Part 2: Upgrade

### 2.1 Upgrading prerequisite software

#### 2.1.1 Upgrading Red Hat OpenShift Serverless Knative Eventing

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

6. Upgrading CDP Services to 5.2.2.

* 6.1 Upgrading Watson Discovery.

```bash
cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=watson_discovery \
--license_acceptance=true \
--upgrade=true
```
<!-- **NOTE:**
<br>Review install-options.yml is configured properly for the service that it is going to be upgraded. -->

* 6.2 Review installation progress.

* 6.2.1 Find the pod of the service.

```bash
oc get pods -n ${PROJECT_CPD_INST_OPERATORS} | grep -i discovery
```

The output should be something like this:

```bash
oc get pods -n ${PROJECT_CPD_INST_OPERATORS} | grep -i discovery
ibm-watson-discovery-operator-catalog-nfzg7                       1/1     Running     0               4h31m
wd-discovery-operator-f4bd9688b-qg2j6                             1/1     Running     1 (4h16m ago)   4h19m
```

* 6.2.2 Review logs of the pod:

```bash
oc logs wd-discovery-operator-f4bd9688b-qg2j6 -n ${PROJECT_CPD_INST_OPERATORS}
```

* 6.2.3 Review the progress of the update.
```bash
watch 'oc get WatsonDiscovery wd -n ${PROJECT_CPD_INST_OPERANDS} --output jsonpath="{.status.progress} {.status.componentStatus.deployed} {.status.componentStatus.verified}"'
```

* 6.3 Validate the upgrade.

```bash
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

Potential issue related to opensearch pods.

```bash
oc patch cm wd-discovery-opensearch-client-config -n ${PROJECT_CPD_INST_OPERANDS} --patch='{"data": {"forceEphemeral": "true"}}'
oc patch cm wd-discovery-opensearch-data-config -n ${PROJECT_CPD_INST_OPERANDS} --patch='{"data": {"forceEphemeral": "true"}}'
oc patch cm wd-discovery-opensearch-master-config -n ${PROJECT_CPD_INST_OPERANDS} --patch='{"data": {"forceEphemeral": "true"}}'
```

* 6.4 Upgrading Watson Assistant.

```bash
cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=watson_assistant \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true \
--upgrade=true
```

<!-- Defect:
https://github.ibm.com/PrivateCloud-analytics/CPD-Quality/issues/42297 -->

<!-- **NOTE:**
<br>Review install-options.yml is configured properly for the service that it is going to be upgraded. -->

* 6.5 Review installation progress.

* 6.5.1 Find the pod of the service.

```bash
oc get pods -n ${PROJECT_CPD_INST_OPERATORS} | grep -i assistant
```

The output should be something like this:

```bash
oc get pods -n ${PROJECT_CPD_INST_OPERATORS} | grep -i assistant
ibm-watson-assistant-operator-64f579c54-c2gtl                     1/1     Running     0               4h40m
ibm-watson-assistant-operator-catalog-xcm6x                       1/1     Running     0               4h40m
```

* 6.5.2 Review logs of the pod:

```bash
oc logs ibm-watson-assistant-operator-64f579c54-c2gtl -n ${PROJECT_CPD_INST_OPERATORS}

OR

oc exec -it <watson-assistant-pod name> -n ${PROJECT_CPD_INST_OPERATORS} sh
```
* 6.5.3 When you connect to the pod:

```bash
tail -f watsonassistant.wa.log
```

* 6.5.4 Review the progress of the update.
```bash
watch 'oc get WatsonAssistant wa -n ${PROJECT_CPD_INST_OPERANDS} --output jsonpath="{.status.progress} {.status.componentStatus.deployed} {.status.componentStatus.verified}"'
```

* 6.6 Validate the upgrade.

```bash
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

Potential issue related to `wa-data-governor` pods.

```bash
oc patch cm wa-data-governor-ibm-data-governor-all-search-config -n ${PROJECT_CPD_INST_OPERANDS} --patch='{"data": {"forceEphemeral": "true"}}'
```

7. Enable `zen-rsi-evictor-cron-job`.

```bash
oc patch CronJob zen-rsi-evictor-cron-job \
--namespace=${PROJECT_CPD_INST_OPERANDS} \
--type=merge \
--patch='{"spec":{"suspend": false}}'
```

8. Apply RSI patches.

```bash
cpd-cli manage apply-rsi-patches \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

### 2.5 Updating cpdbr service

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
