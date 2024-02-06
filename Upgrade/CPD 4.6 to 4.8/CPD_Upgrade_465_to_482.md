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
Componenets: cpfs,cpd_platform,wkc,analyticsengine,openscale
PCR
  port 5000 - openshift
  port 5001 - OLM
  port 5002 - CPD
  port 5003 - test
```

To

```
OCP: 4.12
CPD: 4.8.2
Storage: SPP ???
Componenets: ibm-cert-manager,ibm-licensing,cpfs,cpd_platform,wkc,analyticsengine,openscale
```

## Table of Content

```
Part 1: Pre-upgrade
1.1 Collect information and review upgrade runbook
1.1.1 Prepare cpd_vars.sh
1.1.2 Review the upgrade runbook
1.2 Mirror CPD images into PCR
1.2.1 Prepare a client workstation
1.2.2 Make olm-utils available in bastion
1.2.3 Mirror CPD images into PCR
1.3 Health check OCP & CPD


Part 2: Upgrade
2.1 Upgrade CPD to 4.8.1
2.1.1 Migrate to private topology
2.1.2 Preparing to upgrade an CPD instance
2.1.3 Upgrade foundation service and CPD platform to 4.8.1
2.2 Upgrade CPD services to 4.8.1

Part 3: Post-upgrade
3.1 Validate CPD & CPD services
3.2 Summarize and close out the upgrade
```

## Part 1: Pre-upgrade
### 1.1 Collect information and review upgrade runbook
#### 1.1.1 Prepare cpd_vars.sh

To upgrade from Cloud Pak for Data Version 4.6 to Version 4.8, based on the variables file for 4.6 such as cpd_vars.sh, you must update the VERSION environment variable and add several new environment variables. Update them into a cpd_vars_481.sh script like this 

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
export VERSION=4.8.1

export SERVER_ARGUMENTS="--server=${OCP_URL}"
export LOGIN_ARGUMENTS="--username=${OCP_USERNAME} --password=${OCP_PASSWORD}"
# export LOGIN_ARGUMENTS="--token=${OCP_TOKEN}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${OCP_URL} ${LOGIN_ARGUMENTS}"


export COMPONENTS=ibm-cert-manager,ibm-licensing,cpfs,cpd_platform,ws,ws_runtimes,datarefinery,dashboard,rstudio,wml,datastage_ent_plus,dv,dmc,wkc,analyticsengine

# export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpd/olm-utils-v2:latest
# export CPD_CLI_MANAGE_WORKSPACE=<enter a fully qualified directory>
```

#### 1.1.2 Review the upgrade runbook

Schedule a review meeting with SWAT team to go over the upgrade runbook

#### 1.1.3 Backup before upgrade
Note: Create a folder for 4.6.6 and maintain below created copies in that folder.

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

oc get dvservice dv-service -o yaml > dv-service-cr.yaml

oc get ae analyticsengine-sample -o yaml > analyticsengine-cr.yaml

oc get dmc data-management-console -o yaml >dmc-cr.yaml

oc get bigsql db2u-dv -o yaml > bigsql-cr.yaml
```

#### 1.1.4 (OPTIONAL)If you installed the resource specification injection (RSI) feature, uninstall the cluster-scoped webhook
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=services-uninstalling-rsi-webhook
cpd-cli manage get-rsi-patch-info --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --all
cat cpd-cli-workspace/olm-utils-workspace/work/get_rsi_patch_info.log

#### 1.1.5 (OPTIONAL) If use SAML SSO, export SSO configuration

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

Take CPD 4.8.1 as example, please change the version to what you want to download

```
mkdir -p /ibm/cpd/4.8.1
cd /ibm/cpd/4.8.1
wget https://github.com/IBM/cpd-cli/releases/download/v13.1.1/cpd-cli-linux-EE-13.1.1.tgz

