# CPD Ugrade From 4.7.1 to 4.8.1

## Upgrade Context

```
OCP: 4.12 
CPD: from 4.7.1 to 4.8.1
Componenets: wa,wd
```

## Table of Content
Part 1: Backup wa wd
Part 2: Upgrade CPD 
Part 2: Upgrade CPD services(wa, wd)

## Part 1: Backup wa wd

### Backup wa
check wa version 

oc get WatsonAssistant wa -o yaml


oc project <cpd_namespace>

WA Backup by scripts:
https://cloud.ibm.com/docs/watson-assistant?topic=watson-assistant-backup-data#backup-os

Download the backupPG.sh script.

git clone https://github.com/watson-developer-cloud/community/blob/master/watson-assistant/data/

cd <your-wa-version>
./backupPG.sh --instance ${INSTANCE} > ${BACKUP_DIR}

Note the $INSTANCE is from "oc get wa" output, the first column gives the name of the instance, in Verizon’s case it was “wa”.   It is NOT the namespace.

for example 
```
./backupPG.sh --instance wa > ${BACKUP_DIR}
```

### Backup wd

WD Backup by scripts:
https://cloud.ibm.com/docs/discovery-data?topic=discovery-data-backup-restore#wddata-backup

check wd version
oc get WatsonDiscovery wd -o yaml

```
git clone https://github.com/watson-developer-cloud/doc-tutorial-downloads/
cd /discovery-data/latest
chmod +x all-backup-restore.sh
```
```
./all-backup-restore.sh backup 
```

## Part 2 : Upgrade CPD

### 2.1 Download and setup CPD CLI
```
mkdir /ibm/cpd/4.8.1
cd /ibm/cpd/4.8.1
wget https://github.com/IBM/cpd-cli/releases/download/v13.1.1/cpd-cli-linux-EE-13.1.1.tgz
tar -xvf cpd-cli-linux-EE-13.1.1.tgz
vi ~/.bashrc
export PATH=<fully-qualified-path-to-the-cpd-cli>:$PATH

cpd-cli manage restart-container

```

### 2.2 Editing environment variables file
```
export VERSION=4.8.1
export SERVER_ARGUMENTS="--server=${OCP_URL}"
export LOGIN_ARGUMENTS="--username=${OCP_USERNAME} --password=${OCP_PASSWORD}"
export LOGIN_ARGUMENTS="--token=${OCP_TOKEN}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${OCP_URL} ${LOGIN_ARGUMENTS}"
export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v2:${VERSION}
export COMPONENTS=ibm-cert-manager,ibm-licensing,scheduler,cpfs,cpd_platform,watson_discovery,watson_assistant

```


### 2.3 Preparing to run cpd-cli manage commands in a restricted network


1. From a workstation that can connect to the internet:

a.	Ensure that Docker or Podman is running on the workstation.
b.	Run the following command to save the olm-utils-v2 image to the client workstation:
```
cpd-cli manage save-image \
--from=icr.io/cpopen/cpd/olm-utils-v2:latest
```
This command saves the image as a compressed TAR file named icr.io_cpopen_cpd_olm-utils-v2_latest.tar.gz in the work directory.

2. Transfer the compressed file to a client workstation that can connect to the cluster.
Ensure that you place the TAR file in the work/offline directory:


3. From the workstation that can connect to the cluster:

a.	Ensure that Docker or Podman is running on the workstation.

b.	Run the following command to load the olm-utils-v2 image on the client workstation:
```
cpd-cli manage load-image \
--source-image=icr.io/cpopen/cpd/olm-utils-v2:latest
```

### 2.4 Mirroring images directly to the private container registry.

1. Log in to the IBM Entitled Registry registry:
```
cpd-cli manage login-entitled-registry \
${IBM_ENTITLEMENT_KEY}
```

2. Log in to the private container registry.
The following command assumes that you are using private container registry that is secured with credentials:
```
cpd-cli manage login-private-registry \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PUSH_USER} \
${PRIVATE_REGISTRY_PUSH_PASSWORD}
```
3. Confirm that you have access to the images that you want to mirror from the IBM Entitled Registry:
```
cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--inspect_source_registry=true
```
The output is saved to the list_images.csv file in the work/offline/${VERSION} directory.

- Check the output for errors:
```
grep "level=fatal" list_images.csv
```
4. Mirror the images to the private container registry.
```
cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--arch=${IMAGE_ARCH} \
--case_download=false
```
5. Confirm that the images were mirrored to the private container registry:
a. Inspect the contents of the private container registry:
```
cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--case_download=false
```

