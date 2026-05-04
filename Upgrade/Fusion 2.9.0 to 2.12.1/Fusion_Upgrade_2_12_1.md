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
#### 1.1.  [Mirror the 2.9.1 images to enterprise registry: end-to-end mirroring](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=installation-end-end-mirroring-fusion-its-services)

##### Purpose

- OpenShift release content
- Fusion Data Foundation dependencies
- IBM Fusion images and services
- Optional IBM Storage Scale images, if used

##### Assumptions

- You already have a working private image registry.
- You have cluster-admin access.
- You have internet access from the mirror host.
- Your OpenShift cluster can reach the private registry.
- You will update mirror objects on the cluster before the upgrade.

---
##### 1.1.1. Install prerequisites
- [`oc`](https://docs.openshift.com/)
- [`oc-mirror`](https://docs.openshift.com/container-platform/latest/disconnected_install/about-installing-oc-mirror-v2.html)
- [`ibm-pak`](https://github.com/IBM/cloud-pak-cli)

Example verification:

```bash
oc version
oc-mirror version
ibm-pak version
```
---
##### 1.1.2. Set environment variables

Update these placeholders for your environment.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ===== Registry =====
export TARGET_REGISTRY="registry.example.com"
export TARGET_REGISTRY_PATH="ibm-fusion"
export REGISTRY_AUTH_FILE="$HOME/.docker/config.json"

# ===== OpenShift =====
export OCP_VERSION=""
export OCP_FULL_VERSION=""
export OCP_PLATFORM="x86_64"     # x86_64 | ppc64le | s390x

# ===== OpenShift release metadata =====
export PRODUCT_REPO="openshift-release-dev"
export RELEASE_NAME="ocp-release"
export OCP_RELEASE_IMAGE="quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_FULL_VERSION}-${OCP_PLATFORM}"

# ===== IBM Fusion =====
export FUSION_VERSION="2.9.1"

# ===== Local work area =====
export WORKDIR="$HOME/ibm-fusion-mirror-${FUSION_VERSION}"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

echo "Working in ${WORKDIR}"
```

Login to your private registry if needed:

```bash
podman login "${TARGET_REGISTRY}"
```

Optional OpenShift login:

```bash
oc login --token='<token>' --server='https://api.cluster.example.com:6443'
```

---

##### 1.1.3. Configure IBM catalog access

If required in your environment, authenticate IBM entitlement access:

```bash
export ENTITLED_REGISTRY="cp.icr.io"
export IBM_ENTITLEMENT_KEY="<your-entitlement-key>"

podman login "${ENTITLED_REGISTRY}" -u cp -p "${IBM_ENTITLEMENT_KEY}"
```

---

##### 1.1.4. Mirror OpenShift + Fusion Data Foundation dependencies

Create the ImageSetConfiguration for OpenShift release content and required operators.

Create [`imageset-config-ocp-rh.yaml`](imageset-config-ocp-rh.yaml):

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
storageConfig:
  registry:
    imageURL: "${TARGET_REGISTRY}/${TARGET_REGISTRY_PATH}/isf-df-metadata:latest"
    skipTLS: true
mirror:
  additionalImages:
    - name: ${OCP_RELEASE_IMAGE}
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.15
      full: true
      packages:
        - name: amq-streams
        - name: redhat-oadp-operator
    - catalog: icr.io/cpopen/isf-data-foundation-catalog:latest
      full: true
```

Run the mirror:

```bash
oc-mirror --config=./imageset-config-ocp-rh.yaml docker://"${TARGET_REGISTRY}/${TARGET_REGISTRY_PATH}"
```

> If your registry uses a trusted certificate, remove [`skipTLS: true`](imageset-config-ocp-rh.yaml:5).

---

##### 1.1.5. Generate IBM Fusion mirroring metadata

Use [`ibm-pak`](https://github.com/IBM/cloud-pak-cli) to prepare case metadata for IBM Fusion 2.9.1.

```bash
export CASE_NAME="ibm-scality-fusion"
export CASE_INVENTORY_SETUP="ibmFusionSetup"

oc ibm-pak get "${CASE_NAME}" --version "${FUSION_VERSION}"
oc ibm-pak generate mirror-manifests "${CASE_NAME}" \
  docker://${TARGET_REGISTRY}/${TARGET_REGISTRY_PATH} \
  --version "${FUSION_VERSION}"
```

> If IBM uses a different case name for your entitlement/content set, substitute the correct one from your environment.

This typically creates manifest content under a generated directory. Review the output location before proceeding.

---

##### 1.1.6. Mirror IBM Fusion 2.9.1 images

Run the generated mirror process.

Typical pattern:

```bash
oc image mirror \
  -f ./mirror-manifests/mapping.txt \
  --registry-config="${REGISTRY_AUTH_FILE}"
```

If the generated content includes its own helper script, use that instead:

```bash
chmod +x ./mirror-manifests/mirror-images.sh
./mirror-manifests/mirror-images.sh
```

---

##### 1.1.7. Mirror IBM Fusion services

If you use Fusion services such as:

- Backup & Restore
- Data Cataloging

include them in the generated manifests or case mirror content for the same Fusion 2.9.1 release.

Typical regeneration flow:

```bash
oc ibm-pak generate mirror-manifests "${CASE_NAME}" \
  docker://${TARGET_REGISTRY}/${TARGET_REGISTRY_PATH} \
  --version "${FUSION_VERSION}"
```

Then mirror the resulting mappings again:

```bash
oc image mirror \
  -f ./mirror-manifests/mapping.txt \
  --registry-config="${REGISTRY_AUTH_FILE}"
```

> Ensure the mappings include the services actually installed in your Fusion environment.

---

##### 1.1.8. Optional: mirror IBM Storage Scale images

If your deployment uses Global Data Platform / Storage Scale, mirror its required images too.

Create a separate image set or use the IBM-provided mirror manifests for Storage Scale in the same target registry namespace.

Example placeholder:

```bash
echo "Mirror IBM Storage Scale images here if your Fusion deployment requires them."
```

---

##### 1.1.9. Validate the mirrored content

Check that the mirrored content exists:

```bash
oc adm release info "${TARGET_REGISTRY}/${TARGET_REGISTRY_PATH}/${RELEASE_NAME}:${OCP_FULL_VERSION}-${OCP_PLATFORM}" --registry-config="${REGISTRY_AUTH_FILE}"
```

Check operator catalog pods:

```bash
oc get pods -A | grep -Ei 'catalog|operator'
```

Check image mirror objects:

```bash
oc get imagedigestmirrorsets
oc get imagetagmirrorsets
oc get catalogsource -A
```

Check whether any workload still references public registries:

```bash
oc get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{range .spec.containers[*]}{.image}{" "}{end}{"\n"}{end}' \
| grep -E 'quay.io|registry.redhat.io|cp.icr.io|icr.io' || true
```

---

##### 1.1.10. Upgrade preparation checklist

Run these checks before the upgrade:

```bash
echo "Checklist:"
echo "1. Private registry reachable from all cluster nodes"
echo "2. Cluster pull secret contains private registry auth"
echo "3. OpenShift release image mirrored"
echo "4. Fusion Data Foundation dependencies mirrored"
echo "5. IBM Fusion 2.9.1 images mirrored"
echo "6. Backup & Restore / Data Cataloging images mirrored if installed"
echo "7. Storage Scale images mirrored if required"
echo "8. Catalog sources updated to disconnected registry"
echo "9. No remaining public registry dependencies"
```

---


##### Notes

- Replace placeholder values before use.
- Verify the exact IBM case name and generated manifest paths in your environment.
- If your existing 2.9 environment already mirrors some dependencies, still validate that the **2.9.1** catalogs and images are present before upgrading.
- If you want stricter compatibility, pin operator catalog tags exactly as documented for your OpenShift/Fusion combination.

-------



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
