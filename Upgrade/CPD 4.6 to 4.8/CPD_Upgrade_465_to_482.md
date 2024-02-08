# Verizon CPD Upgrade Runbook

---
## Upgrade documentation
[Upgrading from IBM Cloud Pak for Data Version 4.6 to Version 4.8](
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=upgrading-from-cloud-pak-data-version-46)

## Upgrade context

From

```
OCP: 4.12
CPD: 4.6.5
Storage: SPP 10.1.12
Componenets: cpfs,cpd_platform,ws,ws_runtimes,datarefinery,wml,datastage_ent,datastage_ent_plus,dmc,wkc,analyticsengine,openscale,ws_pipelines,db2aaservice,db2oltp,db2wh,match360,mantaflow, dp
PCR
  port 5000 - openshift
  port 5001 - OLM
  port 5002 - CPD
  port 5003 - test
```

Current CR status
```
# component,CR-kind,CR-name,status,version,creationtimestamp,reconciled-version,operator-info
ws_runtimes,NotebookRuntime,ibm-cpd-ws-runtime-222-py,Completed,6.5.0,2023-06-21T21:22:17Z,6.5.0,6.5.0012
ws_runtimes,NotebookRuntime,ibm-cpd-ws-runtime-py39,Completed,5.3.0,2023-06-21T21:22:17Z,5.3.0,6.5.0012
opencontent_fdb,FdbCluster,mdm-foundationdb-1692305141878844,Completed,--,2023-08-17T20:50:57Z,--,--
opencontent_fdb,FdbCluster,wkc-foundationdb-cluster,Completed,--,2023-07-12T19:31:33Z,--,--
match360,MasterDataManagement,mdm-cr,Completed,2.3.29,2023-08-17T20:44:45Z,--,--
db2wh,Db2whService,db2wh-cr,Completed,4.6.4,2023-06-21T21:20:54Z,4.6.4+11.5.8.0-cn2+2039,4.6.4+11.5.8.0-cn2+2039
datastage_ent_plus,DataStage,datastage,Completed,4.6.5,2023-06-21T21:20:53Z,--,--
datastage_ent,DataStage,datastage,Completed,4.6.5,2023-06-21T21:20:53Z,--,--
openscale,WOService,aiopenscale,Completed,4.6.5,2023-06-21T21:22:46Z,4.6.5,105
openscale,WOService,openscale-defaultinstance,Completed,4.6.5,2023-06-21T21:22:46Z,4.6.5,105
openscale,WOService,vzopenscaledev,Completed,4.6.5,2023-06-21T21:22:46Z,4.6.5,105
dp,DP,dp-cr,Completed,4.6.5,2023-06-21T21:21:00Z,4.6.5,1482
wkc,WKC,wkc-cr,Completed,4.6.5,2023-06-21T21:22:46Z,--,--
wml,WmlBase,wml-cr,Completed,4.6.5,2023-06-21T21:22:46Z,4.6.5,4.6.5-4816
ws,WS,ws-cr,Completed,6.5.0,2023-06-21T21:22:46Z,6.5.0,20
db2aaservice,Db2aaserviceService,db2aaservice-cr,Completed,4.6.4,2023-06-21T21:20:53Z,4.6.4+11.5.8.0-cn2+2039,4.6.4+11.5.8.0-cn2+2039
datarefinery,DataRefinery,datarefinery-sample,Completed,6.5.0,2023-06-21T21:20:53Z,--,--
analyticsengine,AnalyticsEngine,analyticsengine-sample,Completed,4.6.5,2023-06-21T21:20:33Z,4.6.5,1507
ccs,CCS,ccs-cr,Completed,6.5.0,2023-06-21T21:20:34Z,6.5.0,132
cpd_platform,Ibmcpd,ibmcpd-cr,Completed,4.6.5,2023-06-21T21:21:19Z,--,--
zen,ZenService,lite-cr,Completed,4.8.3,2023-06-21T21:22:47Z,4.8.3,zen operator 1.8.3 build 26
```
Current IAM and SAML setup
```
export ZEN_NAMESPACE=<cpd/wkc namespace>
oc -n ${ZEN_NAMESPACE} get zenservice lite-cr -o jsonpath="{.spec.iamIntegration}{'\n'}"

oc exec -it -n ${ZEN_NAMESPACE} \
$(oc get pod -n ${ZEN_NAMESPACE} -l component=ibm-nginx | tail -1 | cut -f1 -d\ ) \
-- bash -c "ls -al /user-home/_global_/config/saml/samlConfig.json"
```
![IAM, SAML Setup on 4.6.5](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/images/IAM-SAML-465-setup.png)

