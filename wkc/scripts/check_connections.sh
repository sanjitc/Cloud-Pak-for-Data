#!/bin/bash

# API endpoint
CPD_URL=cpd-wkc.apps.fix453.cp.fyre.ibm.com

# credentials, must be logged in to oc
CPD_CRED=$(oc get secret wdp-service-id --output=jsonpath='{.data.service-id-credentials}' | base64 -d | base64 -d)

LOG=all_connections.csv
LOGBAD=bad_connections.csv

CURL="curl -s -k --user ${CPD_CRED} https://${CPD_URL}"

# get list of all internal catalogs with iteration through bookmarks
ACCOUNT=999

# If you want to run on a set of catalogs, override CATALOGS
# Empty value means request the list
CATALOGS=""
#CATALOGS=cdfc8de4-e713-4756-a196-3733186861a9

if [ "${CATALOGS}" == "" ]; then
    BOOKMARK=""
    while true; do
        RES=$(${CURL}/v2/catalogs?bss_account_id=${ACCOUNT}\&limit=200\&bookmark=${BOOKMARK})
        if [ "${RES}" == "" ]; then
            break;
        fi
        BOOKMARK=$(echo ${RES} | jq '.nextBookmark' | tr -d '"')
        if [ "${BOOKMARK}" == "null" ]; then
            break;
        fi
        if [ "${BOOKMARK}" == "${PREV_BOOKMARK}" ]; then
            break;
        fi
        PREV_BOOKMARK=${BOOKMARK}
        CAT=$(echo ${RES} | jq '.catalogs[] | .metadata.guid' | tr -d '"')
        if [ "${CAT}" == "" ]; then
            break;
        fi
        CATALOGS="${CATALOGS} ${CAT}"
    done
fi

echo Total catalogs: $(echo ${CATALOGS} | wc -w)
echo All connections log: ${LOG}
echo Corrupted connections log: ${LOGBAD}
echo ===================================


# Header for CSV logs
echo "catalog_id,asset_name,asset_id,resource_key,datasource_type,connection_flags" | tee ${LOG} > ${LOGBAD}

# Iterate through all catalogs to find connections
QUERY='{"query": "asset.asset_state:available", "include": "entity"}'
for CATALOG in ${CATALOGS}; do 
    echo Processing ${CATALOG}
    RES=$(${CURL}/v2/asset_types/connection/search?catalog_id=${CATALOG} -X POST --data "${QUERY}" -H 'Content-Type: application/json')
    echo ${RES} | jq -cr '.results[] | [ .metadata.catalog_id,.metadata.name,.metadata.asset_id,.metadata.resource_key,.entity.connection.datasource_type,.entity.connection.flags ] ' | sed -e 's/^\[//g' | sed 's/]$//g'  >> ${LOG}
done

# Check for corrupted connections
grep '\\"' ${LOG} >> ${LOGBAD}

echo ===================================
echo Connections found: $(grep -v 'catalog_id,asset_name' ${LOG} | wc -l)
echo Corrupted connections found: $(grep -v 'catalog_id,asset_name' ${LOGBAD} | wc -l)
