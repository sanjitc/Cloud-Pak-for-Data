#!/bin/bash
  
################################
# Recover orphaned category
#
# POST /v3/categories/{CATEGORYID}/collaborators
#
# See details in https://github.ibm.com/cds-devops/wkc-glossary-service-runbook/blob/master/maintenance/Recovering%20orphaned%20category.md
################################

addr=
admin_uid=
service_id_token=
category_id=

curl -X POST "https://${addr}/v3/categories/${category_id}/collaborators" -H  "accept: */*" -H  "Content-Type: */*" -H "Authorization: Basic ${service_id_token}" -d "{\"principal_id\":\"${admin_uid}\",\"role\":\"owner\",\"user_type\":\"USER\"}" -k