tar xvf cpd-cli-linux-EE-13.1.1.tgz
mv cpd-cli-linux-EE-13.1.1-83/* .
rm -rf cpd-cli-linux-EE-13.1.1-83
```

4. Copy the cpd_vars.sh over and add path to it

```
cd /ibm/cpd/4.8.1
vi cpd_vars_481.sh
```

Add this line into the head of cpd_vars_481.sh

```
export PATH=/ibm/cpd/4.8.1:$PATH
```

Run this command to apply cpd_vars_481.sh

```
source cpd_vars_481.sh
```

Check out with this commands

```
cpd-cli version
```

Output like this

```
cpd-cli
	Version: 13.1.1
	Build Date: 2023-12-15T15:02:08
	Build Number: 83
	CPD Release Version: 4.8.1
```

#### 1.2.2 Make olm-utils available in bastion

Go to the client workstation with internet

```
cd /ibm/cpd/4.8.1
source cpd_vars_481.sh

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
cd /ibm/cpd/4.8.1
source cpd_vars_481.sh
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
tar czvf cpd-images.tar -C /ibm/cpd/4.8.1 .
```

2. Ship the tar ball into bastion node


3. Mirror CPD images into PCR in bastion node

Unpack the tar ball

```
tar xvf cpd-images.tar

source cpd_vars_481.sh
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
cpd-cli status -n <enter your Cloud Pak for Data installation project>
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

### 2.1 Upgrade CPD to 4.8.1

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
CSV name is ibm-cert-manager-operator.v4.3.0
- Confirm that the License Service pods in the ${PROJECT_CS_CONTROL} project are Running:
```
oc get pods --namespace=${PROJECT_CS_CONTROL}
``` 
CSV name is ibm-licensing-operator.v4.3.0

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

#### 2.1.3 Upgrade foundation service and CPD platform to 4.8.1
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
4.	Confirm that the operator pods are Running or Copmleted:
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
NOTE: cpd_platform has been upgraded to 4.8.1

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

### 2.2 Upgrade CPD services to 4.8.1

#### 2.2.1 Upgrade Watson Machine Learning service
```
export COMPONENTS=wml

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.2 Upgrade Watson Studio service
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
#### 2.2.3 Upgrade RStudio Server Runtimes
```
export COMPONENTS=rstudio

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.4 Upgrade Db2 Data Management Console service
```
# 1.Upgrade the service
export COMPONENTS=dmc

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}

# 2.Confirm the version of service instance is 4.8.0
oc get dmc -n ${PROJECT_CPD_INST_OPERANDS}
```
#### 2.2.5 Upgrade Watson Query service
1. Upgrade the service
```
export COMPONENTS=dv

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --components=${COMPONENTS}
```
2. Creating a profile before upgrading the service instance
```
# 1. Generate the API key that you need for user authentication by going to your Profile and settings page in the Cloud Pak for Data client and clicking Generate API key.

# 2. Set the following environment variables
export API_KEY=<api-key>
export CPD_ADMIN_USER=<user-name>
export LOCAL_USER=<local-user>
export CPD_PROFILE_NAME=<profile-name>
export CPD_PROFILE_URL=<cpd-url>

# for example
export CPD_ADMIN_USER=admin
export LOCAL_USER=admin
export CPD_PROFILE_NAME=adminProfile
export CPD_PROFILE_URL=https://<cpd_route>

# 3. Create a local user configuration to store your username and API key
cpd-cli config users set ${LOCAL_USER} \
--username ${CPD_ADMIN_USER} \
--apikey ${API_KEY}

# 4. Create a profile to store the Cloud Pak for Data URL and to associate the profile with your local user configuration.
cpd-cli config profiles set ${CPD_PROFILE_NAME} \
--user ${LOCAL_USER} \
--url ${CPD_PROFILE_URL}

# 5. Verify with the following command
cpd-cli service-instance list --service-type=dv
```

3. Upgrading the service instance
```
oc project ${PROJECT_CPD_INST_OPERANDS}

cpd-cli service-instance list --service-type=dv

# set the name of the instance that you want to upgrade
export WQ_INSTANCE_NAME=<instance-name>

export AUDIT_PVC_SIZE=30Gi

# Verify that the STG_CLASS_FILE and CPD_PROFILE_NAME environment variables are set.
echo ${STG_CLASS_FILE}
echo ${CPD_PROFILE_NAME}

# Create an instance override file for the instance that you are upgrading. Use the file name dv_override_${WQ_INSTANCE_NAME}.yaml and include the following parameters:
cat <<EOF > dv_override_${WQ_INSTANCE_NAME}.yaml
parameters:
 workerCount: $(cpd-cli service-instance get ${WQ_INSTANCE_NAME} --service-type dv --profile=${CPD_PROFILE_NAME} | grep workerCount | cut -d':' -f2 | cut -d'"' -f2)

 resources.dv.requests.cpu: $(cpd-cli service-instance get ${WQ_INSTANCE_NAME} --service-type dv --profile=${CPD_PROFILE_NAME} | grep resources.dv.requests.cpu | cut -d':' -f2 | cut -d'"' -f2)
 resources.dv.requests.memory: $(cpd-cli service-instance get ${WQ_INSTANCE_NAME} --service-type dv --profile=${CPD_PROFILE_NAME} | grep resources.dv.requests.memory | cut -d':' -f2 | cut -d'"' -f2)

 persistence.storageClass: $(cpd-cli service-instance get ${WQ_INSTANCE_NAME} --service-type dv --profile=${CPD_PROFILE_NAME} | grep persistence.storageClass | cut -d':' -f2 | cut -d'"' -f2)
 persistence.size: $(cpd-cli service-instance get ${WQ_INSTANCE_NAME} --service-type dv --profile=${CPD_PROFILE_NAME} | grep persistence.size | cut -d':' -f2 | cut -d'"' -f2)

 persistence.cachingpv.storageClass: $(cpd-cli service-instance get ${WQ_INSTANCE_NAME} --service-type dv --profile=${CPD_PROFILE_NAME} | grep persistence.cachingpv.storageClass | cut -d':' -f2 | cut -d'"' -f2)
 persistence.cachingpv.size: $(cpd-cli service-instance get ${WQ_INSTANCE_NAME} --service-type dv --profile=${CPD_PROFILE_NAME} | grep persistence.cachingpv.size | cut -d':' -f2 | cut -d'"' -f2)

 persistence.auditpv.storageClass: ${STG_CLASS_FILE}
 persistence.auditpv.size: ${AUDIT_PVC_SIZE}
EOF

# The following example shows an override file with the parameter values set:
parameters:
 workerCount: 1

 resources.dv.requests.cpu: 4
 resources.dv.requests.memory: 16Gi

 persistence.storageClass: nfs-client
 persistence.size: 50Gi

 persistence.cachingpv.storageClass: nfs-client
 persistence.cachingpv.size: 50Gi

 persistence.auditpv.storageClass: nfs-client
 persistence.auditpv.size: 30Gi

# Upgrade the instance
cpd-cli service-instance upgrade 
--instance-name=${WQ_INSTANCE_NAME} \
--service-type=dv \
--profile=${CPD_PROFILE_NAME}
--override dv_override_${WQ_INSTANCE_NAME}.yaml

# Verify the version now reads 2.2.0
cpd-cli service-instance list
oc get bigsql db2u-dv -o jsonpath='{.status.version}{"\n"}'
```

#### 2.2.6 Upgrade Watson OpenScale
```
export COMPONENTS=openscale

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.7 Upgrade Watson Pipelines
```
export COMPONENTS=ws_pipelines

cpd-cli manage apply-cr --components=${COMPONENTS} --release=${VERSION} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --license_acceptance=true --upgrade=true

cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --components=${COMPONENTS}
```
#### 2.2.8 Upgrade IBM Knowledge Catalog service
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

#### 2.2.9 Install Cognos Dashboards
1. Create the required OLM objects for Cognos Dashboards
```
cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--components=dashboard
```

2. Create the custom resource for Cognos Dashboards
```
cpd-cli manage apply-cr \
--components=dashboard \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true
```

3. Validating the installation
```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=dashboard
```

4. Post install
Setup permission: https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=dashboards-post-installation-setup

5. Migrate each existing dashboard that you created on Cognos Dashboards Version 4.6 if needed
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=dashboards-opening-from-version-46-earlier
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=dashboards-migrating-cognos-analytics

6. (Optional) Uninstall the old version

```
# Delete the custom resource for Cognos Dashboards(skip).

cpd-cli manage delete-cr \
--components=cde \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE}

# Delete the OLM objects for Cognos Dashboards

cpd-cli manage delete-olm-artifacts \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--components=cde
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

### 3.2 Summarize and close out the upgrade

Schedule a wrap-up meeting and review the upgrade procedure and lessons learned from it.

Evaluate the outcome of upgrade with pre-defined goals.

Close out the upgrade git issue.

---

End of document