The output is saved to the list_images.csv file in the work/offline/${VERSION} directory.

c.	Check the output for errors:
```
grep "level=fatal" list_images.csv
```
### 2.5 Upgrading Multicloud Object Gateway

**Red Hat OpenShift Data Foundation**

If you installed Multicloud Object Gateway through Red Hat OpenShift Data Foundation Version 4.10, you must upgrade Multicloud Object Gateway.
If you installed Multicloud Object Gateway through Red Hat OpenShift Data Foundation Version 4.12, no action is required.

**IBM Storage Fusion Data Foundation**

If you installed Multicloud Object Gateway through IBM Storage Fusion Data Foundation Version 2.6.1 or later fixes, no action is required.

## Installing Red Hat OpenShift Serverless Knative Eventing (Upgrading from Version 4.7 to Version 4.8)
If your environment includes IBM® watsonx Assistant, you must install Red Hat OpenShift Serverless Knative Eventing and IBM Events on the cluster.

https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=ips-installing-red-hat-openshift-serverless-knative-eventing-1


### 2.6 Upgrading shared cluster components

**NOTE**

The location of the License Service depends on whether you installed Cloud Pak for Data with the private topology or whether you migrated to the private topology.

If you installed with the private topology, the License Service is in the project defined by the ${PROJECT_LICENSE_SERVICE} environment variable.

If you migrated to the private topology, the License Service is in the project defined by the ${PROJECT_CS_CONTROL} environment variable.

If you're not sure which project the License Service is in, run the following command:
```
oc get deployment -A |  grep ibm-licensing-operator
```
1. Log the cpd-cli in to the Red Hat OpenShift Container Platform cluster:
```
${CPDM_OC_LOGIN}
```
2. Upgrade the Certificate manager and License Service.

The command that you run depends on where the License Service is installed:

The License Service is in the ${PROJECT_LICENSE_SERVICE} project

```
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--cert_manager_ns=${PROJECT_CERT_MANAGER} \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```

The License Service is in the ${PROJECT_CS_CONTROL} project

```
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--cert_manager_ns=${PROJECT_CERT_MANAGER} \
--licensing_ns=${PROJECT_CS_CONTROL}
```
3. Confirm that the Certificate manager pods in the ${PROJECT_CERT_MANAGER} project are Running or Completed:
```
oc get pods --namespace=${PROJECT_CERT_MANAGER}
```

4. Confirm that the License Service pods are Running or Completed:

The License Service is in the ${PROJECT_LICENSE_SERVICE} project
```
 oc get pods --namespace=${PROJECT_LICENSE_SERVICE}
```

The License Service is in the ${PROJECT_CS_CONTROL} project
```
 oc get pods --namespace=${PROJECT_CS_CONTROL}
```

5. Upgrade the scheduling service:
```
cpd-cli manage apply-scheduler \
--release=${VERSION} \
--license_acceptance=true \
--scheduler_ns=${PROJECT_SCHEDULING_SERVICE}
```
6. Confirm that the scheduling service pods are Running or Completed:
```
oc get pods --namespace=${PROJECT_SCHEDULING_SERVICE}

```

### 2.7 Preparing to upgrade an instance of IBM Cloud Pak for Data


1. Run the cpd-cli manage authorize-instance-topology to apply the required permissions to the projects.
```
cpd-cli manage authorize-instance-topology \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```


### 2.8 Upgrading the IBM Cloud Pak foundational services

1. Run the cpd-cli manage setup-instance-topology command to upgrade IBM Cloud Pak foundational services.

```
cpd-cli manage setup-instance-topology \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true \
--block_storage_class=${STG_CLASS_BLOCK}
```
### 2.9 Upgrading IBM Cloud Pak for Data

1. Upgrade the operators in the operators project for the instance.

```
cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--upgrade=true
```

2. Confirm that the operator pods are Running or Copmleted:
```
oc get pods --namespace=${PROJECT_CPD_INST_OPERATORS}
```
3. Upgrade the operands in the operands project for the instance.
```
cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=cpd_platform \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true \
--upgrade=true
```
4. Confirm that the status of the operands is Completed:
```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
## Part 3: Upgrade CPD services

### Upgrading watson discovery,watson assistant

1. Log the in to the cluster:
```
${CPDM_OC_LOGIN}
```
2. Update the custom resource for watson_discovery,watson_assistant
```
cpd-cli manage apply-cr \
--components=watson_discovery,watson_assistant \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true \
--upgrade=true
```
3. Validating the upgrade
```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=watson_discovery,watson_assistant
```
