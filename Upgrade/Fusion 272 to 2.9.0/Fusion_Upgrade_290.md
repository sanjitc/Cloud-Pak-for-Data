## Fusion upgrade from to 2.7.2 to 2.9.0

### Upgrade Path
Current version(2.7.2) > 2.8.0 > 2.8.2 > 2.9.0

### Component to upgrade
- IBM Storage Fusion management software,
- Fusion services,
- Red Hat OpenShift Container Platform

### Documentation
- [Upgrading IBM Storage Fusion to 2.8.2](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=upgrading-storage-fusion)
- [Upgrading IBM Storage Fusion to 2.9.0](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=upgrading-fusion-its-components)

### 1. Before you begin
Because of a known Red Hat issue, the Fusion operator upgrade can get stuck during upgrade. Run the following commands before you begin the IBM Storage Fusion operator upgrade to prevent this scenario.
```
oc project $(oc get spectrumfusion -A -o custom-columns=NS:metadata.namespace --no-headers)
oc get fusionserviceinstance -o jsonpath='{.items[*].metadata.name}' |tr ' ' '\n' | xargs -I {} oc patch fusionserviceinstance {} --type=merge --subresource=status -p '{"status": {"triggerCatSrcCreateStartTime": 0}}'
oc get fusionserviceinstance -o jsonpath='{.items[*].metadata.name}' |tr ' ' '\n' | xargs -I {} oc patch fusionserviceinstance {} --type=merge --subresource=status -p '{"status": {"currentInstallStartTime": 0}}'
oc get fusionserviceinstance -o jsonpath='{.items[*].metadata.name}' |tr ' ' '\n' | xargs -I {} oc patch fusionserviceinstance {} --type=merge --subresource=status -p '{"status": {"operatorLastUpdateTime": 0}}'
oc get fusionserviceinstance -o jsonpath='{.items[*].metadata.name}' |tr ' ' '\n' | xargs -I {} oc patch fusionserviceinstance {} --type=merge --subresource=status -p '{"status": {"operatorUpgradeStartTime": 0}}'
oc get fusionservicedefinition -o jsonpath='{.items[*].metadata.name}' |tr ' ' '\n' | xargs -I {} oc patch fusionservicedefinition {} --type=merge -p '{"spec": {"serviceInformation": {"lastUpdated": 0}}}'
```

### 2. [Prerequisites for enterprise registry upgrade](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=fusion-prerequisites-enterprise-registry-upgrade)
- [Mirror Data Cataloging images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-data-cataloging-images)
- [Mirror Data Cataloging images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=images-mirroring-data-cataloging)
------------------
- [Mirror Data Foundation images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=myier-mirroring-data-foundation-images-deployed-openshift-container-platform-414-higher-using-imagedigestmirrorset)
- [Mirror Data Foundation images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=mii-mirroring-data-foundation-images-deployed-openshift-container-platform-414-higher-using-imagedigestmirrorset)
------------------
- [Mirror IBM Storage Fusion images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-storage-fusion-images)
- [End-to-end mirroring of IBM Fusion and its services - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=installation-end-end-mirroring-fusion-its-services)
------------------
- [Mirror Backup & Restore images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-backup-restore-images)
- [Mirror Backup & Restore images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=images-mirroring-backup-restore)
------------------
- [Mirror IBM Storage Scale images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-storage-scale-images)
- [Mirror IBM Storage Scale images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=images-mirroring-storage-scale)
------------------
  
### 3. Data Cataloging offline upgrade - 2.8
a. Update the redhat-operators catalog source.
```
for catalog in $(ls oc-mirror-workspace/results-*/catalogSource* | grep -v spectrum-discover); do echo "Creating CatalogSource from file: $catalog"; echo "oc apply -f $catalog"; done
```