To

```
OCP: 4.12
CPD: 4.8.2
Storage: SPP ???
Componenets: ibm-cert-manager,ibm-licensing,cpfs,cpd_platform,ws,ws_runtimes,datarefinery,wml,datastage_ent,datastage_ent_plus,dmc,wkc,analyticsengine,openscale,ws_pipelines,db2aaservice,db2oltp,db2wh,match360,mantaflow,dp
```

## Table of Content

```
Part 1: Pre-upgrade
1.1 Collect information and review upgrade runbook
1.1.1 Prepare cpd_vars.sh
1.1.2 Review the upgrade runbook
1.1.3 Backup before upgrade
1.1.4 If you installed the resource specification injection (RSI) feature, uninstall the cluster-scoped webhook
1.1.5 if you installed hotfixes, uninstall all hotfixes
1.2 Mirror CPD images into PCR
1.2.1 Prepare a client workstation
1.2.2 Make olm-utils available in bastion
1.2.3 Mirror CPD images into PCR
1.3 Health check OCP & CPD


Part 2: Upgrade
2.1 Upgrade CPD to 4.8.2
2.1.1 Migrate to private topology
2.1.2 Preparing to upgrade an CPD instance
2.1.3 Upgrade foundation service and CPD platform to 4.8.2
2.2 Upgrade CPD services to 4.8.2

Part 3: Post-upgrade
3.1 Validate CPD & CPD services
3.2 Summarize and close out the upgrade
```

## Part 1: Pre-upgrade
### 1.1 Collect information and review upgrade runbook
#### 1.1.1 Prepare cpd_vars.sh

To upgrade from Cloud Pak for Data Version 4.6 to Version 4.8, based on the variables file for 4.6 such as cpd_vars.sh, you must update the VERSION environment variable and add several new environment variables. Update them into a cpd_vars_482.sh script like this 

```
export PROJECT_CPFS_OPS=ibm-common-services
export PROJECT_CPD_OPS=ibm-common-services
export PROJECT_CPD_INSTANCE=cpd-instance

export PROJECT_CERT_MANAGER=ibm-cert-manager
export PROJECT_LICENSE_SERVICE=ibm-licensing
export PROJECT_CS_CONTROL=cs-control
# export PROJECT_SCHEDULING_SERVICE=cpd-scheduler
export PROJECT_CPD_INST_OPERATORS=cpd-operators
export PROJECT_CPD_INST_OPERANDS=cpd-instance
export VERSION=4.8.2

export SERVER_ARGUMENTS="--server=${OCP_URL}"
export LOGIN_ARGUMENTS="--username=${OCP_USERNAME} --password=${OCP_PASSWORD}"
# export LOGIN_ARGUMENTS="--token=${OCP_TOKEN}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${OCP_URL} ${LOGIN_ARGUMENTS}"

# export COMPONENTS=ibm-cert-manager,ibm-licensing,cpfs,cpd_platform,ws,ws_runtimes,datarefinery,wml,datastage_ent,datastage_ent_plus,dmc,wkc,analyticsengine,openscale,ws_pipelines,db2aaservice,db2oltp,db2wh,match360,mantaflow,dp

export COMPONENTS=ibm-cert-manager,ibm-licensing,cpfs,cpd_platform,ws,ws_runtimes,datarefinery,wml,datastage_ent,datastage_ent_plus,dmc,wkc,analyticsengine,openscale,db2aaservice,db2oltp,db2wh,match360,dp
# export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpd/olm-utils-v2:latest
# export CPD_CLI_MANAGE_WORKSPACE=<enter a fully qualified directory>
```

