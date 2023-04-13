#!/bin/bash
  
################################
# Recover orphaed category
#
# POST /v3/categories/{CATEGORYID}/collaborators
#
# See details in https://github.ibm.com/cds-devops/wkc-glossary-service-runbook/blob/master/maintenance/Recovering%20orphaned%20category.md
################################

addr=
admin_uid=
service_id_token=
category_id=


if [ "x${addr}" = "x" -o "x${admin_uid}" = "x" -o "x${service_id_token}" = "x" -o "x${category_id}" = "x" ]
then
  echo
  echo "Need to fill-in addr, admin_uid, service_id_token, and category_id values in the script."
  echo
  exit 1
fi

addr=`echo ${addr} | sed -e 's/https\:\/\///'`
addr=`echo ${addr} | sed -e 's/http\:\/\///'`


token=${service_id_token}
token_type=Basic

curl -k -w "\n%{http_code}" -S -s -X POST \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: ${token_type} ${token}" \
-d "{
      \"members\": [
        {
          \"user_iam_id\": \"${admin_uid}\",
          \"role\": \"admin\"
        }
      ]
}" \
"https://${addr}/v3/categories/${category_id}/collaborators" | {
    read body
    read code

    if [ "x$code" = "x201" ]
    then
      echo "$body"
    else
      echo "ERROR:$code:$body"
    fi
}
