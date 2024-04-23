## Fusion upgrade from 2.5.2 to 2.7.2

### Upgrade Path
Current version(2.5.2) > 2.6.0 > 2.6.1 > 2.7.0 > 2.7.2

### Documentation
- [Upgrade to 2.6 or 2.6.1](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=upgrading-storage-fusion)
- [Upgrade to 2.7.0.x](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=upgrading-storage-fusion)

### Post upgrade checklist
1. IBM Storage Fusion version 2.5.x installation method ["Online" or "Enterprise registry installation"]
2. OpenShift version 4.12
3. All OpenShift compute nodes are in ready state.
4. Ensure node upsize and disk scale out are not initiated.
5. Download the needed logs that you collected by using the IBM Storage Fusion Collect logs user interface page.
6. Mirror images in your enterprise registry / Artifactory [2.6.0 and 2.6.1 Images](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=registry-mirroring-storage-fusion-images)
   - [ ] [Mirroring Data Foundation images](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=myier-mirroring-data-foundation-images-deployed-openshift-container-platform-version-412#sds_odf_mirror_images__step_hdp_5j5_fyb)
   - [ ] ~~Mirror Red Hat OpenShift Container Platform release images.~~
   - [ ] ~~Mirror images for Red Hat operator~~
   - [ ] Mirror IBM Storage Fusion
   - [ ] ~~Mirror IBM Spectrum Scale~~
   - [ ] Mirror IBM Spectrum Protect Plus
   - [ ] Mirror Backup & Restore images
   - [ ] Mirror Data Cataloging images ??
7. Mirror images in your enterprise registry / Artifactory [2.7.0, 2.7.2 and hot fix Images](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=installation-mirroring-your-images-enterprise-registry)
   - [ ] Mirror IBM Storage Fusion
   - [ ] ~~Mirror IBM Spectrum Scale~~
   - [ ] Mirror Data Foundation images
   - [ ] Mirror Backup & Restore images
   - [ ] Mirror Data Cataloging images ??
   - [ ] [Mirror Hot fix images](https://www.ibm.com/support/pages/node/7148289?myns=swgother&mynp=OCSSFETU&mync=E&cm_sp=swgother-_-OCSSFETU-_-E)

### Upgrade process
- Update Openshift DF to 4.12
- Clusters are all on Red Hat OpenShift 4.12 so compatible with IBM Fusion 2.6.x
  - Make sure we migrate from Red Hat ODF to Fusion DF
  - [RH ODF 4.12 to IBM Fusion DF 2.6 for OCP 4.12](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=usf-upgrading-red-hat-openshift-data-foundation-412-storage-fusion-data-foundation-412)
- Upgrade from Fusion 2.6.0 to Fusion 2.6.1
- Deploy Fusion Backup and Restore service
- [Migrate Backup & Restore Legacy policies to Backup and Restore policies](https://www.ibm.com/docs/en/sfhs/2.7.x?topic=restore-migrating-from-backup-legacy).
  - The backup data stored on the S3 endpoint and the Backup and Restore Legacy catalog are not migrated by the operation above
  - [See the general note on the Backup and Restore Legacy deprecation](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=services-upgrade-prerequisites-backup-restore)
    
#### Once done with above, go to Fusion 2.7.0
- Upgrade to Fusion 2.7.0
- Upgrade to Fusion 2.7.2
- [Apply hot fix for 2.7.2](https://www.ibm.com/support/pages/node/7148289?myns=swgother&mynp=OCSSFETU&mync=E&cm_sp=swgother-_-OCSSFETU-_-E)
- Run an online backup using the new Backup and Restore
- The Backup and Restore Legacy (SPP) service is still running but can only be used for restores.

