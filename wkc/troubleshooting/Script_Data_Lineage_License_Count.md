# Script counting for licensing on Unified lineage 
## Concept 
Get number of objects using specific asset_types considered as script for licensing purposes. 

## Asset Types considered as scripts for licensing purposes 
All objects having one of asset_type below are considered a script from licensing perspective. 
```
• Custom Script 
• Custom Query 
• Custom Transformation 
• Function 
• Procedure 
• CreateViewScript 
• Package 
• Trigger 
• BigQuery Script 
• BigQuery Job Script 
• Cobol Program 
• JCL Job 
• JCL Procedure 
• Databricks SQL Scripts 
• DB2 Script 
• Hive Script 
• MSSQL Script 
• Netezza Script 
• PLSQL Script 
• PLSQL Package 
• PostgreSQL Script 
• SAPHana Script 
• SAS Program 
• Snowflake Script 
• Snowflake Pipe 
• Task 
• BTEQ Script 
• TPT Script 
• Report 
• Azure Data Factory Mapping Dataflow 
• DataStage Parallel Job 
• DataStage Sequence Job 
• DataStage Server Job 
• Fivetran Source Connector 
• IFPC Session 
• Matillion Orchestration Job 
• Matillion Transformation Job 
• MicroStrategy Dossier 
• MicroStrategy Report 
• ODI Mapping 
• Load Script 
• Sheet 
• SSIS SqlTask 
• SSIS BulkInsertTask 
• SSIS FileSystemTask 
• SSIS DataFlowTask 
• StreamSets Pipeline 
• Tableau Workbook 
• Talend Job 
• Dimension 
• Logical System 
• Logical Model File 
• Excel Workbook 
• Analysis 
• Logical Model 
• Conceptual Model 
• PigLatin Script 
• PigLatin Macro 
• Sqoop Script 
```

## Option 1 – API 
Method: 
https://cloud.ibm.com/apidocs/data-lineage-cpd/data-lineage-cpd-5.1.2#search-lineage-assets 

Request: 
```
POST /gov_lineage/v2/search_lineage_assets 
{"query":"","filters":[{"type":"asset_type","values":["specific asset type"]}],"limit":1}
```
Sample response:  
```
{ "lineage_assets": [...], "total_count": 2, "offset": 0, "limit": 1 }
```
The API call may take up to several minutes to complete, please make sure that the timeout set for response and/or any gateway/firewall timeouts are set to 30+minutes. 

### Usage 
#### Getting overall count 
To get an overall count of scripts consumed  
1. call the API with the following parameters:
```
POST /gov_lineage/v2/search_lineage_assets 
{"query":"","filters":[{"type":"asset_type","values”:["Custom Script", "Custom Query", "Custom Transformation", "Function", "Procedure", "CreateViewScript", "Package", "Trigger", "BigQuery Script", "BigQuery Job Script", "Cobol Program", "JCL Job", "JCL Procedure", "Databricks SQL Scripts", "DB2 Script", "Hive Script", "MSSQL Script", "Netezza Script", "PLSQL Script", "PLSQL Package", "PostgreSQL Script", "SAPHana Script", "SAS Program", "Snowflake Script", "Snowflake Pipe", "Task", "BTEQ Script", "TPT Script", "Report", "Azure Data Factory Mapping Dataflow", "DataStage Parallel Job", "DataStage Sequence Job", "DataStage Server Job", "Fivetran Source Connector", "IFPC Session", "Matillion Orchestration Job", "Matillion Transformation Job", "MicroStrategy Dossier", "MicroStrategy Report", "ODI Mapping", "Load Script", "Sheet", "SSIS SqlTask", "SSIS BulkInsertTask", "SSIS FileSystemTask", "SSIS DataFlowTask", "StreamSets Pipeline", "Tableau Workbook", "Talend Job", "Dimension", "Logical System", "Logical Model File", "Excel Workbook", "Analysis", "Logical Model", "Conceptual Model", "PigLatin Script", "PigLatin Macro", "Sqoop Script"]}],"limit":1}
```
2. The number of consumed scripts is value total_count in the response 
 
