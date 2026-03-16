
# CPD Upgrade From 5.2.0 to 5.3.1

## Upgrade Context
- **OCP:** 4.16
- **CPD:** 5.2.0 → 5.3.1
- **Storage:** NFS
- **Components:** ibm-licensing, cpfs, cpd_platform, wkc, datastage_ent, analyticsengine, datalineage, ikc_standard, ikc_premium, semantic_automation
- **Airgapped:** Yes

# Table of Contents
- 1. Pre-upgrade
- 2. Upgrade
- 3. Post-upgrade tasks

# 1. Pre-upgrade
## 1.1 Checking the health of your cluster
```
cpd-cli health cluster
cpd-cli health nodes
cpd-cli health operators --operator_ns=${PROJECT_CPD_INST_OPERATORS} --control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
cpd-cli health operands --control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

## 1.2 Health check OCP & CPD
```
${OC_LOGIN}
oc get nodes,co,mcp

${CPDM_OC_LOGIN}
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[digit:]])/\1.*R' | grep -v 'Completed'
```

## 1.3 Backup before upgrade
Note: Create a folder for 5.2.0 and maintain below created copies in that folder.
Login to the OCP cluster for cpd-cli utility.
```
cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}
```
### 1.3.1 Capture data for the CPD 5.2.0 instance. 
No sensitive information is collected. Only the operational state of the Kubernetes artifacts is collected. The output of the command is stored in a file named collect-state.tar.gz in the cpd-cli-workspace/olm-utils-workspace/work directory.
```
cpd-cli manage collect-state --cpd_instance_ns=${PROJECT_CPD_INSTANCE}
```
### 1.3.2 Make a copy of existing custom resources (Recommended)
```
oc project ${PROJECT_CPD_INSTANCE}

oc get ibmcpd ibmcpd-cr -o yaml > ibmcpd-cr.yaml

oc get zenservice lite-cr -o yaml > lite-cr.yaml

oc get CCS ccs-cr -o yaml > ccs-cr.yaml

oc get wkc wkc-cr -o yaml > wkc-cr.yaml

oc get analyticsengine analyticsengine-sample -o yaml > analyticsengine-cr.yaml

oc get DataStage datastage -o yaml > datastage-cr.yaml

oc get route -o yaml > cpd_routes.yaml
```

### 1.3.3 Backup the routes.
```
oc get routes -o yaml > routes.yaml
```

### 1.3.4 Backup the RSI patches.
```
cpd-cli manage get-rsi-patch-info \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--all
```

## 1.4 Update the cpd-cli utility
```
wget https://github.com/IBM/cpd-cli/releases/download/v14.3.1/cpd-cli-linux-EE-14.3.1.tgz
tar -xvf cpd-cli-linux-EE-14.3.1.tgz
```
Ensure the cpd-cli manage plug-in has the latest olm-utils image.
Check and confirm the olm-utils-v4 container is up and running.
```
cpd-cli manage restart-container
podman ps | grep olm-utils-v4
```

## 1.5 Install Helm CLI
Install Helm by following the https://www.ibm.com/links?url=https%3A%2F%2Fhelm.sh%2Fdocs%2Fintro%2Finstall%2F

```
sudo dnf install helm
```

## 1.6 Updating your environment variables script
Make a copy of the environment variables script used by the existing 5.2.0 variables with the name like cpd_vars_531.sh.

Update the environment variables script cpd_vars_531.sh as follows.
```
vi cpd_vars_531.sh
```
1. Locate the VERSION entry and update the environment variable for VERSION.
```
export VERSION=5.3.1
```
2. Locate the COMPONENTS entry and confirm the COMPONENTS entry is accurate.
```
export COMPONENTS=ibm-licensing,cpfs,cpd_platform,wkc,datastage_ent, analyticsengine,datalineage,ikc_standard,ikc_premium,semantic_automation
```
3. Add a new section called Image pull configuration to your script and add the following environment variables
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=cri-updating-your-environment-variables-script
```
export IMAGE_PULL_SECRET=${IBM_ENTITLEMENT_KEY}
export IMAGE_PULL_CREDENTIALS=$(echo -n "$PRIVATE_REGISTRY_PULL_USER:$PRIVATE_REGISTRY_PULL_PASSWORD" | base64 -w 0)
export IMAGE_PULL_PREFIX=${PRIVATE_REGISTRY_LOCATION}
```
4. Locate the OLM_UTILS_IMAGE entry and update the value
```
export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
export OLM_UTILS_LAUNCH_ARGS=" --network=host"
```
5. Save the changes. 

6. Confirm that the script does not contain any errors.
```
bash ./cpd_vars_531.sh
```
7. Run this command to apply cpd_vars_531.sh
```
source ./cpd_vars_531.sh
```

## 1.7 Mirror CPD 5.3.1 images
### 1.7.1 Obtaining the olm-utils-v4 image
```
podman pull cp.icr.io/cp/cpd/olm-utils-premium-v4:${VERSION}.amd64 --tls-verify=false

