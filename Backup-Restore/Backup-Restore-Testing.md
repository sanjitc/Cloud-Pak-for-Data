### [Cloud Pak for Data online backup and restore to the same cluster with IBM Storage Fusion](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=cluster-backup-restore-storage-fusion)

1. [Preparing to back up Cloud Pak for Data with IBM Storage Fusion](https://www.ibm.com/docs/en/SSQNUZ_4.6.x/cpd/admin/fusion_bckup_prereq_same_cluster.html)
   - IBM Storage Fusion 2.5.2
   - Get list of all RSI patches
   ```
   cpd-cli manage get-rsi-patch-info --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --all
   ```
   - Is Fusion Hot Fix deployed on Stage? `https://www.ibm.com/support/pages/node/7060466`
   - Increase resource
      - Increase memory for data mover pods
      - Increase ODF ceph mds memory
      - Use local recipe, if it exists, for restore (for restore retry logic)
   - Backup all configmaps
   - Check for duplicate BR configmaps (if duplicates exist, repair duplicates)
   ```
   oc get cm -l cpdfwk.aux-kind=checkpoint -o jsonpath="{range .items[*]}{.metadata.labels.cpdfwk\.component}{': '}{.metadata.name}{'\n'}{end}" |sort
   ```
   - [Validate all installed services support online backup](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=data-services-that-support-backup-restore)
   ```
   cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE}
   ```

2. [Creating and scheduling online backups of Cloud Pak for Data with IBM Storage Fusion](https://www.ibm.com/docs/en/SSQNUZ_4.6.x/cpd/admin/bar_same_cluster_bckup_spectrum.html)
   - Confirm backup process backup the following information:
      - Cloud Pak for Data operators project
      - Cloud Pak for Data instance
      - IBM Storage Fusion project
      - IBM Spectrum® Protect Plus catalog
      ```
      oc get policyassignments.data-protection.isf.ibm.com -n ${PROJECT_FUSION}
      ```
   - Backed up data is available in the backup object storage location.
   - Retrieve the spp-connection secret to find the IBM Spectrum Protect Plus URL and user interface credentials
   ```
   oc extract secret/spp-connection --to=- -n ${PROJECT_FUSION}
   ```
