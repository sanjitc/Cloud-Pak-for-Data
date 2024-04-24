## Fusion upgrade from 2.5.2 to 2.7.2

### Upgrade Path
Current version(2.5.2) > 2.6.0 > 2.6.1 > 2.7.0 > 2.7.1 > 2.7.2

### Documentation
- [Upgrade to 2.6 or 2.6.1](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=upgrading-storage-fusion)
- [Upgrade to 2.7.0.x](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=upgrading-storage-fusion)

### Pre upgrade checklist
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
   - [ ] ~~Mirror Data Cataloging images~~ ??
7. Mirror images in your enterprise registry / Artifactory [2.7.0, 2.7.2 and hot fix Images](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=installation-mirroring-your-images-enterprise-registry)
   - [ ] Mirror IBM Storage Fusion
   - [ ] ~~Mirror IBM Spectrum Scale~~
   - [ ] Mirror Data Foundation images
   - [ ] Mirror Backup & Restore images
   - [ ] ~~Mirror Data Cataloging images~~ ??
   - [ ] [Mirror Hot fix SDS images](https://www.ibm.com/support/pages/node/7148289?myns=swgother&mynp=OCSSFETU&mync=E&cm_sp=swgother-_-OCSSFETU-_-E) --
      Mirror instructions for applying 2.7.2 Backup & Restore hot fixes
```
skopeo copy --insecure-policy --all docker://cp.icr.io/cp/fbr/guardian-backup-service@sha256:54820def941c9ebfde1acca54368b9bc7cd34fedfa94151deb8a6766aeedc505 docker://$TARGET_PATH/guardian-backup-service@sha256:54820def941c9ebfde1acca54368b9bc7cd34fedfa94151deb8a6766aeedc505

skopeo copy --insecure-policy --all docker://cp.icr.io/cp/fbr/guardian-transaction-manager@sha256:f7e325d1a051dfacfe18139e46a668359a9c11129870a4b2c4b3c2fdaec615eb docker://$TARGET_PATH/guardian-transaction-manager@sha256:f7e325d1a051dfacfe18139e46a668359a9c11129870a4b2c4b3c2fdaec615eb

skopeo copy --insecure-policy --all docker://cp.icr.io/cp/fbr/guardian-datamover@sha256:fda1faf48cadef717de9926d37c05305103ed86e0821359423fcc8e60f250178 docker://$TARGET_PATH/guardian-datamover@sha256:fda1faf48cadef717de9926d37c05305103ed86e0821359423fcc8e60f250178

skopeo copy --all docker://cp.icr.io/cp/isf-sds/isf-application-operator@sha256:845b8b7cd012363027fdcc537ac478773754ea0c0cead5e6ac4cb8e42f44b650 docker://$TARGET_PATH/isf-application-operator@sha256:845b8b7cd012363027fdcc537ac478773754ea0c0cead5e6ac4cb8e42f44b650

skopeo copy --insecure-policy --all docker://icr.io/cpopen/guardian-dm-operator@sha256:63b136b38a07c0afdd5082bc594e0d4d6bf5a2b2cbb1297f371d7852279121c9 docker://$TARGET_PATH/guardian-dm-operator@sha256:63b136b38a07c0afdd5082bc594e0d4d6bf5a2b2cbb1297f371d7852279121c9
```

### Upgrade process
1. Update Openshift DF to 4.12 (ODF is already on 4.12)
![Fusion Servives version](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/images/Fusion-Services.png)
2. [Upgrade to 2.6.0](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=upgrading-storage-fusion)
3. Clusters are all on Red Hat OpenShift 4.12 so compatible with IBM Fusion 2.6.x
  - Make sure we migrate from Red Hat ODF to Fusion DF
  - [RH ODF 4.12 to IBM Fusion DF 2.6 for OCP 4.12 - ~~Upgrade to Fusion 2.6.0~~](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=usf-upgrading-red-hat-openshift-data-foundation-412-storage-fusion-data-foundation-412)
4. [Upgrade from Fusion 2.6.0 to Fusion 2.6.1](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=upgrading-storage-fusion)
5. [Red Hat AMQ Streams and OpenShift API for Data Protection (OADP) version requirements](https://www.ibm.com/docs/en/storage-fusion/2.6?topic=usfs-red-hat-amq-streams-openshift-api-data-protection-oadp-version-requirements) - Follow this procedure for "baas" namespaces only.
6. Deploy Fusion Backup and Restore service - Deploy it from the Fusion console.
![Deploy the B&R service using rbd storageclass](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/images/Deploy-Fusion-BR-Service.png)
7. [Migrate Backup & Restore Legacy policies to Backup and Restore policies](https://www.ibm.com/docs/en/sfhs/2.7.x?topic=restore-migrating-from-backup-legacy).
    The instruction proves an exaple. You need to change the YAML file according to your application name. Migrate each application individually. 
  - The backup data stored on the S3 endpoint and the Backup and Restore Legacy catalog are not migrated by the operation above
  - [See the general note on the Backup and Restore Legacy deprecation](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=services-upgrade-prerequisites-backup-restore)
    
#### Once done with above, go to Fusion 2.7.0
8.  [Upgrade to Fusion 2.7.0](https://www.ibm.com/docs/en/storage-fusion-software/2.7.x?topic=upgrading-storage-fusion)
   Once Fusion upgraded to 2.7.0. You need to upgrade the "Backup & Restore" service from the Fusion console. 
10. Upgrade to Fusion 2.7.1
11. Upgrade to Fusion 2.7.2
12. [Apply hot fix for 2.7.2](https://www.ibm.com/support/pages/node/7148289?myns=swgother&mynp=OCSSFETU&mync=E&cm_sp=swgother-_-OCSSFETU-_-E)
13. Run an online backup using the new Backup and Restore
14. The Backup and Restore Legacy (SPP) service is still running but can only be used for restores.

### Problem encountered
1. While mirroring "Data Foundation images" noticed oc-mirror OpenShift CLI plug-in missing on the basion node.
   > Installed oc-mirror plug-in using [OpeShift documentation](https://docs.openshift.com/container-platform/4.15/installing/disconnected_install/installing-mirroring-disconnected.html#installation-oc-mirror-installing-plugin_installing-mirroring-disconnected).

2. IBM Storage Fusion operator status does not go to Succeeded but keeps changing between "Installing > Pending > InstallReady"
   > [Known issue](IBM Storage Fusion operator where operator status does not go to Succeeded but keeps changing between "Installing > Pending > InstallReady")

3. Different fusion pods running out of memory (OOMKill) during upgrade.
   > Increased memory limit in appropriate CSV.

4. The isf-data-foundational catalog was using "version" as a tag, which caused failure in air-gapped environemnt.
   > You need to use image digest instead of tag.
   
5. In OpenShift operator index pod failed with CrashLoop. Error: "cache requires rebuild: cache reports digest as xxx, but computed digest is yyy".
   > It's a [problem related to oc-mirror](https://access.redhat.com/solutions/7041232). Need to download latest oc-mirror binary, then mirrored images using the new binary.