#### 1.1.2 Review the upgrade runbook

Review upgrade runbook

#### 1.1.3 Backup before upgrade
Note: Create a folder for 4.6.5 and maintain below created copies in that folder.

Make a copy of existing catalog sources (Recommended)

```
for CS in $(oc get catsrc -n ${PROJECT_CATSRC} | awk '/IBM|MANTA/ {print $1}')
do
   oc get catsrc -n ${PROJECT_CATSRC} ${CS} -o yaml >${CS}-catsrc.yaml
done
```

Make a copy of existing subscriptions (Recommended)

```
for SUB in $(oc get subs -n ${PROJECT_CPFS_OPS} | awk '!/NAME/{print $1}')
do
   oc get subs -n ${PROJECT_CPFS_OPS} ${SUB} -o yaml >${SUB}-sub.yaml
done
```

Make a copy of existing custom resources (Recommended)

```
oc project ${PROJECT_CPD_INSTANCE}

oc get ibmcpd ibmcpd-cr -o yaml > ibmcpd-cr.yaml

oc get zenservice lite-cr -o yaml > lite-cr.yaml

oc get wkc wkc-cr -o yaml > wkc-cr.yaml

oc get ae analyticsengine-sample -o yaml > analyticsengine-cr.yaml
```

#### 1.1.4 if you installed hotfixes, uninstall all hotfixes
Edit Zensevice, CCS, WKC, AE custom resources and remove all hotfix references.

#### 1.1.5 If you installed the resource specification injection (RSI) feature, uninstall the cluster-scoped webhook
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=services-uninstalling-rsi-webhook
```
cpd-cli manage get-rsi-patch-info --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --all
cat cpd-cli-workspace/olm-utils-workspace/work/get_rsi_patch_info.log
```
_**We need disabled the RSI patches and post install enabled them**_

#### 1.1.6 If use SAML SSO, export SSO configuration

If you use SAML SSO, export your SSO configuration. You will need to reapply your SAML SSO configuration after you upgrade to Version 4.8. Skip this step if you use the IBM Cloud Pak foundational services Identity Management Service

```
oc cp -n=${PROJECT_CPD_INSTANCE} $(oc get pods -l component=usermgmt -n ${PROJECT_CPD_INSTANCE} -o jsonpath='{.items[0].metadata.name}'):/user-home/_global_/config/saml ./samlConfig.json
```

### 1.2 Mirror CPD images into PCR

#### 1.2.1 Prepare a client workstation

You need a client workstation with internet to pull OCP & CPD images, then ship the images into PCR(Private Container Registry) on bastion node, which is in a restricted network, to upgrade OCP & CPD.

1. Prepare a RHEL 8 machine with internet

2. Install tools

```
yum install openssl httpd-tools podman skopeo wget -y
```

3. Download and setup CPD CLI

Take CPD 4.8.2 as example, please change the version to what you want to download

```
mkdir -p /ibm/cpd/4.8.2
cd /ibm/cpd/4.8.2
wget https://github.com/IBM/cpd-cli/releases/download/v13.1.2/cpd-cli-linux-EE-13.1.2.tgz

tar xvf cpd-cli-linux-EE-13.1.2.tgz
mv cpd-cli-linux-EE-13.1.2-89/* .
rm -rf cpd-cli-linux-EE-13.1.2-89
```

4. Copy the cpd_vars.sh over and add path to it

```
cd /ibm/cpd/4.8.2
vi cpd_vars_482.sh
```

Add this line into the head of cpd_vars_482.sh

```
export PATH=/ibm/cpd/4.8.2:$PATH
```

Run this command to apply cpd_vars_482.sh

```
source cpd_vars_482.sh
```

