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

- AE CR
```
oc patch AnalyticsEngine analyticsengine-sample -n ${PROJECT_CPD_INSTANCE} --type=merge -p '{"spec":{"image_digests":{"spark-hb-control-plane":"sha256:ef46de7224c6c37b2eadf2bfbbbaeef5be7b2e7e7c05d55c4f8b0eba1fb4e9e4","spark-hb-jkg-v33":"sha256:4b4eefb10d2a45ed1acab708a28f2c9d3619432f4417cfbfdc056f2ca3c085f7"}}}'
```

