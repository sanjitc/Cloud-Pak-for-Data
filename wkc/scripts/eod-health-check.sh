### An end‑of‑day CPD health check to ensure that MDI, MDE, and Publishing jobs ran properly overnight. 
### The goal is to verify that all associated pods were healthy, identify any recent pod restarts, and 
### review CPU and memory consumption.

#!/bin/bash

TOKEN=$(oc whoami -t)
THANOS_URL=$(oc get routes -n openshift-monitoring thanos-querier -o jsonpath='{.status.ingress[0].host}')
NAMESPACE=cpd
POD='spark-m|spark-w|spark-hb-control|spark-hb-nginx|mde-service-manager|wdp-profiling|term-assignment|asset-files|jobs-api|metadata-discovery|wdp-couchdb|rabbitmq'

# Pod status
printf "\n### Current pods status\n"
oc get pods -n $NAMESPACE | egrep 'NAME|spark-m|spark-w|spark-hb-control|spark-hb-nginx|mde-service-manager|wdp-profiling|term-assignment|asset-files|jobs-api|metadata-discovery|wdp-couchdb|rabbitmq'


# Pod level memory usage vs limit 
QUERY='(
  sum by (namespace, pod) (
  container_memory_working_set_bytes{image!="",namespace="cpd",pod=~".*(spark-m|spark-w|spark-hb-control|spark-hb-nginx|mde-service-manager|wdp-profiling|term-assignment|asset-files|jobs-api|metadata-discovery|wdp-couchdb|rabbitmq).*"}
  ) /
  sum (
  kube_pod_container_resource_limits{namespace="cpd",pod=~".*(spark-m|spark-w|spark-hb-control|spark-hb-nginx|mde-service-manager|wdp-profiling|term-assignment|asset-files|jobs-api|metadata-discovery|wdp-couchdb|rabbitmq).*",resource="memory"}
  )
  by (pod,namespace)) * 100'

printf "\n### Pod-level MEMORY Consumption (percentage)\n"
curl -s -H "Authorization: Bearer $TOKEN" \
  -k "https://$THANOS_URL/api/v1/query?" \
  --data-urlencode \
  "query=$QUERY" \
  | jq -r '.data.result[] | "\(.metric.pod) \(.value[1])"' | column -t | sort -nk 2,2



# Pod level CPU usage vs limit 
QUERY='(
  sum by (namespace, pod) (
  pod:container_cpu_usage:sum{namespace="cpd",pod=~".*(spark-m|spark-w|spark-hb-control|spark-hb-nginx|mde-service-manager|wdp-profiling|term-assignment|asset-files|jobs-api|metadata-discovery|wdp-couchdb|rabbitmq).*"}
  ) /
  sum by (pod,namespace)(
  kube_pod_container_resource_limits{namespace="cpd",unit="core"}
  )) * 100'

printf "\n### Pod-level CPU Consumption (percentage)\n"
curl -s -H "Authorization: Bearer $TOKEN" \
  -k "https://$THANOS_URL/api/v1/query?" \
  --data-urlencode \
  "query=$QUERY" \
  | jq -r '.data.result[] | "\(.metric.pod) \(.value[1])"' | column -t | sort -nk 2,2