Check out with this commands

```
cpd-cli version
```

Output like this

```
cpd-cli
	Version: 13.1.2
	Build Date: 
	Build Number: 89
	CPD Release Version: 4.8.2
```

#### 1.2.2 Make olm-utils available in bastion

Go to the client workstation with internet

```
cd /ibm/cpd/4.8.2
source cpd_vars_482.sh

cpd-cli manage save-image \
--from=icr.io/cpopen/cpd/olm-utils-v2:latest
```

This command saves the image as a compressed TAR file named icr.io_cpopen_cpd_olm-utils-v2_latest.tar.gz in the cpd-cli-workspace/olm-utils-workspace/work/offline directory

Ship the tarbll into bastion node

Go to bastion node

```
cpd-cli manage load-image \
--source-image=icr.io/cpopen/cpd/olm-utils-v2:latest
```

The command returns the following message when the image is loaded:

```
Loaded image: icr.io/cpopen/cpd/olm-utils-v2:latest
```

For details please refer to 4.8 doc (https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=pruirn-obtaining-olm-utils-v2-image)

#### 1.2.3 Mirror CPD images into PCR

1. Mirror CPD images into intermediary registry

Go to the client workstation with internet

```
cd /ibm/cpd/4.8.2
source cpd_vars_482.sh
```

Log into IBM registry and list images

```
cpd-cli manage login-entitled-registry \
${IBM_ENTITLEMENT_KEY}
```

Download case package from either of the following locations:
```
# GitHub (github.com)
cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION}

# IBM Cloud Pak Open Container Initiative (icr.io)
cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION} \
--from_oci=true
```

List images

```
export COMPONENTS=ibm-cert-manager,ibm-licensing,cpfs,cpd_platform

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--inspect_source_registry=true

grep "level=fatal" cpd-cli-workspace/olm-utils-workspace/work/offline/${VERSION}/list_images.csv
```

Note: Make sure this command return no authorization errors or network errors

Mirror images

```
cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=127.0.0.1:12443 \
--arch=${IMAGE_ARCH} \
--case_download=false

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=127.0.0.1:12443 \
--case_download=false

grep "level=fatal" cpd-cli-workspace/olm-utils-workspace/work/offline/${VERSION}/list_images.csv
```

Note: Make sure this command return no authorization errors or network errors

Repeat above steps to list and mirror other component images and it is recommended to miror component one by one (ws,ws_runtimes,datarefinery,cde,rstudio,wml,datastage_ent_plus,dv,dmc,wkc,analyticsengine)

```
export COMPONENTS=<component_id>
```

E.g.

```
export COMPONENTS=ws
```

Make a tar ball to have all downloaded images

```
tar czvf cpd-images.tar -C /ibm/cpd/4.8.2 .
```

2. Ship the tar ball into bastion node


3. Mirror CPD images into PCR in bastion node

Unpack the tar ball

```
tar xvf cpd-images.tar

source cpd_vars_482.sh
```

Log into PCR

```
cpd-cli manage login-private-registry \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PUSH_USER} \
${PRIVATE_REGISTRY_PUSH_PASSWORD}
```

Mirror images to PCR

```
export COMPONENTS=ibm-cert-manager,ibm-licensing,cpfs,cpd_platform

cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--source_registry=127.0.0.1:12443 \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--arch=${IMAGE_ARCH} \
--case_download=false

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--case_download=false

grep "level=fatal" cpd-cli-workspace/olm-utils-workspace/work/offline/${VERSION}/list_images.csv
```

Note: Make sure this command return no authorization errors or network errors

Repeat above steps to mirror other component images and it is recommended to miror component one by one

```
export COMPONENTS=<component_id>
```

E.g.

```
export COMPONENTS=ws
```

4. Update image pull secret and config image content source policy

Log into OCP

```
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}
```

Update the global image pull secret

```
cpd-cli manage add-cred-to-global-pull-secret \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PULL_USER} \
${PRIVATE_REGISTRY_PULL_PASSWORD}
```