Linux Bash script to automate counting: 
```
#!/bin/bash 
 
# Ask for API base URL 
read -p "Enter API base URL (e.g., https://your-api-
endpoint.com): " base_url 
 
# Ask for user credentials 
read -p "Username: " username 
read -s -p "Password: " password 
echo "" 
 
# API endpoint paths 
auth_url="$base_url/icp4d-api/v1/authorize" 
data_url="$base_url/gov_lineage/v2/search_lineage_assets" 
 
# Get Bearer token 
token=$(curl -s -X POST "$auth_url" \ 
  -H "Content-Type: application/json" \ 
  -d "{\"username\":\"$username\", \"password\":\"$password\"}" 
| jq -r '.token') 
 
# Check if token was retrieved 
if [ "$token" == "null" ] || [ -z "$token" ]; then 
  echo "Failed to get token. Check username, password, or API 
URL." 
  exit 1 
fi 
 
echo "Token received." 
 
# Call the API using the Bearer token 

response=$(curl -s -X POST "$data_url" \ 
  -H "Content-Type: application/json" \ 
  -H "Authorization: Bearer $token" \ 
  -d '{ 
  "query": "", 
  "filters": [ 
    { 
      "type": "asset_type", 
      "values": [ 
        "Custom Script", 
        "Custom Query", 
        "Custom Transformation", 
        "Function", 
        "Procedure", 
        "CreateViewScript", 
        "Package", 
        "Trigger", 
        "BigQuery Script", 
        "BigQuery Job Script", 
        "Cobol Program", 
        "JCL Job", 
        "JCL Procedure", 
        "Databricks SQL Scripts", 
        "DB2 Script", 
        "Hive Script", 
        "MSSQL Script", 
        "Netezza Script", 
        "PLSQL Script", 
        "PLSQL Package", 
        "PostgreSQL Script", 
        "SAPHana Script", 
        "SAS Program", 
        "Snowflake Script", 
        "Snowflake Pipe", 
        "Task", 
        "BTEQ Script", 
        "TPT Script", 
        "Report", 
        "Azure Data Factory Mapping Dataflow", 
        "DataStage Parallel Job", 
        "DataStage Sequence Job", 
        "DataStage Server Job", 
        "Fivetran Source Connector", 
        "IFPC Session", 
        "Matillion Orchestration Job", 
        "Matillion Transformation Job", 
        "MicroStrategy Dossier", 
        "MicroStrategy Report", 
        "ODI Mapping", 
        "Load Script", 
        "Sheet", 
        "SSIS SqlTask", 
        "SSIS BulkInsertTask", 
        "SSIS FileSystemTask", 
        "SSIS DataFlowTask", 
        "StreamSets Pipeline", 
        "Tableau Workbook", 
        "Talend Job", 
        "Dimension", 
        "Logical System", 
        "Logical Model File", 
        "Excel Workbook", 
        "Analysis", 
        "Logical Model", 
        "Conceptual Model", 
        "PigLatin Script", 
        "PigLatin Macro", 
        "Sqoop Script" 
      ] 
    } 
  ], 
  "limit": 1 
}') 
 
# Extract "total_count" from the response 
total_count=$(echo "$response" | jq '.total_count') 
 
# Display the result 
echo "IBM UL Total Script Count: $total_count"
```

#### Getting detailed script count by asset type 
To get a more detailed information about number of scripts consumed per asset type iterate over the list of asset types and for each of them 
1. call the API with the asset type 
2. collect the total_count from the response 
3. print asset_type and total_count 

Other `LineageAssetFilter` such as filtering by Technology can be used to get more 
detailed per-technology script count utilization. 