b. If a new TARGET_PATH value is used for the upgrade, then update the existing ImageContentSourcePolicy.
```
cat << EOF > imagecontentsourcepolicy_dcs.yaml
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: isf-dcs-icsp
spec:
  repositoryDigestMirrors:
    - mirrors:
        - $LOCAL_ISF_REGISTRY/cpopen
      source: icr.io/cpopen
    - mirrors:
        - $LOCAL_ISF_REGISTRY/redhat
      source: registry.redhat.io/redhat
    - mirrors:
        - $LOCAL_ISF_REGISTRY/ubi8
      source: registry.redhat.io/ubi8
    - mirrors:
        - $LOCAL_ISF_REGISTRY/amq-streams
      source: registry.redhat.io/amq-streams
    - mirrors:
        - $LOCAL_ISF_REGISTRY/openshift4
      source: registry.redhat.io/openshift4
    - mirrors:
        - $LOCAL_ISF_REGISTRY/cp/ibm-spectrum-discover
      source: cp.icr.io/cp/ibm-spectrum-discover
    - mirrors:
        - $LOCAL_ISF_REGISTRY/db2u
      source: icr.io/db2u
EOF
oc apply -f imagecontentsourcepolicy_dcs.yaml
```
------------------
### 4. Fusion Data Foundation offline service upgrade - 2.8
a. Before you upgrade IBM Storage Fusion, from the Services page of the IBM Storage Fusion user interface, disable **Automatic updates** for Data Foundation service.

b. Go to **Operators > Installed Operators > IBM Storage Fusion Data Foundation > Subscription**, and check whether the **Update approval** is changed to **Manually**.

c. Start the IBM Storage Fusion version upgrade.

d. Update the image digest ID after you upgrade the IBM Storage Fusion as follows:

i) Run the following command to get the catalog source image digest ID.
```
skopeo inspect docker://<enterprise registry host:port>/<target-path>/cpopen/isf-data-foundation-catalog:<ocp version> | jq -r ".Digest"
```
You need to record the image digest ID. It is used in deployment phase only.

ii) Check whether the data-foundation-service FusionServiceDefinition CR is created.
```
oc get fusionservicedefinitions.service.isf.ibm.com -n ibm-spectrum-fusion-ns data-foundation-service
```

iii) Update the imageDigest in the FusionServiceDefinition data-foundation-service.
```
skopeo inspect docker://<enterprise registry host:port>/<target-path>/cpopen/isf-data-foundation-catalog:<ocp version> | jq -r ".Digest"
```

iv) Edit the data-foundation-service .spec.onboarding.serviceOperatorSubscription.multiVersionCatSrcDetails.ocp412-t.imageDigest.
```
oc edit fusionservicedefinitions.service.isf.ibm.com -n ibm-spectrum-fusion-ns data-foundation-service
```

Example of OpenShift Container Platform 4.12 output:
```
spec:
  hasRelatedDefinition: false
  onboarding:
...
    serviceOperatorSubscription:
      catalogSourceName: isf-data-foundation-catalog
      createCatalogSource: true
      globalCatalogSource: true
      isClusterWide: false
      multiVersionCatSrcDetails:
        ocp49:
          skipCatSrcCreation: true
        ocp410:
          skipCatSrcCreation: true
        ocp411:
          skipCatSrcCreation: true
        ocp412-t:
          displayName: Data Foundation Catalog
          imageDigest: sha256:ed94a66296d1a4fe047b0a79db0e8653e179a8a2a646b0c05e435762d852de73
          imageName: isf-data-foundation-catalog
          imageTag: v4.12
          publisher: IBM
          registryPath: icr.io/cpopen
          skipCatSrcCreation: false
```

e. Change **Update approval** to the original value in the IBM Storage Fusion user interface.

