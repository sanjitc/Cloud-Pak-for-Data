
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
oc get nodes,co,mcp
${CPDM_OC_LOGIN}
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[digit:]])/\1.*R' | grep -v 'Completed'
```

## 1.3 Backup before upgrade
Backing up custom resources, routes, and RSI patches.

## 1.6 Update the cpd-cli utility
```
wget https://github.com/IBM/cpd-cli/releases/download/v14.3.1/cpd-cli-linux-EE-14.3.1.tgz
tar -xvf cpd-cli-linux-EE-14.3.1.tgz
./cpd-cli manage restart-container
podman ps | grep olm-utils-v4
```

## 1.7 Install Helm CLI
```
sudo dnf install helm
```

## 1.8 Update environment variables
```
export VERSION=5.3.1
export COMPONENTS=ibm-licensing,cpfs,cpd_platform,wkc,datastage_ent,analyticsengine,datalineage,ikc_standard,ikc_premium,semantic_automation
export IMAGE_PULL_SECRET=${IBM_ENTITLEMENT_KEY}
export IMAGE_PULL_PREFIX=${PRIVATE_REGISTRY_LOCATION}
```

## 1.9 Mirror CPD 5.3.1 images
```
podman pull cp.icr.io/cp/cpd/olm-utils-premium-v4:${VERSION}.amd64 --tls-verify=false
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

