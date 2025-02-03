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
- [Mirror IBM Storage Fusion images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-storage-fusion-images)
------------------
- [Mirror Backup & Restore images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-backup-restore-images)
- [Mirror Backup & Restore images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=images-mirroring-backup-restore)
------------------
- [Mirror IBM Storage Scale images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-storage-scale-images)
- [Mirror IBM Storage Scale images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=images-mirroring-storage-scale)
------------------
- [Mirror Data Foundation images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=myier-mirroring-data-foundation-images-deployed-openshift-container-platform-414-higher-using-imagedigestmirrorset)
- [Mirror Data Foundation images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=mii-mirroring-data-foundation-images-deployed-openshift-container-platform-414-higher-using-imagedigestmirrorset)
------------------
- [Mirror Data Cataloging images - 2.8](https://www.ibm.com/docs/en/fusion-software/2.8.x?topic=registry-mirroring-data-cataloging-images)
- [Mirror Data Cataloging images - 2.9](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=images-mirroring-data-cataloging)
  

