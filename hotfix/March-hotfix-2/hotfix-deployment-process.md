## Hotfix Deployment Process

### 1)	Review the hotfix installation instruction to identify Custom Resources need to patch part of the hotfix deployment.

### 2)	Take a backup of all CRs that going to patch.
-	ibm-cpd-wkc-operator pod sescription
-	CCS CR
-	WKC CR
-	AE CR


### 3)	Take a note and copy all OpenShift resources definition that changed previously part of the CR maintenance mode.
-	CCS - deployment catalog-api
-	CCS - asset-files-api deployment
-	WKC - svc finley-public

### 4)	Take out CRs from maintenance mode one at a time and wait it done with CR reconciliation. 
-	CCS 
-	WKC

### 5)	Run patch commands for deploy the hotfix.
- WKC CSV
```
oc patch csv -n ${OPERATOR_NAMESPACE} ibm-cpd-wkc.v1.6.5 --type='json' -p='[{"op": "replace", "path": "/spec/install/spec/deployments/0/spec/template/spec/containers/0/image", "value":"icr.io/cpopen/ibm-cpd-wkc-operator@sha256:9bb509867f1c5a9948796ea50b7087d23aa733eb5e88ed93a15425d98221c5d0"}] '
```
