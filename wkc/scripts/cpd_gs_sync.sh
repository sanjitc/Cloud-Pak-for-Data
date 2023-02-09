#!/bin/bash

function prompt_for_namespace(){
    read -p "Please provide namespace in which WKC is installed: " NAMESPACE
    echo "Job will be deployed into \"$NAMESPACE\" namespace"
}

function all_container_confirmation(){
    read -p "ARE YOU SURE YOU WANT TO CONTINUE? THIS WILL AFFECT ALL CONTAINERS, AND MAY TAKE A LONG TIME. TYPE \"YES\" TO PROCEED: " PROCESS_ALL
    if [[ $PROCESS_ALL != "YES" ]]; then
        echo "Job run cancelled."
        exit 0
    fi
    echo "All containers will be processed"
}

function prompt_for_list_of_catalogs(){
    read -p "Please provide the list of containers to synchronize separated by commas, empty list indicates processing all containers(catalog/project/space): " CATALOGS_STRING
    IFS=', ' read -r -a CATALOGS <<< "$CATALOGS_STRING"
    if [[ $CATALOGS_STRING == "" ]]; then
        all_container_confirmation
    else
        echo "Following containers will be processed: "
        for index in "${!CATALOGS[@]}"
        do
            echo "$index - ${CATALOGS[index]}"
        done
    fi    
}

function construct_db_list_string(){
    DB_STRING="["
    first=true
    for index in "${!CATALOGS[@]}"
    do
        if [ $first == false ]; then
            DB_STRING+=","
        fi
        first=false
        DB_STRING+="\"${CATALOGS[index]}\""
    done
    DB_STRING+="]"
}

function patch_cronjob(){
    oc set env -n $NAMESPACE cronjob/wkc-search-reindexing-cronjob dbs_to_sync=$DB_STRING
}

function spawn_job(){
    oc delete job -n $NAMESPACE wkc-search-reindexing-job
    oc create job -n $NAMESPACE --from=cronjob/wkc-search-reindexing-cronjob wkc-search-reindexing-job
}

function restore_cronjob(){
    oc set env -n $NAMESPACE cronjob/wkc-search-reindexing-cronjob dbs_to_sync=[]
}

prompt_for_namespace
prompt_for_list_of_catalogs
construct_db_list_string
patch_cronjob
spawn_job
restore_cronjob