## Option 2 – Neo4j database query 
Connect to Neo4j server pod 
```
oc -n ${PROJECT_CPD_INST_OPERANDS} exec -it data-lineage-neo4j-server1-0 – bash
```
Connect to Neo4j database, to be able to run Cypher query commands 
```
cypher-shell -a "neo4j+ssc://localhost:7687" -u neo4j -p "$(cat /config/neo4j-auth/NEO4J_AUTH | cut -d/ -f2)"
```
Getting overall count 
```
MATCH (n:Asset)-[:HAS_ASSET_TYPE]->(t:AssetType) WHERE t.name IN ["Custom 
Script", "Custom Query", "Custom Transformation", "Function", "Procedure", 
"CreateViewScript", "Package", "Trigger", "BigQuery Script", "BigQuery Job 
Script", "Cobol Program", "JCL Job", "JCL Procedure", "Databricks SQL 
Scripts", "DB2 Script", "Hive Script", "MSSQL Script", "Netezza Script", 
"PLSQL Script", "PLSQL Package", "PostgreSQL Script", "SAPHana Script", "SAS 
Program", "Snowflake Script", "Snowflake Pipe", "Task", "BTEQ Script", "TPT 
Script", "Report", "Azure Data Factory Mapping Dataflow", "DataStage Parallel 
Job", "DataStage Sequence Job", "DataStage Server Job", "Fivetran Source 
Connector", "IFPC Session", "Matillion Orchestration Job", "Matillion 
Transformation Job", "MicroStrategy Dossier", "MicroStrategy Report", "ODI 
Mapping", "Load Script", "Sheet", "SSIS SqlTask", "SSIS BulkInsertTask", 
"SSIS FileSystemTask", "SSIS DataFlowTask", "StreamSets Pipeline", "Tableau 
Workbook", "Talend Job", "Dimension", "Logical System", "Logical Model File", 
"Excel Workbook", "Analysis", "Logical Model", "Conceptual Model", "PigLatin 
Script", "PigLatin Macro", "Sqoop Script"] RETURN count(n); 
Sample output 
+----------+ 
| count(n) | 
+----------+ 
| 7431     | 
+----------+ 
```
> [!NOTE] - Neo4j database structure changed in IKC 5.3.x. Run the following query to get overall count. 
> ```
> MATCH (n:Asset) WHERE n.lineageType  IN ["Custom Script", "Custom Query", "Custom Transformation", "Function", "Procedure","CreateViewScript", "Package", "Trigger", "BigQuery Script", "BigQuery Job Script", "Cobol Program", "JCL Job", "JCL Procedure", "Databricks SQL Scripts", "DB2 Script", "Hive Script", "MSSQL Script", "Netezza Script", "PLSQL Script", "PLSQL Package", "PostgreSQL Script", "SAPHana Script", "SAS Program", "Snowflake Script", "Snowflake Pipe", "Task", "BTEQ Script", "TPT Script", "Report", "Azure Data Factory Mapping Dataflow", "DataStage Parallel Job", "DataStage Sequence Job", "DataStage Server Job", "Fivetran Source Connector", "IFPC Session", "Matillion Orchestration Job", "Matillion Transformation Job", "MicroStrategy Dossier", "MicroStrategy Report", "ODI Mapping", "Load Script", "Sheet", "SSIS SqlTask", "SSIS BulkInsertTask", "SSIS FileSystemTask", "SSIS DataFlowTask", "StreamSets Pipeline", "Tableau Workbook", "Talend Job", "Dimension", "Logical System", "Logical Model File", "Excel Workbook", "Analysis", "Logical Model", "Conceptual Model", "PigLatin Script", "PigLatin Macro", "Sqoop Script"] RETURN count(n);
> ```

#### Getting detailed script count by asset type 
```
MATCH (n:Asset)-[:HAS_ASSET_TYPE]->(t:AssetType) RETURN t.name, count(n) 
ORDER BY count(n) DESC;
```
Sample output 
```
+-------------------------------------+ 
| t.name                   | count(n) | 
+-------------------------------------+ 
| "Column"                 | 98684    | 
| "ColumnFlow"             | 44881    | 
| "View"                   | 5620     | 
| "CreateViewScript"       | 5489     | 
| "CreateView"             | 5487     | 
...
```
