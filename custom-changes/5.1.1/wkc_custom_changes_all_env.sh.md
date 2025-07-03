#!/bin/bash

### Custom changes for WKC CR on v5.1.1

#set -x

## Change the project name
export ns=wkc

function put_cr_in_maintenance(){
  oc patch -n $ns wkc wkc-cr --type=merge --patch='{"spec":{"ignoreForMaintenance":true}}'
}


function update_deploy-wdp-lineage(){
  dm=wdp-lineage
  LS_IGNORED_ASSET_TYPES=metadata_import,metadata_enrichment_area,job,job_run,asset_image,data_intg_flow,project_mde_settings,key_analysis_result,key_analysis,key_analysis_area,ibm_import_asset,data_asset,connection,term_assignment_profile,directory_asset,data_definition,parameter_set,data_rule,data_rule_definition,data_intg_subflow,orchestration_flow,data_intg_build_stage,data_intg_cff_schema,data_intg_wrapped_stage,ds_match_specification,standardization_rule,ds_xml_schema_library,environment,data_intg_project_settings,data_intg_custom_stage,data_intg_data_set,physical_constraint,data_intg_java_library,data_intg_parallel_function,data_intg_ilogjrule,data_intg_file_set,data_intg_message_handler,notebook,data_transformatio
  echo "Updating $dm deployment."
  oc get -n $ns deploy $dm -oyaml > deploy_$dm$$.yaml
  oc set env deploy $dm "LS_IGNORED_ASSET_TYPES=$LS_IGNORED_ASSET_TYPES"
}

function update_deploy-wkc-data-lineage-service(){
  dm=wkc-data-lineage-service
  kg_neo4j_global_transaction_timeout=1120
  echo "Updating $dm deployment."
  oc get -n $ns deploy $dm -oyaml > deploy_$dm$$.yaml
  oc set env deploy $dm "kg_neo4j_global_transaction_timeout=$kg_neo4j_global_transaction_timeout"
}

put_cr_in_maintenance
update_deploy-wdp-lineage
update_deploy-wkc-data-lineage-service
