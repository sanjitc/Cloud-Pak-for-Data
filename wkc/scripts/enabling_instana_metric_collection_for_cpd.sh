#
# bash shell script for enabling Instana
#
NS=<project where CPD installed>

echo start by putting the CRDs into maintenance mode
oc patch ZenService lite-cr -n ${NS}  --type merge --patch '{"spec": {"ignoreForMaintenance": true}}'
oc patch CCS ccs-cr -n ${NS}  --type merge --patch '{"spec": {"ignoreForMaintenance": true}}'
oc patch WS ws-cr -n ${NS}  --type merge --patch '{"spec": {"ignoreForMaintenance": true}}'

# make the list of Node.js and GoLang microservices to enable for Instana
export deployment_list="asset-files-api dap-dashboards-api datastage-ibm-datastage-assets datastage-ibm-datastage-canvas datastage-ibm-datastage-caslite datastage-ibm-datastage-codegen datastage-ibm-datastage-flows datastage-ibm-datastage-migration datastage-ibm-datastage-ruleset datastage-ibm-datastage-runtime dc-main event-logger-api jobs-api jobs-ui ngp-projects-api portal-catalog portal-common-api portal-dashboards portal-job-manager portal-main portal-ml-dl portal-notifications portal-projects usermgmt wdp-dataprep wml-main zen-core runtime-assemblies-operator runtime-manager-api"

# save a copy of the deployments befome making changes
for d in $deployment_list
do
oc get deployment/$d -n ${NS} -oyaml > $d.yaml
done

echo next, remove Instana env vars if any from Node.js microservices
for d in $deployment_list
do
echo $d
oc set env deployment/$d INSTANA_ENABLED- INSTANA_AGENT_HOST- -n ${NS}
sleep 30
done

echo finally, add in both Instana env vars
for d in $deployment_list
do
echo $d
oc patch deployment $d --type=json -n ${NS} --patch '[{"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"INSTANA_ENABLED","value":"true"}},{"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"INSTANA_AGENT_HOST","valueFrom":{"fieldRef":{"apiVersion":"v1","fieldPath":"status.hostIP"}}}}]' 
sleep 30
done