podman login ${PRIVATE_REGISTRY_LOCATION} -u ${PRIVATE_REGISTRY_PUSH_USER} -p ${PRIVATE_REGISTRY_PUSH_PASSWORD}

podman tag cp.icr.io/cp/cpd/olm-utils-premium-v4:${VERSION}.amd64 ${PRIVATE_REGISTRY_LOCATION}/cp/cpd/olm-utils-premium-v4:${VERSION}.amd64 

podman push ${PRIVATE_REGISTRY_LOCATION}/ cp/cpd/olm-utils-premium-v4:${VERSION}.amd64
```
### 1.7.2 Downloading CASE packages 
```
./cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION}
```

### 1.7.3 Mirroring images directly to the private container registry
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=mipcr-mirroring-images-directly-private-container-registry-1

Log in to the IBM Entitled registry:
```
./cpd-cli manage login-entitled-registry ${IBM_ENTITLEMENT_KEY}
```
Log in to the private container registry.

The following command assumes that you are using a private container registry that is secured with credentials:
```
./cpd-cli manage login-private-registry \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PUSH_USER} \
${PRIVATE_REGISTRY_PUSH_PASSWORD}

./cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--arch=${IMAGE_ARCH} \
--case_download=false
```

## 1.8 Final checks before start the upgrade
### 1.8.1 Pre-upgade check 
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=hub-upgrading-software

### 1.8.2 Uninstall all hotfixes
Needs to check all CRs for any custom image used.

### 1.8.3 Backup the RSI patches
```
cpd-cli manage get-rsi-patch-info \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--all
```
### 1.8.4 Final health check OCP & CPD
Check OCP status
Log onto the bastion node, in the termial log into OCP and run this command.
```
oc get co
```
Make sure all the cluster operators are in AVAILABLE status. And not in PROGRESSING or DEGRADED status.
Run this command and make sure all nodes are in Ready status.
```
oc get nodes
```
Run this command and make sure all the machine configuretion pool are in a healthy status.
```
oc get mcp
```
Check Cloud Pak for Data status
Log onto the bastion node, and make sure the IBM Cloud Pak for Data command-line interface is installed properly.
Run this command in the terminal and make sure the Lite and all the services' status are in Ready status.
```
${CPDM_OC_LOGIN}
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
Run this command and make sure all pods are healthy.
```
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[:digit:]])/\1.*R' | grep -v 'Completed'
```
Check the private container registry status if installed
Log into bastion node, where the private container registry is usually installed, as root. Run this command in the terminal and make sure it succeeds.
```
podman login --username $PRIVATE_REGISTRY_PULL_USER --password $PRIVATE_REGISTRY_PULL_PASSWORD $PRIVATE_REGISTRY_LOCATION --tls-verify=false
```
You can run this command to verify the images are in the private container registry.
```
curl -k -u ${PRIVATE_REGISTRY_PULL_USER}:${PRIVATE_REGISTRY_PULL_PASSWORD} https://${PRIVATE_REGISTRY_LOCATION}/v2/_catalog?n=6000 | jq .
```

# 2. Upgrade
## 2.1 Migrate to Red Hat OpenShift certificate manager
Documentation links preserved.

## 2.2 Upgrade shared cluster components
```
oc get deployment -A | grep ibm-licensing-operator
./cpd-cli manage apply-cluster-components --release=${VERSION} --license_acceptance=true --licensing_ns=${PROJECT_LICENSE_SERVICE}
```

## 2.4 Prepare to upgrade IBM Software Hub
```
./cpd-cli manage case-download --components=${COMPONENTS} --release=${VERSION} --operator_ns=${PROJECT_CPD_INST_OPERATORS} --cluster_resources=true
```

## 2.5 Upgrade IBM Software Hub
```
./cpd-cli manage install-components --license_acceptance=true --components=cpd_platform --release=${VERSION} --operator_ns=${PROJECT_CPD_INST_OPERATORS} --instance_ns=${PROJECT_CPD_INST_OPERANDS} --upgrade=true
```

## 2.6 Upgrade WKC
```
./cpd-cli manage install-components --license_acceptance=true --components=ikc_premium --release=${VERSION} --upgrade=true
```

## 2.7 Upgrade DataLineage
```
./cpd-cli manage install-components --components=datalineage --upgrade=true
```

## 2.8 Upgrade DataStage
```
./cpd-cli manage install-components --components=datastage_ent --upgrade=true
```

# 3. Post-upgrade tasks
RSI patches, hotfix links, and DataStage patches.

