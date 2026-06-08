# Applying patches to CPD
## Context
- **OCP:** 4.16
- **CPD:** 5.3.1 Patch 3
- **Storage:** ODF
- **Components:** cpd_platform,wkc,analyticsengine,datalineage,ws,ws_runtimes,wml,openscale,db2wh,match360
- **Airgapped:** Yes
- **Product documentation:** https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading-applying-patches

# Pre-requisites

### 1. The permissions required
- Cluster administrator 
- Instance administrator 
- Registry administrator

### 2. Setting up a client workstation
- IBM Software Hub: cpd-cli ([Download Version 14.3.1 of the cpd-cli from the IBM/cpd-cli repository on GitHub.](https://www.ibm.com/links?url=https%3A%2F%2Fgithub.com%2FIBM%2Fcpd-cli%2Freleases))
- OpenShift® CLI: [oc](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=workstation-installing-openshift-cli)
- Helm CLI: [helm](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=workstation-installing-helm-cli)

### 3. Gathering information about installed components
```
${CPDM_OC_LOGIN}

cpd-cli manage list-deployed-components \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--all=true
```

### 4. Checking for new patches
```
cpd-cli manage restart-container
cpd-cli manage list-patch
```

