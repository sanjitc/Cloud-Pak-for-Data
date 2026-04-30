## Fusion upgrade from 2.9.0 to 2.12.1

### Upgrade Path
Current version(2.9.0) > 2.9.1 > 2.10.0 > 2.11.0 > 2.12.0 > 2.12.1
### Component to upgrade
- Fusion services,
- IBM Storage Fusion management software,
- Red Hat OpenShift Container Platform

### Documentation
- [Upgrading IBM Storage Fusion to 2.9.0](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=components-upgrading-fusion)
- [Upgrading IBM Storage Fusion to 2.10.0](https://www.ibm.com/docs/en/fusion-software/2.10.x?topic=fusion-upgrading)
- [Upgrading IBM Storage Fusion to 2.11.0](https://www.ibm.com/docs/en/fusion-software/2.11.0?topic=fusion-upgrading)
- [Upgrading IBM Storage Fusion to 2.12.1](https://www.ibm.com/docs/en/fusion-software/2.12.x?topic=fusion-upgrading)

### 1. Prerequisites for enterprise registry upgrade
Configure common environment variables
```
export LOCAL_ISF_REGISTRY="<Your container registry host>:<port>"
export LOCAL_ISF_REPOSITORY="<Your image path>"
export TARGET_PATH="$LOCAL_ISF_REGISTRY/$LOCAL_ISF_REPOSITORY"

export OCP_VERSION=<your OCP version in X.Y format>
export OCP_FULL_VERSION=<your OCP version in X.Y.Z format>
export OCP_PLATFORM=<your OCP platform, i.e., x86_64>
export PRODUCT_REPO="openshift-release-dev"
export RELEASE_NAME="ocp-release"
export OCP_RELEASE_IMAGE="quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_FULL_VERSION}-${OCP_PLATFORM}"
```
#### 1.1.  [Mirror the 2.9.1 images to enterprise registry](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=components-prerequisites-enterprise-registry-upgrade)
##### 1.1.1. [Mirror IBM Fusion images](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=installation-end-end-mirroring-fusion-its-services).

**a) Mirror Fusion Data Foundation and related OpenShift dependencies.**
Create the following ImageSetConfiguration file to mirror OpenShift and Fusion Data Foundation. 
For 4.16:
```

cat << EOF > imageset-config-ocp-rh.yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
storageConfig:
  registry:
    imageURL: "${TARGET_PATH}/isf-df-metadata:latest"
    skipTLS: true
mirror:
  additionalImages:
    - name: ${OCP_RELEASE_IMAGE}
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v${OCP_VERSION}
      packages:
        - name: "redhat-oadp-operator"
        - name: "amq-streams"
    - catalog: icr.io/cpopen/isf-data-foundation-catalog:v${OCP_VERSION}
    packages:
      - name: "mcg-operator"
      - name: "ocs-operator"
      - name: "odf-csi-addons-operator"
      - name: "odf-multicluster-orchestrator"
      - name: "odf-operator" 
      - name: "odr-cluster-operator"    
      - name: "odr-hub-operator"
      - name: "ocs-client-operator"
      - name: "odf-prometheus-operator"
      - name: "recipe"
      - name: "rook-ceph-operator"
EOF
```
Run the following OC command to mirror OpenShift and Fusion Data Foundation images:
```
oc mirror --config imageset-config-ocp-rh.yaml docker://${TARGET_PATH} --dest-skip-tls --ignore-history
```
Apply the created files.

**b) Mirror IBM Fusion and related services.**
Define the following environment variables for 2.9.1
```
export CASE_NAME=ibm-spectrum-fusion-sds
export CASE_VERSION=2.9.1
```
Configure the ibm-pak plugin to use the oc mirror command:
```
oc ibm-pak config mirror-tools -e oc-mirror
```

Use the ibm-pak get command to download the mirroring metadata from the public CloudPak repo of IBM:
```
oc ibm-pak get --version "${CASE_VERSION}" "${CASE_NAME}"
```

Run the ibm-pak generate command to generate the oc mirror configuration files specific to your environment:
```
oc ibm-pak generate mirror-manifests --version "${CASE_VERSION}" "${CASE_NAME}" "${TARGET_PATH}"
```

The generate command adds additional catalog sources to the generated catalog-sources.yaml file that is not used. To avoid confusion, it is best to delete these additional catalog sources:
```
cd /root/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}/
oc apply -f image-digest-mirror-set.yaml
oc apply -f catalog-sources.yaml

oc delete catalogsource -n openshift-marketplace ibm-db2uoperator-catalog ibm-fusion-bnr-catalog ibm-spectrum-discover-catalog
```

##### 1.1.2. Mirror Backup & Restore images. 
##### 1.1.3. Mirror IBM Storage Scale images.
##### 1.1.4. Data Cataloging offline upgrade.

### 2. Before you begin
#### 2.1. Ensure all compute nodes are in a ready state on OpenShift user interface.
#### 2.2. Download the logs that you collected by using IBM Fusion. The Collect logs user interface page gets deleted after the upgrade process completes.

Updating the cpdbr service
If you use IBM Fusion to back up and restore your IBM® Software Hub deployment, you must upgrade the cpdbr service after you upgrade IBM Cloud Pak® for Data Version 4.8 to IBM Software Hub Version 5.1.
