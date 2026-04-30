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
```
#### 1.1.  [Mirror the 2.9.1 images to enterprise registry](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=components-prerequisites-enterprise-registry-upgrade)
##### 1.1.1. [Mirror IBM Fusion images](https://www.ibm.com/docs/en/fusion-software/2.9.x?topic=installation-end-end-mirroring-fusion-its-services).
##### 1.1.2. Mirror Backup & Restore images. 
##### 1.1.3. Mirror IBM Storage Scale images.
##### 1.1.4. Data Cataloging offline upgrade.

### 2. Before you begin
#### 2.1. Ensure all compute nodes are in a ready state on OpenShift user interface.
#### 2.2. Download the logs that you collected by using IBM Fusion. The Collect logs user interface page gets deleted after the upgrade process completes.

Updating the cpdbr service
If you use IBM Fusion to back up and restore your IBM® Software Hub deployment, you must upgrade the cpdbr service after you upgrade IBM Cloud Pak® for Data Version 4.8 to IBM Software Hub Version 5.1.
