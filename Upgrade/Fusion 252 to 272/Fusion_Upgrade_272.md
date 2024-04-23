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
6. Mirror images in your enterprise registry / Artifactory [2.6 Images](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=ersfi-mirroring-your-images-enterprise-registry)
   - [ ] Mirror Red Hat OpenShift Container Platform release images.
   - [ ] Mirror images for Red Hat operator
   - [ ] Mirror IBM Storage Fusion
   - [ ] Mirror IBM Spectrum Scale
   - [ ] Mirror IBM Spectrum Protect Plus
   - [ ] Mirror Backup & Restore images
   - [ ] Mirror Data Cataloging images 
7. Mirror images in your enterprise registry / Artifactory [2.7 Images](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=installation-mirroring-your-images-enterprise-registry)
   - [ ] Mirror IBM Storage Fusion
   - [ ] Mirror IBM Spectrum Scale
   - [ ] Mirror Data Foundation images
   - [ ] Mirror Backup & Restore images
   - [ ] Mirror Data Cataloging images 

### Upgrade process
- Verizon clusters are all Red Hat OpenShift 4.12 so compatible with IBM Fusion 2.6.x
  - Make sure we migrate from Red Hat ODF to Fusion DF
  - RH ODF 4.12 to IBM Fusion DF 2.6 for OCP 4.12  here

- Upgrade from Fusion 2.6.0 to Fusion 2.6.1
- Deploy Fusion Backup and Restore service
- Migrate Backup & Restore Legacy policies to Backup and Restore policies (see documentation on how to do so here).
  - The backup data stored on the S3 endpoint and the Backup and Restore Legacy catalog are not migrated by the operation above
  - See the general note on the Backup and Restore Legacy deprecation here

    
- Run an online backup using the new Backup and Restore
- The Backup and Restore Legacy (SPP) service is still running but can only be used for restores.


Once done with above, go to Fusion 2.7.0
- Upgrade to Fusion 2.7.0
- Upgrade to Fusion 2.7.2
- Apply hot fix for 2.7.2 here
- Run an online backup using the new Backup and Restore
