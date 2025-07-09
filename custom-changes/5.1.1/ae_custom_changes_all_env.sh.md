#!/bin/bash

### Custom changes for analyticsengine-sample CR on v5.1.1

#set -x

## Change the project name
export ns=wkc

function put_cr_in_maintenance(){
  oc patch -n $ns ae analyticsengine-sample --type=merge --patch='{"spec":{"ignoreForMaintenance":true}}'
}

function update_cm-spark-hb-deployment-properties(){
  cm=spark-hb-deployment-properties
  echo "Updating $cm."
  oc get -n $ns cm $cm -oyaml > cm_$cm$$.yaml
  if [ ! `oc get -n $ns cm $cm -oyaml|grep deploymentStatusRetryCount` ]; then
	  echo "Updating cm $cm"
	  oc get -n $ns cm $cm -oyaml|sed '/deployment-properties: /a\    deploymentStatusRetryCount=6' | oc apply -f -
  else
	  echo "deploymentStatusRetryCount has already set in the configmap $cm"
  fi

  #oc patch cm $cm -n $ns --type=json \
  #   --patch='[{"op": "replace", "path": "/data/enforceAuthorizeReporting", "value": "true"},{"op": "replace", "path": "/data/defaultAuthorizeReporting", "value": "true"}]'
}

put_cr_in_maintenance
update_cm-spark-hb-deployment-properties
