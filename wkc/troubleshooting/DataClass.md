# Troubleshooting - DataClass
## Prods 

```

```

## Logs

## Status

## Troubleshooting

1.  Get the Active/Failed job id form MDE job log.

2.  Use the following swagger and get the corresponding job payload for that job id (hb_task_id):
```
https://<CPD_HOST>/v2/data_profiles/api/explorer/#/Hummingbird%20tasks/getHbTask
```
3.  The job payload looks something like this:
```
{
  "id": "d67fff15-01e7-4c71-8148-164e0e0c8645",
  "account_id": "999",
  "free_account_plan": true,
  "job_type": "data_profile",
  "job_payload": "{\"application_arguments\":[\"-DwkcURL\",\"https:\\/\\/internal-nginx-svc.wkc.svc:12443\",\"-DtenantId\",\"999                             \",\"-DwkcProjectId\",\"ecb428bd-b368-4bcd-adfa-896a991c8eaf\",\"-DwkcAssetId\",\"fe3e6667-3795-483d-b17e-513acbc850f9\",\"-DIBM-WDP-Impersonate\",\"{\\\"iam_id\\\":\\\"1000330999\\\",\\\"account\\\":{\\\"bss\\\":\\\"999                             \\\"}}\",\"-of\",\"com.ibm.iis.ia.hdfs_analyzer.profiling.ProfilingOutputFormat\",\"-DtaskID\",\"MDESM##e507d7c9-7194-4004-8114-abfe8b62ada5\",\"-DrunDQA\",true,\"-DbatchSize\",10000,\"-DnbOfRowsToRead\",\"1000\",\"-DminNbOfRowsToRead\",\"0\",\"-DsampleType\",\"sequential\",\"-DnbOfValuesToClassify\",\"100\",\"-DfastClassification\",true,\"-DmaxNbColsPerTask\",250,\"-DnullabilityThreshold\",0.05,\"-DuniquenessThreshold\",0.95,\"-DdataClassificationConfidenceThreshold\",0.75,\"-DminDataClassificationConfidenceThreshold\",0.25,\"-DdataClassesMetaDataLocation\",\"profiling\\/dataClasses\\/35c87350-6198-4f95-bfc3-34e6ef9c20db\\/dataClassMetadata.json\",\"-DanalysisResourcesRetriever\",\"com.ibm.iis.ia.hdfs_analyzer.wkc.WKCResourcesRetriever\",\"-DLogLevel\",\"DEBUG\"],\"application_jar\":\"\\/opt\\/ibm\\/third-party\\/libs\\/spark2\\/quickscan-spark-*.jar\",\"engine\":{\"size\":{\"num_workers\":\"1\",\"worker_size\":{\"memory\":\"8g\",\"cpu\":2}},\"template_id\":\"spark-3.3-wkc-profiling-cp4d-template\",\"conf\":{\"spark.eventLog.enabled\":\"false\",\"spark.app.name\":\"Profiling-QuickScan\"},\"type\":\"spark\",\"env\":{\"ENVIRONMENT_NAME\":\"ugi1dev\",\"GATEWAY_URL\":\"https:\\/\\/internal-nginx-svc.wkc.svc:12443\",\"SPARK_WORKER_DIR\":\"\\/home\\/spark\\/shared\\/logs\\/executors\",\"TRUST_ALL_SSL_CERT\":\"true\"}},\"main_class\":\"com.ibm.iis.quickscan_spark.QuickScanSparkJob\"}",
  "correlation_id": "MDESM##e507d7c9-7194-4004-8114-abfe8b62ada5",
  "priority": 1,
  "job_id": "bf8f4a10-4c97-4fc9-928f-1ca76cd171cd",
  "create_time": "2023-03-30T10:07:01.880Z",
  "job_submission_time": "2023-03-30T10:07:04.570Z",
  "job_end_time": "2023-03-30T10:07:59.780Z",
  "job_execution_time": 55210,
  "retry_count": 0,
  "status": "COMPLETED"
}
```
4. From the payload, we should pick the parameter `'-DdataClassesMetaDataLocation'` value. (which is `profiling\\/dataClasses\\/35c87350-6198-4f95-bfc3-34e6ef9c20db\\/dataClassMetadata.json` in above payload). Remove the two backward slashes before every forward slash as they are only escape characters, so the value becomes profiling/dataClasses/35c87350-6198-4f95-bfc3-34e6ef9c20db/dataClassMetadata.json )
5. Use the following swagger `https://<CPD_HOST>/v2/asset_files/docs/swagger/#/Asset%20Files/getAssetFile`
    Specify Bearer token, path and project_id (make sure Range property is null, by default it is 0-100)
    This should get us a json that contains encrypted string.
6. That encrypted string can be decrypted using:
```
  echo <encryptedString> | base64 -d | gunzip | xmllint --format -
```  