g. Modify the image content source policy isf-operator-index. For each source defined in the image content source policy, add the new mirror that points to the new registry. If you want to mirror to the same enterprise registry as the previous version, then skip this step.
See the following sample image content source policy:
```
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: isf-catalog-index
spec:
  repositoryDigestMirrors:
  # for scale
  - mirrors:
    - <Old ISF enterprise registry host>/<Old ISF target-path>
    - <Old ISF enterprise registry host:port>/<Old ISF target-path>
    - <New ISF enterprise registry host>/<New ISF target-path>
    - <New ISF enterprise registry host:port>/<New ISF target-path>
    source: cp.icr.io/cp/spectrum/scale
  - mirrors:
    - <Old ISF enterprise registry host>/<Old ISF target-path>
    - <Old ISF enterprise registry host:port>/<Old ISF target-path>
    - <New ISF enterprise registry host>/<New ISF target-path>
    - <New ISF enterprise registry host:port>/<New ISF target-path>
    source: icr.io/cpopen
  #for IBM Spectrum Fusion operator 
  - mirrors:
    - <Old ISF enterprise registry host>/<Old ISF target-path>
    - <Old ISF enterprise registry host:port>/<Old ISF target-path>
    - <New ISF enterprise registry host>/<New ISF target-path>
    - <New ISF enterprise registry host:port>/<New ISF target-path>
    source: cp.icr.io/cp/isf-sds
  # for spp agent
  - mirrors:
    - <Old ISF enterprise registry host>/<Old ISF target-path>/sppc
    - <Old ISF enterprise registry host:port>/<Old ISF target-path>/sppc
    - <New ISF enterprise registry host>/<New ISF target-path>/sppc
    - <New ISF enterprise registry host:port>/<New ISF target-path>/sppc
    source: cp.icr.io/cp/sppc
  - mirrors:
    - <Old ISF enterprise registry host>/<Old ISF target-path>/sppc
    - <Old ISF enterprise registry host:port>/<Old ISF target-path>/sppc
    - <New ISF enterprise registry host>/<New ISF target-path>/sppc
    - <New ISF enterprise registry host:port>/<New ISF target-path>/sppc
    source: registry.redhat.io/amq7
  - mirrors:
    - <Old ISF enterprise registry host>/<Old ISF target-path>/sppc
    - <Old ISF enterprise registry host:port>/<Old ISF target-path>/sppc
    - <New ISF enterprise registry host>/<New ISF target-path>/sppc
    - <New ISF enterprise registry host:port>/<New ISF target-path>/sppc
    source: registry.redhat.io/oadp
  - mirrors: 
    - <New ISF enterprise registry host>/<New ISF target-path>/sppc 
    - <New ISF enterprise registry host:port>/<New ISF target-path>/sppc 
    source: registry.redhat.io/amq-streams
```
------------------
### 5. Upgrading IBM Storage Fusion - 2.8
1. Log in to the OpenShift Container Platform management console as the cluster administrator.
2. Upgrade IBM Storage Fusion:

a) From the navigation menu, click **Operators > Installed Operators**.

b) From the **Installed Operators** list, click **IBM Storage Fusion** operator.
The **Details** tab opens by default.

c) Go to **Subscription** tab.

d) View the **Subscription details** section for the upgrade status.

**Note:** If this is an offline setup, then update the image path in IBM Storage Fusion catalog source with new catalog source image.

e) If an upgrade is available for the operator, then click Approve to manually initiate the upgrade. If you do not agree to the upgrade, click Deny.

**Note:** You can ignore this step if you have set auto-approval to true. By default, the upgrade of the IBM Storage Fusion is Automatic. However, you can change it to Manual.

If no new upgrade is available, then **Upgrade status** displays **Up to date**.

f) After the upgrade is successful, refresh your browser and clear your cache.

g) Verify whether the IBM Storage Fusion is in succeeded state and the version is 2.8.0 or 2.8.2. Also, in the **Subscription** tab, ensure that the upgrade status displays **Up to date**.

------------------

### 6. [Upgrade IBM Storage Fusion services - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=fusion-upgrading-storage-services)
From the IBM Storage Fusion user interface, upgrade the IBM Storage Fusion services, namely Data Foundation, Global Data Platform, Backup & Restore, and Data Cataloging.

**Important:** It is recommended to upgrade the services to the latest version after a IBM Storage Fusion upgrade to avoid compatibility issues between IBM Storage Fusion and its installed services.

[[follow from the documentation link]]