Apply image content source policy

```
cpd-cli manage apply-icsp \
${PRIVATE_REGISTRY_LOCATION}
```

Watch node update until all ready

```
watch oc get nodes
```

For details please refer to 4.8 doc (https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=mipcr-mirroring-images-using-intermediary-container-registry)

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
cpd-cli manage get-cr-status -n <enter your Cloud Pak for Data installation project>
```

Run this command and make sure all pods healthy.

```
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[:digit:]])/\1.*R' | grep -v 'Completed'
```

3. Check private container registry status if installed

Log into bastion node, where the private container registry is usually installed, as root.
Run this command in terminal and make sure it is succeed.

```
podman login --username $PRIVATE_REGISTRY_USER --password $PRIVATE_REGISTRY_PASSWORD $PRIVATE_REGISTRY --tls-verify=false
```

You can run this command to verify the images in private container registry.

```
curl -k -u ${PRIVATE_REGISTRY_USER}:${PRIVATE_REGISTRY_PASSWORD} https://${PRIVATE_REGISTRY}/v2/_catalog?n=6000 | jq .
```

4. Check out all pods

```

oc get po --no-headers --all-namespaces -o wide| grep -Ev '1/1|2/2|3/3|4/4|5/5|6/6|7/7|8/8|9/9|10/10|Completed' > unhealthypods.txt
```

Make sure there is no pod listed in  unhealthypods.txt




## Part 2: Upgrade

### 2.1 Upgrade CPD to 4.8.2

#### 2.1.1 Migrate to private topology
1. Create new projects
```
${OC_LOGIN}
oc new-project ${PROJECT_CS_CONTROL}             # This is for ibm-licensing operator and instance
oc new-project ${PROJECT_CERT_MANAGER}           # This is for ibm-cert-manager operator and instance
oc new-project ${PROJECT_CPD_INST_OPERATORS}     # This is for migrated cpd operator
# oc new-project ${PROJECT_SCHEDULING_SERVICE}     # This is for ibm-scheduling operator and instance
```
2.	Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}

# or
${CPDM_OC_LOGIN}
```
3.	Move the Certificate manager and License Service from the shared operators project to the cs-control project.
```
cpd-cli manage detach-cpd-instance --cpfs_operator_ns=${PROJECT_CPFS_OPS} --control_ns=${PROJECT_CS_CONTROL}
```
- Wait for the cpd-cli to return the following message before proceeding to the next step:
```
[SUCCESS] ... The detach-cpd-instance command ran successfully.
```
- Confirm that the Certificate manager and License Service pods in the cs-control project are Running :
```
oc get pods --namespace=${PROJECT_CS_CONTROL}
```
4. Upgrade the Certificate manager and License Service

The Certificate manager will be moved to the {PROJECT_CERT_MANAGER} project. The License Service will remain in the cs-control {PROJECT_CS_CONTROL} project.
```
cpd-cli manage apply-cluster-components --release=${VERSION} --license_acceptance=true --migrate_from_cs_ns=${PROJECT_CPFS_OPS} --cert_manager_ns=${PROJECT_CERT_MANAGER} --licensing_ns=${PROJECT_CS_CONTROL}
```
- Confirm that the Certificate manager pods in the ${PROJECT_CERT_MANAGER} project are Running:
```
oc get pod -n ${PROJECT_CERT_MANAGER}
```
CSV name is ibm-cert-manager-operator.~~v4.3.0~~  **<- Need to check**
- Confirm that the License Service pods in the ${PROJECT_CS_CONTROL} project are Running:
```
oc get pods --namespace=${PROJECT_CS_CONTROL}
``` 
CSV name is ibm-licensing-operator.~~v4.3.0~~  **<- Need to check**

