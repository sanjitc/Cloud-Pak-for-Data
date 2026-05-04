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
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v${OCP_VERSION}
      full: true
      packages:
        - name: amq-streams
        - name: redhat-oadp-operator
    - catalog: icr.io/cpopen/isf-data-foundation-catalog:v${OCP_VERSION}
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
#### 1.2.  [Mirror the 2.9.1 images to enterprise registry: end-to-end mirroring](https://www.ibm.com/docs/en/fusion-software/2.10.x?topic=installation-end-end-mirroring-fusion-its-services)


##### 1.2.1. Set common environment variables

Update these values for your registry.

```bash
#!/usr/bin/env bash
set -euo pipefail

export LOCAL_ISF_REGISTRY="registry.example.com:443"
export LOCAL_ISF_REPOSITORY="mirror-fusion-services-images"
export TARGET_PATH="${LOCAL_ISF_REGISTRY}/${LOCAL_ISF_REPOSITORY}"

# Optional auth file location
export REGISTRY_AUTH_FILE="${HOME}/.docker/config.json"

# Working directory
export WORKDIR="${HOME}/fusion-2.10-mirror"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"
```

Example values in the IBM doc follow this same pattern:

```bash
export LOCAL_ISF_REGISTRY="registryhost.com:443"
export LOCAL_ISF_REPOSITORY="mirror-fusion-services-images"
export TARGET_PATH="${LOCAL_ISF_REGISTRY}/${LOCAL_ISF_REPOSITORY}"
```

Log in to the private registry:

```bash
podman login "${LOCAL_ISF_REGISTRY}"
```

---

##### 1.2.2. Set Fusion case variables

The 2.10 doc shows these case values:

```bash
export CASE_NAME="ibm-spectrum-fusion-sds"
export CASE_VERSION="2.10.1"
```

If your organization pins a later 2.10.z level, replace only the version after validating supportability.

---

#####  1.2.3. Install or verify prerequisites

Verify the required tools are installed:

- [`oc`](https://docs.openshift.com/)
- [`oc mirror`](https://docs.openshift.com/container-platform/latest/disconnected_install/about-installing-oc-mirror-v2.html)
- [`oc ibm-pak`](https://github.com/IBM/cloud-pak-cli)

Example:

```bash
oc version
oc ibm-pak version
oc mirror --help >/dev/null
```

If needed, log in to the cluster:

```bash
oc login --token='<token>' --server='https://api.cluster.example.com:6443'
```

---

#####  1.2.4. Verify Red Hat operators if needed

The 2.10 doc says [`redhat-oadp-operator`](#4-verify-red-hat-operators-if-needed) and [`amq-streams`](#4-verify-red-hat-operators-if-needed) are required only for:

- Backup & Restore
- IBM Data Cataloging

Check whether they are already available:

```bash
oc get packagemanifests | grep -iE 'oadp|amq|streams'
```

If they are not mirrored yet, mirror them first using your normal Red Hat operator mirroring process.

If you already mirrored them earlier for 2.9.x and they remain available in-cluster, you do not need to mirror them separately again.

---

##### 1.2.5. Configure [`ibm-pak`](oc%20ibm-pak%20config%20mirror-tools():1) to use [`oc mirror`](oc%20mirror:1)

The 2.10 doc explicitly configures the plugin like this:

```bash
oc ibm-pak config mirror-tools -e oc-mirror
```

---

##### 1.2.6. Download Fusion 2.10 mirroring metadata

Use [`oc ibm-pak get`](oc%20ibm-pak%20get:1) to pull metadata from IBM’s public repository:

```bash
oc ibm-pak get --version "${CASE_VERSION}" "${CASE_NAME}"
```

---

##### 1.2.7. Generate mirror manifests

Generate the [`oc mirror`](oc%20mirror:1) configuration files for your target registry:

```bash
oc ibm-pak generate mirror-manifests \
  --version "${CASE_VERSION}" \
  "${CASE_NAME}" \
  "${TARGET_PATH}"
```

This generates the files needed for mirroring and cluster configuration, typically under a path like:

[`/root/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}`](/root/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION})

---

##### 1.2.8. Run [`oc mirror`](oc%20mirror:1)

The IBM doc says to run [`oc mirror`](oc%20mirror:1) with the non-curated catalog config generated in the previous step.

Example pattern:

```bash
oc mirror --config /root/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}/image-set-config.yaml docker://${TARGET_PATH}
```

If your environment requires skipping TLS verification for a Quay registry, use:

```bash
oc mirror --config /root/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}/image-set-config.yaml docker://${TARGET_PATH} --dest-tls-verify=false
```

Wait for successful completion. The IBM doc indicates successful output includes messages like:

- writing image mappings
- writing CatalogSource manifests
- writing ICSP/IDMS manifests

---

##### 1.2.9. Apply the generated cluster manifests

Change into the generated directory:

```bash
cd /root/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}
```

Apply the generated mirror objects to the cluster.

For [`amd64`](amd64:1), the doc shows:

```bash
oc apply -f image-digest-mirror-set.yaml
oc apply -f catalog-sources-linux-amd64.yaml
```

If your platform differs, use the matching generated catalog-source file.

---

##### 1.2.10. Delete extra catalog sources you do not use

The 2.10 doc states the generate step can add additional catalog sources to the generated [`catalog-sources.yaml`](catalog-sources.yaml) file that are not used.

Delete the additional unused catalog sources to reduce confusion.

Example from the doc:

```bash
oc delete catalogsource -n openshift-marketplace ibm-db2uoperator-catalog
```

If you get `NotFound`, that can be ignored.

##### Important

The doc explicitly warns that a **CAS catalog source is also created and must not be deleted**.

Do not remove the CAS catalog source.

---

##### 1.2.11. Validate the disconnected configuration

Run these checks before starting the Fusion upgrade.

##### Verify generated catalog sources

```bash
oc get catalogsource -n openshift-marketplace
```

##### Verify image mirror set

```bash
oc get imagedigestmirrorsets
```

##### Verify cluster can resolve required packages

```bash
oc get packagemanifests | grep -iE 'fusion|oadp|amq|catalog|cas'
```

##### Verify no public pull dependency remains for Fusion components

```bash
oc get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{range .spec.containers[*]}{.image}{" "}{end}{"\n"}{end}' \
| grep -E 'cp.icr.io|icr.io|quay.io|registry.redhat.io' || true
```
---
#### 1.3.  [Mirror the 2.11.1 images to enterprise registry: end-to-end mirroring](https://www.ibm.com/docs/en/fusion-software/2.11.0?topic=erfi-end-end-mirroring-fusion-its-services-images-enterprise-registry)


##### 1.3.1. Verify Current Environment
```bash
# Check current IBM Fusion version
oc get fusion -A

# Verify cluster connectivity
oc whoami
oc cluster-info

# Check available storage
df -h
```
---
##### 1.3.2. Backup Current Environment
```bash
# Backup current configurations
oc get fusion -A -o yaml > fusion-backup-$(date +%Y%m%d).yaml
oc get pods -A > pods-backup-$(date +%Y%m%d).txt
```

---

##### 1.3.3. Define Environment Variables

Set the following environment variables for your target container registry:

```bash
# Target registry configuration
export LOCAL_ISF_REGISTRY="<Your container registry host name>"
export LOCAL_ISF_REPOSITORY="<Your image path>"
export TARGET_PATH="$LOCAL_ISF_REGISTRY/$LOCAL_ISF_REPOSITORY"

# Example:
# export LOCAL_ISF_REGISTRY="registryhost.com:443"
# export LOCAL_ISF_REPOSITORY="mirror/fusion-services-images"
# export TARGET_PATH="$LOCAL_ISF_REGISTRY/$LOCAL_ISF_REPOSITORY"
```

##### 1.3.4. Define IBM Fusion Version Variables

```bash
# IBM Fusion version configuration
export CASE_NAME=ibm-spectrum-fusion-sds
export CASE_VERSION=2.11.0
```
---

##### 1.3.5. Verify Operator Packages

Ensure that `redhat-oadp-operator` and `amq-streams` operator packages are present in your cluster:

```bash
# Check for required operators
oc get packagemanifests | grep -E "redhat-oadp-operator|amq-streams"
```

**Important Notes:**
- The `redhat-oadp-operator` and `amq-streams` operator packages are required only for Backup & Restore and IBM Data Cataloging services
- If you have not mirrored these operators from Red Hat packages previously, follow the steps in the Mirroring Red Hat operator images documentation
- Ensure you also add existing packages along with the `ImageSetConfiguration` file to avoid losing old packages from the Red Hat operator index image

---

## Mirroring Procedure

### Step 1: Configure ibm-pak Plugin

Configure the `ibm-pak` plugin to use the `oc mirror` command:

```bash
oc ibm-pak config mirror-tools -e oc-mirror
```

### Step 2: Download Mirroring Metadata

Download the mirroring metadata from IBM's public CloudPak repository:

```bash
oc ibm-pak get --version "$CASE_VERSION" "$CASE_NAME"
```

**Expected Output:**
```
Downloading and extracting the CASE ...
- Success
Retrieving CASE version ...
- Success
Validating the CASE ...
- Success
Creating inventory ...
- Success
```

### Step 3: Generate Mirror Manifests

Run the `ibm-pak generate` command to generate the `oc mirror` configuration files specific to your environment:

```bash
oc ibm-pak generate mirror-manifests \
  --version "$CASE_VERSION" \
  "$CASE_NAME" \
  $LOCAL_ISF_REGISTRY
```

**Expected Output:**
```
Generating mirror manifests...
- Success
Generated files:
  - image-digest-mirror-set.yaml
  - catalog-sources-linux-amd64.yaml
```

### Step 4: Review Generated Configuration

Navigate to the directory containing the generated `image-set-config.yaml` file:

```bash
cd /root/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION
ls -la
```

**Important:** Review the `image-set-config.yaml` file to understand what will be mirrored.

### Step 5: Execute Mirroring - Curated Catalog

Run the `oc mirror` command for the curated catalog:

```bash
oc mirror --config /root/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/image-set-config.yaml \
  docker://$LOCAL_ISF_REGISTRY
```

**Expected Output:**
```
Writing image mapping to oc-mirror-workspace/results-*/mapping.txt
Writing CatalogSource manifests to oc-mirror-workspace/results-*/
Writing ICSP manifests to oc-mirror-workspace/results-*/
```

### Step 6: Execute Mirroring - Non-Curated Catalog (Optional)

If you need to mirror the non-curated catalog:

```bash
oc mirror --config /root/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/image-set-config-non-curated.yaml \
  docker://$LOCAL_ISF_REGISTRY
```

**Note:** Use the `--dest-tls-verify=false` parameter when mirroring images to a quay repository.

### Step 7: Apply Generated Files to Cluster

Navigate to the directory containing the generated files:

```bash
cd /root/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION
```

Apply the `image-digest-mirror-set.yaml` and `catalog-sources-linux-amd64.yaml` files:

```bash
oc apply -f image-digest-mirror-set.yaml
oc apply -f catalog-sources-linux-amd64.yaml
```

### Step 8: Clean Up Unused Catalog Sources (Important)

The `generate` command adds additional catalog sources to the generated `catalog-sources.yaml` file that are not used. To avoid confusion, delete these additional catalog sources:

```bash
oc delete catalogsource -n openshift-marketplace ibm-db2uoperator-catalog
```

**Important:** The process also creates a CAS catalogsource, and you must not delete it. The delete command also does not clean the CAS catalogsource.

**Error Handling:**
If you see "Error from server (NotFound)" messages, this indicates that the catalogs do not exist and the message can be ignored.

---

## Post-Mirroring Validation

### Step 1: Verify Image Mirroring

Check that images have been successfully mirrored:

```bash
# Verify ImageDigestMirrorSet
oc get imagedigestmirrorset

# Check catalog sources
oc get catalogsource -n openshift-marketplace

# Verify specific catalog sources
oc get catalogsource -n openshift-marketplace | grep -E "ibm-spectrum-fusion|openshift-marketplace"
```

### Step 2: Verify Operator Availability

```bash
# Check available operators
oc get packagemanifests -n openshift-marketplace | grep fusion

# Verify operator catalog
oc get pods -n openshift-marketplace
```

### Step 3: Test Image Pull

Verify that images can be pulled from the mirrored registry:

```bash
# Test image pull (replace with actual image name)
oc run test-pull --image=$LOCAL_ISF_REGISTRY/$LOCAL_ISF_REPOSITORY/fusion-test:latest --restart=Never

# Check pod status
oc get pod test-pull

# Clean up test pod
oc delete pod test-pull
```

### Step 4: Verify Mirrored Content

```bash
# Check the oc-mirror workspace for results
ls -la oc-mirror-workspace/results-*/

# Review mapping file
cat oc-mirror-workspace/results-*/mapping.txt

# Verify catalog source manifests
cat oc-mirror-workspace/results-*/catalogSource-*.yaml
```

### Step 5: Document Mirrored Images

```bash
# Save list of mirrored images
cat oc-mirror-workspace/results-*/mapping.txt > mirrored-images-$(date +%Y%m%d).txt

# Count mirrored images
wc -l mirrored-images-$(date +%Y%m%d).txt
```

---

## Troubleshooting

### Common Issues and Resolutions

#### Issue 1: Mirror Command Fails with Authentication Error

**Symptoms:**
```
Error: authentication required
```

**Resolution:**
```bash
# Re-authenticate to the registry
oc registry login --registry $LOCAL_ISF_REGISTRY

# Or use docker login
docker login $LOCAL_ISF_REGISTRY
```

#### Issue 2: Insufficient Storage Space

**Symptoms:**
```
Error: no space left on device
```

**Resolution:**
```bash
# Check available space
df -h

# Clean up old images
docker system prune -a

# Or increase storage allocation
```

#### Issue 3: Network Timeout During Mirroring

**Symptoms:**
```
Error: context deadline exceeded
```

**Resolution:**
```bash
# Increase timeout values
export OC_MIRROR_TIMEOUT=3600

# Retry the mirror command
oc mirror --config /root/.ibm-pak/data/mirror/$CASE_NAME/$CASE_VERSION/image-set-config.yaml \
  docker://$LOCAL_ISF_REGISTRY
```

#### Issue 4: Catalog Source Not Available

**Symptoms:**
```
CatalogSource not found or not ready
```

**Resolution:**
```bash
# Check catalog source status
oc get catalogsource -n openshift-marketplace

# Check catalog source pods
oc get pods -n openshift-marketplace

# Review catalog source logs
oc logs -n openshift-marketplace <catalog-pod-name>

# Reapply catalog sources if needed
oc apply -f catalog-sources-linux-amd64.yaml
```

#### Issue 5: Image Pull Errors After Mirroring

**Symptoms:**
```
ImagePullBackOff or ErrImagePull
```

**Resolution:**
```bash
# Verify ImageDigestMirrorSet is applied
oc get imagedigestmirrorset

# Check image reference in the mirror mapping
cat oc-mirror-workspace/results-*/mapping.txt | grep <image-name>

# Verify registry credentials
oc get secret -n openshift-config pull-secret -o yaml
```

### Getting Additional Help

For additional troubleshooting steps, refer to:
- Troubleshooting and known issues in offline mirroring documentation
- IBM Support Portal
- Red Hat Customer Portal

---

## Rollback Plan

### Pre-Rollback Checklist
- [ ] Verify backup files are available
- [ ] Document current state before rollback
- [ ] Notify stakeholders of rollback procedure

### Rollback Steps

#### Step 1: Remove New Catalog Sources
```bash
# Remove newly applied catalog sources
oc delete -f catalog-sources-linux-amd64.yaml

# Remove image digest mirror set
oc delete -f image-digest-mirror-set.yaml
```

#### Step 2: Restore Previous Configuration
```bash
# Restore previous catalog sources (if backed up)
oc apply -f catalog-sources-backup.yaml

# Restore previous image digest mirror set (if backed up)
oc apply -f image-digest-mirror-set-backup.yaml
```

#### Step 3: Verify Rollback
```bash
# Verify catalog sources
oc get catalogsource -n openshift-marketplace

# Verify image digest mirror sets
oc get imagedigestmirrorset

# Check operator availability
oc get packagemanifests -n openshift-marketplace | grep fusion
```

------------

### 2. Before you begin
#### 2.1. Ensure all compute nodes are in a ready state on OpenShift user interface.
#### 2.2. Download the logs that you collected by using IBM Fusion. The Collect logs user interface page gets deleted after the upgrade process completes.

Updating the cpdbr service
If you use IBM Fusion to back up and restore your IBM® Software Hub deployment, you must upgrade the cpdbr service after you upgrade IBM Cloud Pak® for Data Version 4.8 to IBM Software Hub Version 5.1.
