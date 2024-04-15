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

### 5)	Run patch commands for deploy the hotfix. Run one patch command at a time. Make sure CR in completed state before move on the next step.
- WKC CSV
```
oc patch csv -n ${OPERATOR_NAMESPACE} ibm-cpd-wkc.v1.6.5 --type='json' -p='[{"op": "replace", "path": "/spec/install/spec/deployments/0/spec/template/spec/containers/0/image", "value":"icr.io/cpopen/ibm-cpd-wkc-operator@sha256:9bb509867f1c5a9948796ea50b7087d23aa733eb5e88ed93a15425d98221c5d0"}] '
```

- AE CR
```
oc patch AnalyticsEngine analyticsengine-sample -n ${PROJECT_CPD_INSTANCE} --type=merge -p '{"spec":{"image_digests":{"spark-hb-control-plane":"sha256:ef46de7224c6c37b2eadf2bfbbbaeef5be7b2e7e7c05d55c4f8b0eba1fb4e9e4","spark-hb-jkg-v33":"sha256:4b4eefb10d2a45ed1acab708a28f2c9d3619432f4417cfbfdc056f2ca3c085f7"}}}'
```

- CCS CR
```
oc patch ccs ccs-cr -n ${PROJECT_CPD_INSTANCE} --type=merge -p '{"spec":{"wdp_connect_connection_image":{"name":"wdp-connect-connection@sha256","tag":"3d5fadf3ec1645dae10136226d37542a9d087782663344a1f78e0ee3af7b5aa6","tag_metadata":"6.3.325"},"wdp_connect_connector_image":{"name":"wdp-connect-connector@sha256","tag":"1b7ecb102c8461b1b9b0df9a377695b71164b00ab72391ddf4b063bd45da670c","tag_metadata":"6.3.325"},"asset_files_api_image":{"name":"asset-files-api@sha256","tag":"a1525c29bebed6e9a982f3a06b3190654df7cf6028438f58c96d0c8f69e674c1","tag_metadata":"4.6.5.4.155-amd64"},"portal_projects_image":{"name":"portal-projects@sha256","tag":"d3722fb9a7e4a97f6f6de7d2b92837475e62cd064aa6d7590342e05620b16a6a","tag_metadata":"4.6.5.4.2504-amd64"},"portal_catalog_image":{"name":"portal-catalog@sha256","tag":"4646053d470dbb7edc90069f1d7e0b1d26da76edd7325d22af50535a61e42fed","tag_metadata":"0.4.2817-amd64"},"dap_base_resources":{ "requests":{"cpu": "1", "memory": "8Gi"}, "limits":{"cpu": "4", "memory": "32Gi", "ephemeral-storage" : "1Gi"} },"dap_base_asset_files_replicas": "6"}}'
```

- WKC CR
```
oc patch wkc wkc-cr -n ${PROJECT_CPD_INSTANCE} --type=merge -p '{"spec":{"wkc_metadata_imports_ui_image":{"name":"wkc-metadata-imports-ui@sha256","tag":"53c8e2a0def2aa48c11bc702fc1ddd0dda089585f65597d0e64ec6cfba3a103e","tag_metadata":"4.6.5511"},"wdp_profiling_ui_image":{"name":"wdp-profiling-ui@sha256","tag":"85e36bf943bc4ccd7cb2af0c524d5430ceabc90f2d5a5fb7e1696dbc251e5cc0","tag_metadata":"4.6.1203-amd64"},"wkc_mde_service_manager_image":{"name":"wkc-mde-service-manager@sha256","tag":"713684c36db568e0c9d5a3be40010b0f732fa73ede7177d9613bc040c53d6ab9","tag_metadata":"1.2.55"},"wdp_profiling_image":{"name":"wdp-profiling@sha256","tag":"ecc845503e45b4f8a0c83dce077d41c9a816cb9116d3aa411b000ec0eb916620","tag_metadata":"4.6.5031-amd64"},"kg_resources":{ "requests":{"cpu": "2", "memory": "3Gi"}, "limits":{"cpu": "4", "memory": "6Gi"}},"foundationdb_full_cluster_resources":{ "requests":{"cpu": "750m", "memory": "3Gi"}, "limits":{"cpu": "750m", "memory": "6Gi"}}}}'
```

### 6)	Check correct images load to respective pods, which impacted by the hotfix. 

### 7) Check all pods are running

### 8) Post hotfix considerations
- Post CCS reconciliation

a) Change the catalog-api deployment:
```
 > oc edit deployment catalog-api -o yaml
 Add under the env variable section the following
   - name: asset_files_call_socket_timeout_ms
     value: "60000"
```

b) Change the asset-files-api deployment:
```
         args:
           - '-c'
           - |
             cd /home/node/${MICROSERVICENAME}
             source /scripts/exportSecrets.sh
             export npm_config_cache=~node
             node --max-old-space-size=12288 --max-http-header-size=32768 index.js
         command:
           - /bin/bash
```

- Post WKC reconciliation

a) Change finley-public svc:
```
> oc edit svc finley-public -o yaml

We should have:

sessionAffinity: None

Instead of:

sessionAffinity: ClientIP
 sessionAffinityConfig:
  clientIP:
   timeoutSeconds: 10800
```
