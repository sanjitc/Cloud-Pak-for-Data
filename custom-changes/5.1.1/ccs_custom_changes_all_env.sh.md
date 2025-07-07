#!/bin/bash

### Custom changes for CCS CR on v5.1.1

#set -x

## Change the project name
export ns=wkc

function put_cr_in_maintenance(){
  oc patch -n $ns ccs ccs-cr --type=merge --patch='{"spec":{"ignoreForMaintenance":true}}'
}

function update_deploy-portal-projects(){
  dm=portal-projects
  TOTAL_PROJECT_THRESHOLD=5000
  echo "Updating $dm deployment."
  oc get -n $ns deploy $dm -oyaml > deploy_$dm$$.yaml
  oc set -n $ns env deploy $dm "TOTAL_PROJECT_THRESHOLD=$TOTAL_PROJECT_THRESHOLD"
}

function update_cm-ccs-features-configmap(){
  cm=ccs-features-configmap
  echo "Updating $cm."
  oc get -n $ns cm $cm -oyaml > cm_$cm$$.yaml
  oc patch configmap ccs-features-configmap -n $ns --type=json \
     --patch='[{"op": "replace", "path": "/data/enforceAuthorizeReporting", "value": "true"},{"op": "replace", "path": "/data/defaultAuthorizeReporting", "value": "true"}]'
}

put_cr_in_maintenance
update_deploy-portal-projects
update_cm-ccs-features-configmap
