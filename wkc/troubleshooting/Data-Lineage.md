## Pods related to IBM Data Lineage
[Pods description](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/wkc/troubleshooting/Pods_Making_CPD.md)

## Description of IBM Data Lineage Job Steps
- `inputsInitializationStep`, `inputsCompletionStep`, `dictionaryInitializationStep`, `dictionaryCompletionStep`: These are what we call "platform" steps. They update some internal state of the scanner service to make sure everything is stored properly. These four steps shouldn't take more than few seconds each.
- `bigqueryExtractorStep`: This is the step that actually extracts the metadata that is used to generate lineage.
- `bigqueryDictionaryMappingStep`: Extracts information that is necessary to identify the correct dictionary when referencing this data source from other technologies.
- `attachedInputsExtractionStep`: Fetches the external inputs that the user manually added to the MDI asset.
- `*DataflowStep`: These steps are the ones that run the analysis and generate lineage.
  -  `Dictionary`: Creates lineage assets from the extracted dictionary.
  -  `Extracted`: Analysis of inputs extracted during the ExtractorStep.
  -  `External`: Analysis of manually added external inputs.
  -  `Job`: Specific to BigQuery, analysis of BQ jobs.

## Capture wkc-data-lineage-service log with DEBUG level:

1. Set wkc-cr to maintenance mode

2. Run command
```
oc edit deployment wkc-data-lineage-service
```
In the opened editor locate `-env` section and add underneath
```
      - env:
        - name: SPRING_APPLICATION_JSON
          value: '{"logging.level.com.ibm.wdp":"DEBUG"}'
```
(Note that SPRING_APPLICATION_JSON may already be there if you did this procedure before, then only log level should be changed to DEBUG).

Save the file and wait for wkc-data-lineage-service  pod to restart.
```
oc get pod | grep wkc-data-lineage-service
```

3. Right after the service is back up and running start collections the logs
```
oc logs -f wkc-data-lineage-service-<podid> > lineage.log
```
4. Click on get lineage for problematic asset and wait for the timeout to occur. Stop the tail command a minute later.
5. Revert logs back to INFO by running
`oc edit deployment wkc-data-lineage-service` and replacing the
```
      - env:
        - name: SPRING_APPLICATION_JSON
          value: '{"logging.level.com.ibm.wdp":"INFO"}'
```

## API to retrieve the completion percentage of Lineage jobs.
```
curl --request GET \
  --url <BASE_URL>/gov_lineage/v2/scan_executions/<LINEAGE_EXECUTION_ID> \
  --header 'Authorization: Bearer <TOKEN>'
```
The <LINEAGE_EXECUTION_ID>  is the ID present in the MDI job log.
