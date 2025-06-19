datasource_definition_info.technology:
- technology of the associated DSD
- *Example*: "IBM Db2"

datasource_definition_info.scanner:
- type of scanner used for generating the lineage
- *Example*: "IBM Db2 on Cloud"

lineage_scanning_phases:
- a list of phases executed as part of the lineage metadata import
- *Accepted element values*: "extraction_of_transformations", "processing_of_extracted_inputs", "processing_of_external_inputs", "processing_of_all_inputs", "dictionary_processing" (not all scanners use all of these)

metadata_ingestion_info:
- currently unused by the lineage scanner service

extraction_info:
- configuration of lineage extraction

extraction_info.connection_type:
- how should extraction be executed
- *Accepted values*: "direct", "agent"

extraction_info.external_agent:
- agent group ID for the agent group that extraction of this asset should be assigned to (only applicable if `extraction_info.connection_type == "agent"`)

file_configuration:
- settings that impact how external inputs are processed

file_configuration.encoding:
- the text encoding that external inputs are read with. defaults to UTF-8 if not specified.
- *Example*: "UTF-8" 

file_configuration.enable_replacements:
- flag enabling the application of script replacements on external inputs
- *Accepted values*: "true", "false"

file_configuration.replacements:
- configuration of script replacements

file_configuration.replacements.replacement_scope:
- regular expression matching the path of inputs this replacement applies to
- *Example*: "mydb/myschema/*.sql"

file_configuration.replacements.placeholder_value:
- value of the placeholder that should be replaced

file_configuration.replacements.replacement_value:
- value that the placeholder should be replaced with

file_configuration.placeholders_are_expressions:
- flag indicating whether script replacement placeholders are interpreted as regular expressions instead of simple strings
- *Accepted values*: "true", "false"

