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
6. [Mirror images in your enterprise registry / Artifactory](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=ersfi-mirroring-your-images-enterprise-registry)
   - [ ] Mirror Red Hat OpenShift Container Platform release images.
   - [ ] Mirror images for Red Hat operator.
   - [ ] Mirror IBM Storage Fusion,
   - [ ] Mirror IBM Spectrum Scale,
   - [ ] Mirror IBM Spectrum Protect Plus,
   - [ ] Mirror Backup & Restore images,
   - [ ] Mirror Data Cataloging images. 
