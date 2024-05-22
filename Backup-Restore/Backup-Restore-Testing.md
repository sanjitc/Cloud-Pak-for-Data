### [Cloud Pak for Data online backup and restore to the same cluster with IBM Storage Fusion](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=cluster-backup-restore-storage-fusion)

1. [Preparing to back up Cloud Pak for Data with IBM Storage Fusion](https://www.ibm.com/docs/en/SSQNUZ_4.6.x/cpd/admin/fusion_bckup_prereq_same_cluster.html)
   - IBM Storage Fusion 2.5.2
   - Get list of all RSI patches
   ```
   cpd-cli manage get-rsi-patch-info --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --all
   ```
   - Is Fusion Hot Fix deployed on Stage? `https://www.ibm.com/support/pages/node/7060466`
   - ~~Increase resource~~
      - ~~Increase memory for data mover pods~~
      - ~~Increase ODF ceph mds memory~~
      - ~~Use local recipe, if it exists, for restore (for restore retry logic)~~
   - Backup all configmaps
   - Check for duplicate BR configmaps (if duplicates exist, repair duplicates)
   ```
   oc get cm -l cpdfwk.aux-kind=checkpoint -o jsonpath="{range .items[*]}{.metadata.labels.cpdfwk\.component}{': '}{.metadata.name}{'\n'}{end}" |sort
   ```
   - Modify configmap wkc-foundationdb-cluster-aux-checkpoint-cm, if it exists:
      - In the data.aux-meta section:
      ```
      managed-resources:
        - resource-kind: deployment  <------------------------- delete this line
          labels: fdb-cluster=wkc-foundationdb-cluster  <------ delete this line
        - resource-kind: pod
          labels: foundationdb.org/fdb-cluster-name=wkc-foundationdb-cluster
        - resource-kind: pod  <-------------------------------- delete this line
          labels: fdb-cluster=wkc-foundationdb-cluster  <------ delete this line
      ```
   - For disconnected (air-gap) clusters, fix images referenced by tag in configmap: `cpd-zen-aux-ckpt-cm`.
        - To check for the problem: `oc get configmap/cpd-zen-aux-ckpt-cm -o yaml | grep registry.redhat.io`.
        - If any of the image instances are `ose-cli:latest`, then the issue needs to be resolved.
        - To fix:
            - Manually push the missing container image to the Artifactory (customer registry) with the following command. Example: `skopeo copy --all docker://registry.redhat.io/openshift4/ose-cli:latest docker://hptv-docker-icp4d-np.oneartifactoryci.verizon.com/openshift4/ose-cli:latest`
            - Update the ConfigMap for the CP4D backup: `oc edit cm cpd-zen-aux-ckpt-cm`
            - Change all occurrences of `registry.redhat.io/openshift/ose-cli:latest` with `<customer-registry>/openshift4/ose-cli:latest` (there are 4 occurrences).
        - Example of the instances that need to be changed:
        ```
        $ oc get configmap/cpd-zen-aux-ckpt-cm -o yaml | grep registry.redhat.io
            \     containers: \n        - name: zen-checkpoint-backup\n          image:   registry.redhat.io/openshift4/ose-cli:latest\n
            \n        - name: zen-ckpt-mark-exclusion\n          image:   registry.redhat.io/openshift4/ose-cli:latest\n
            \n        - name: zen-ckpt-mark-exclusion\n          image:   registry.redhat.io/openshift4/ose-cli:latest\n
            \n        - name: zen-ckpt-restore\n          image:   registry.redhat.io/openshift4/ose-cli:latest\n
        ```
   - Elasticsearch restore job timeout extension. This is required to allow restore of large elasticsearch data store.
        - Edit the `elasticsearch-master-aux-ckpt-cm` configmap and increase timeout from 900 seconds to 3600 seconds.
          ```
          $ oc edit cm elasticsearch-master-aux-ckpt-cm
              restore-meta: |
                post-hooks:
                  exec-job:
                    job-key: es-restore-job
                    timeout: 3600s <--- increase from 900s to 3600s
          ```
   - [For restore, make sure cpdbr service install is performed before restore is initiated.](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=utilities-installing-cpdbr-services-storage-fusion-integration)
   - [Validate all installed services support online backup](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=data-services-that-support-backup-restore)
   ```
   cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INSTANCE}
   ```

2. [Creating and scheduling online backups of Cloud Pak for Data with IBM Storage Fusion](https://www.ibm.com/docs/en/SSQNUZ_4.6.x/cpd/admin/bar_same_cluster_bckup_spectrum.html)
   - Confirm backup process backup the following information:
      - Cloud Pak for Data operators project
      - Cloud Pak for Data instance
      - IBM Storage Fusion project
      - ~~IBM Spectrum® Protect Plus catalog~~
      ```
      oc get policyassignments.data-protection.isf.ibm.com -n ${PROJECT_FUSION}
      ```
   - Backed up data is available in the backup object storage location.
   - In IBM Spectrum Protect Plus, create a daily backup policy for the IBM Spectrum Protect Plus catalog and then back up the catalog.
      - Retrieve the spp-connection secret to find the IBM Spectrum Protect Plus URL and user interface credentials
      ```
      oc extract secret/spp-connection --to=- -n ${PROJECT_FUSION}
      ```
      - Log in to IBM Spectrum Protect Plus.
      - Select **Manage Protection > Policy Overview > Add SLA Policy**.
      - Select the category **IBM Spectrum Protect Plus catalog**, and then select **Catalog to Object Storage**.
      - Set **Start Time** to 30 minutes after the IBM Storage Fusion control plane policy.
      - Go to **Manage Protection > IBM Spectrum Protect Plus > Backup**.
      - To assign the policy to the catalog backup, under **SLA Policy**, select the policy that you created and click **Save**.
      - In the SLA Status Policy page, click the **Actions** menu and then click **Start** to start the backup.

3. [Restoring a Cloud Pak for Data online backup to the same cluster with IBM Storage Fusion](https://www.ibm.com/docs/en/SSQNUZ_4.6.x/cpd/admin/restore_same_cluster_fusion_spp.html)
   - Make sure no custom resource is in maintenance mode.
   - Delete the Cloud Pak for Data instance project
   ```
   oc delete namespace ${PROJECT_CPD_INSTANCE} and ibm-common-services
   ```
   **Don't** delete the IBM Storage Fusion project 
   - In IBM Storage Fusion, go to **Applications** and check application name. Application name should not ends with `:resources`. Start restoring with "ibm-common-services", next "Cloud Pak for Data instance".
     [https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=data-restoring-backup](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=data-restoring-backup)
     ![Restoring ibm-common-service namespace from SPP console](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/images/restore-ibm-common-service.png)
   - During restore approve any install plans as the operators are restored.
   - Restore of Db2 might fail if `/mnt/blumeta0` is restored with permissions 755 instead of 777.
      - Workaround is to manually change the permissions of `/mnt/blumeta0` to 777.
      - If the issue is detected and resolved early enough in the restore process, then the restore might finish successfully.
      - If the issue is not detected and the restore fails, then the permissions can be manually fixed and restore retry attempted.
      - This is an ODF 4.12 (and beyond) change in the way permissions are restored.
   - "Connection to remote host was lost” message.
      - There is a known issue where a restore (or backup) will fail in Fusion during recipe workflow due to a lost connection.
      - When this occurs, the only thing to do is to cleanup and retry the restore.
  
4. [Post-restore tasks after restoring a Cloud Pak for Data online backup](https://www.ibm.com/docs/en/SSQNUZ_4.6.x/cpd/admin/fusion_post_restore_same_clustr.html)
   - Watson Knowledge Catalog metadata enrichment jobs
   - Watson Knowledge Catalog lineage data import jobs
   - After restore is complete, perform the disable selinux relabeling patch: `https://www.ibm.com/support/pages/node/7105604`
   - Check if the apple-fdb-controller-manager operator pod, in the cpd operators namespace, fails to come up with oom
      - To resolve, increased the memory for the failing pod in the foundationdb csv.
   - During WKC reconcile, the wkc-base will fail if return code 409 is not accepted as a good rc.
      - Manually edit the wkc-post-install-config script and skip the check for both HTTP rc 200 and 409.
      ```
      $ oc edit cm wkc-post-install-config
         Change line:    if [ "$http_code" != "409" ] && [ "$http_code" != "200" ]; then`
      ```

### Problem encountered
1. Restore failed to schedule db2-iis pod during posthooks phase.
> Db2 pod scheduled on a node that don't have enough resource. Identify the node with lack of resouce.
```
for node in $(oc get nodes -l node-role.kubernetes.io/worker= --no-headers |awk '{print $1}');do echo -- $node --;oc describe node $node |sed -n '/Capacity:/,/Allocatable:/p'|grep -vE "Allocatable|hugepage|kubevirt";oc describe node $node |sed -n '/Allocated resources:/,/Events:/p' |grep -vE "Events|hugepage|kubevirt";done
```
> Before restart a failed restore, you need to use a local recipe. Update spp-agent cluster for use local recipe. Ref. https://www.ibm.com/support/pages/node/7060466.
```
$ oc edit clusterrole baas-spp-agent
  "useLocalRecipe": True
```
> 
> Need to cordon the node, delete some other pods and uncordon the node.
> Manually restart posthooks - `/cpdbr-scripts/cpdbr/checkpoint_restore_posthooks.sh --scale-wait-timeout=30m --include-namespaces=<CPD ns>`

2. The posthooks phase failing on elasticsearch restore job timeout.
> Edit the `elasticsearch-master-aux-ckpt-cm` configmap and increase timeout from 900 seconds to 9000 seconds.
```
          $ oc edit cm elasticsearch-master-aux-ckpt-cm
              restore-meta: |
                post-hooks:
                  exec-job:
                    job-key: es-restore-job
                    timeout: 9000s <--- increase from 900s to 9000s
```
