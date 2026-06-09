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
Output from list-patch:
```
Components                    Current   Available
--------------------------------------------------
cpd_platform                  5.4.3     5.4.6
zen                           6.4.3     6.4.5
cpfs                          4.18.0    4.18.1
analyticsengine               5.3.3     5.3.6
ccs                           12.1.3    12.1.6
datalineage                   5.3.13    5.3.15
datarefinery                  12.1.2    12.1.4
datastage_ent                 5.3.2     5.3.5
db2u                          7.5.3     7.5.4
db2wh                         5.3.2+12.1.3.0-cn2.37175.3.3
ibm_neo4j                     1.3.13    1.3.15
match360                      4.11.59   4.11.66
opencontent_opensearch        1.2.0     1.4.3
opencontent_fdb               5.3.4     5.3.5
openscale                     5.3.3     5.3.4
wkc                           5.3.13    5.3.15
wml                           5.3.2     5.3.4
ws                            12.1.3    12.1.4
ws_runtimes                   12.1.1    12.1.3
--------------------------------------------------
Current patch id : 3
Available patch ids : 4,5,6
```

