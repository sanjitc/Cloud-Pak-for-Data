#!/bin/bash

### Custom changes for datalineage-cr CR on v5.1.1

#set -x

## Change the project name
export ns=wkc

function put_cr_in_maintenance(){
  oc patch -n $ns datalineage datalineage-cr --type=merge --patch='{"spec":{"ignoreForMaintenance":true}}'
}

function update_ex-datalineage-ui-routes(){
  ex=datalineage-ui-routes
  echo "Updating zenextention $ex."
  oc get -n $ns zenextension $ex -oyaml > ex_$ex$$.yaml
  if [ ! `oc get -n $ns zenextension $ex -oyaml|grep "keepalive_timeout 30s"` ]; then
          echo "No changes needed."
  else
	  echo "Updating zenextention $ex"
	  oc get -n $ns zenextension $ex -oyaml|sed -e '/add_header Content-Security-Policy/a\      proxy_read_timeout 30m;' -e 's/keepalive_timeout 30s;/keepalive_timeout 30m;/' | oc apply -f -
  fi
}

put_cr_in_maintenance
update_ex-datalineage-ui-routes