5. (Optional) If the scheduling service is installed, migrate and upgrade the scheduling service.
```
cpd-cli manage migrate-scheduler \
--release=${VERSION} \
--license_acceptance=true \
--from_ns=${PROJECT_CPFS_OPS} \
--to_ns=${PROJECT_SCHEDULING_SERVICE}
```
Confirm that the scheduling service pods in the ${PROJECT_SCHEDULING_SERVICE} project are Running or Completed:
```
oc get pods --namespace=${PROJECT_SCHEDULING_SERVICE}
```

#### 2.1.2 Preparing to upgrade an CPD instance
1.	Detache CPD instance from the shared operators
```
cpd-cli manage detach-cpd-instance --cpfs_operator_ns=${PROJECT_CPFS_OPS} --control_ns=${PROJECT_CS_CONTROL}  --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

- Confirm ${PROJECT_CPD_INST_OPERANDS} has been isolated from the previous nss

``` 
oc get cm -n $PROJECT_CPFS_OPS namespace-scope -o yaml
``` 
Result example:
``` 
Name:         namespace-scope
Namespace:    ibm-common-services
Labels:       <none>
Annotations:  <none>

Data
====
namespaces:
----
ibm-common-services #<- original $PROJECT_CPD_INSTANCE (cpd-instance) should NOT appear here
...
``` 

2.	Apply the required permissions to the projects
```
cpd-cli manage authorize-instance-topology --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --preview=true

cpd-cli manage authorize-instance-topology --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

#### 2.1.3 Upgrade foundation service and CPD platform to 4.8.2
1.	Run the cpd-cli manage login-to-ocp command to log in to the cluster.
```
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}
```
2.	upgrade IBM Cloud Pak foundational services and create the required ConfigMap.
```
cpd-cli manage setup-instance-topology --release=${VERSION} --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true
```

- Confirm common-service, namespace-scope, opencloud and odlm operator migrated to ${PROJECT_CPD_INST_OPERATORS} namespace
```
oc get pod -n ${PROJECT_CPD_INST_OPERATORS}
```
3.	Upgrade the operators in the operators project for CPD instance
```
cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--upgrade=true
```
4.	Confirm that the operator pods are Running or Copmpleted:
NOTE: You will find cpd component operator and catalogsource migrated to ${PROJECT_CPD_INST_OPERATORS} namespace
```
oc get pods --namespace=${PROJECT_CPD_INST_OPERATORS}
```

WARNING: This step will ask you to validated that your WKC legacy data can be migrated
If you want to continue with the migration, please type: 'I have validated that I can migrate my metadata and I want to continue'

- Check the version, refer to the following operator version

```
Catalogsource                                Operator version    Operand version                     
cpd-platform                                 5.1.0               4.8.1
opencloud-operators                          4.3.0               4.3.0
ibm-cpd-ws-operator-catalog                  8.1.0               8.1.0
ibm-cpd-ws-runtimes-operator-catalog         8.1.0               8.1.0
ibm-cpd-wml-operator-catalog                 5.1.0               4.8.1
ibm-cpd-wkc-operator-catalog                 1.8.1               4.8.1
ibm-cpd-ae-operator-catalog                  5.1.0               4.8.1
ibm-cpd-datarefinery-operator-catalog        8.1.0               8.1.0
ibm-cpd-datastage-operator-catalog           5.1.0               4.8.1
ibm-dv-operator-catalog                      4.0.0               2.2.0
ibm-dmc-operator-catalog                     4.0.0               4.8.0   
ibm-cpd-rstudio-operator-catalog             8.1.0               8.1.0
ibm-cpd-ccs-operator-catalog                 8.1.0               8.1.0
ibm-db2aaservice-cp4d-operator-catalog       5.0.0               4.8.0
ibm-db2uoperator-catalog                     5.0.0               11.5.8.0-cn6
ibm-elasticsearch-catalog                    1.1.1845            1.1.1845
ibm-fdb-operator-catalog                     3.1.6               3.1.6
ibm-cloud-databases-redis-operator-catalog   1.6.11
ibm-dashboard-operator-catalog               2.1.0               4.8.1
```

5.	Upgrade the operands in the operands project for CPD instance
```
cpd-cli manage apply-cr --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=cpd_platform --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

oc logs -f cpd-platform-operator-manager-XXXX-XXXX -n ${PROJECT_CPD_INST_OPERATORS}
```
6.	Confirm that the status of the operands is Completed:
```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
NOTE: cpd_platform has been upgraded to 4.8.2

7.	Clean up any failed operand requests in the operands project:

-	Get the list of operand requests with the format -requests-:
```
oc get operandrequest --namespace=${PROJECT_CPD_INST_OPERANDS} | grep requests
```
-	Delete each operand request in the Failed state: Replace with the name of operand request to delete.
```
oc delete operandrequest <operand-request-name>
--namespace=${PROJECT_CPD_INST_OPERANDS}
```
8.	Remove the instance project from the sharewith list in the ibm-cpp-config SecretShare in the shared IBM Cloud Pak foundational services operators project:
•	Confirm the name of the instance project:
```
echo $PROJECT_CPD_INST_OPERANDS
```
- Check whether the instance project is listed in the sharewith list in the ibm-cpp-config SecretShare:
```
 oc get secretshare ibm-cpp-config \
--namespace=${PROJECT_CPFS_OPS} \
-o yaml
```
The command returns output with the following format:
```
apiVersion: ibmcpcs.ibm.com/v1
kind: SecretShare
metadata:
  name: ibm-cpp-config
  namespace: ibm-common-services
spec:
  configmapshares:
  - configmapname: ibm-cpp-config
    sharewith:
    - namespace: cpd-instance-x
    - namespace: ibm-common-services
    - namespace: cpd-operators
    - namespace: cpd-instance-y
```
If the instance project is in the list, proceed to the next step. If the instance is not in the list, no further action is required.
-	Open the ibm-cpp-config SecretShare in the editor:
```
oc edit secretshare ibm-cpp-config \
--namespace=${PROJECT_CPFS_OPS}
```
- Remove the entry for the instance project from the sharewith list and save your changes to the SecretShare.

### 2.2 Upgrade CPD services to 4.8.2
#### 2.2.1 Upgrade IBM Knowledge Catalog service
WARNING: If you need to migrate WKC legacy feature data, install and follow the steps for the patch here (https://www.ibm.com/support/pages/node/7003929#4.8.1). Make sure you have exported the legacy data using cpd-cli export-import command, before doing the upgrade in this section. Note that this migration feature will be ready after 4.7.0.
```
# 1. For custom installation, check the previous install-options.yaml or wkc-cr yaml, make sure to keep original custom settings
vim cpd-cli-workspace/olm-utils-workspace/work/install-options.yml
################################################################################
# IBM Knowledge Catalog parameters
################################################################################
custom_spec:
  wkc:
#    enableKnowledgeGraph: False
#    enableDataQuality: False

# 2.Upgrade WKC instance with default or custom installation
export COMPONENTS=wkc

# Custom installation (with installation options)
cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --param-file=/tmp/work/install-options.yml --license_acceptance=true --upgrade=true

# Default installation (without installation options)
cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}

# NOTE: wkc and analyticsengine,datastage_ent_plus have been upgraded to 4.8.1, db2aaservice to 4.8.0, datarefinery to 8.1.0

# OPTIONAL: Check Post-upgrade tasks of wkc here https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=u-upgrading-from-version-46-20#cli-upgrade__next-steps
```
#### 2.2.2 Upgrade Watson Machine Learning service
```
export COMPONENTS=wml

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.3 Upgrade Watson Studio service
```
export COMPONENTS=ws

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
Upgrade all installed Watson Studio Runtimes:
```
export COMPONENTS=ws_runtimes
cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}
```
#### 2.2.4 Upgrade Data Privacy
```
export COMPONENTS=dp

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.5 Upgrade Db2 Data Management Console service
```
# 1.Upgrade the service
export COMPONENTS=dmc

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}

# 2.Confirm the version of service instance is 4.8.0
oc get dmc -n ${PROJECT_CPD_INST_OPERANDS}
```
#### 2.2.6 Upgrade Db2 Warehouse
```
# 1.Upgrade the service
export COMPONENTS=db2wh

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}

# 2. Upgrading Db2 Warehouse service instances
# 2.1. Get a list of your Db2 Warehouse service instances
cpd-cli service-instance list --profile=${CPD_PROFILE_NAME} --service-type=${COMPONENTS}

# 2.2. If you have applied any custom patches to override scripts, remove them. This will restart Db2 Warehouse pods. 
oc set volume statefulset/c-${DB2U_ID}-db2u -n ${PROJECT_CPD_INST_OPERANDS} --remove --name=<volume_name>

# 2.3. Upgrade Db2 Warehouse service instances
cpd-cli service-instance upgrade --profile=${CPD_PROFILE_NAME} --instance-name=${INSTANCE_NAME} --service-type=${COMPONENTS}

# 3. Verifying the service instance upgrade
# 3.1. Wait for the status to change to Ready
oc get db2ucluster <instance_id> -o jsonpath='{.status.state} {"\n"}'

3.2. Check the service instances have updated
cpd-cli service-instance list --profile=${CPD_PROFILE_NAME} --service-type=${COMPONENTS}
```
#### 2.2.7 Upgrade Db2 OLTP
```
# 1.Upgrade the service
export COMPONENTS=db2oltp

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}

# 2. Upgrading Db2 Warehouse service instances
# 2.1. Get a list of your Db2 Warehouse service instances
cpd-cli service-instance list --profile=${CPD_PROFILE_NAME} --service-type=${COMPONENTS}

# 2.2. If you have applied any custom patches to override scripts, remove them. This will restart Db2 pods. 
oc set volume statefulset/c-${DB2U_ID}-db2u -n ${PROJECT_CPD_INST_OPERANDS} --remove --name=<volume_name>

# 2.3. Upgrade Db2 Warehouse service instances
cpd-cli service-instance upgrade --profile=${CPD_PROFILE_NAME} --instance-name=${INSTANCE_NAME} --service-type=${COMPONENTS}

# 3. Verifying the service instance upgrade
# 3.1. Wait for the status to change to Ready
oc get db2ucluster <instance_id> -o jsonpath='{.status.state} {"\n"}'

3.2. Check the service instances have updated
cpd-cli service-instance list --profile=${CPD_PROFILE_NAME} --service-type=${COMPONENTS}
```
#### 2.2.8 Upgrade Watson OpenScale
```
export COMPONENTS=openscale

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.9 Upgrade Watson Pipelines
```
export COMPONENTS=ws_pipelines

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.10 Upgrade Match 360
```
export COMPONENTS=match360

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.11 Upgrade DataStage edition plus
```
export COMPONENTS=datastage_ent_plus

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
### 2.3 Remove the shared operators
Complete this task only if all of the instances of Cloud Pak for Data are upgraded to Version 4.8.
If any of the instances have not been upgraded and migrated to the private topology, the instances will stop working.

```
# Log in to the cluster
${CPDM_OC_LOGIN}

# Delete the shared OLM objects.

cpd-cli manage delete-olm-artifacts \
--cpd_operator_ns=ibm-common-services \
--delete_all_components=true \
--delete_shared_catsrc=true
```

## Part 3: Post-upgrade

### 3.1 Validate CPD & CPD services

Log into CPD web UI with admin and check out each services, including provision instance and functions of each service

### 3.2 Enable RSI patches

### 3.3 Enable Relationship Explorer feature
[Enable Relationship Explorer feature](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/Upgrade/CPD%204.6%20to%204.8/Enabling_Relationship_Explorer_480%20-%20disclaimer%200208.pdf)

### 3.x Summarize and close out the upgrade

Schedule a wrap-up meeting and review the upgrade procedure and lessons learned from it.

Evaluate the outcome of upgrade with pre-defined goals.

Close out the upgrade git issue.

---

End of document
