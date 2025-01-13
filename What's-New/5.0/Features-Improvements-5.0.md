## What's new in Version 5.0 (Customized)
### Quick links
- [What's new in Version 5.0](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=overview-whats-new)

### Cloud Pak for Data command-line interface
a) **Remove files and folders from the work directory** - If you need to restart your installation or upgrade from the beginning, you can use the cpd-cli manage clean-workspace command to clean the olm-utils-workspace/work directory. The command removes all of the files and folders, except for the log files, in the directory. The command also restarts the olm-utils container.

### IBM Cloud Pak for Data Common Core services 
a) **HTTP Proxy for connections** - You can use HTTP Proxy for managing inbound and outbound traffic with the following connectors:
   - Amazon RDS for PostgreSQL
   - IBM Cloud Databases for PostgreSQL
   - PostgreSQL
   - MySQL
   - Amazon RDS for Oracle
   - Oracle

b) **Access more data with a new connector** - You can now work with data from the following data sources: 
   - Elastic Cloud
   - Microsoft Azure Synapse Analytics
   - Vertica 

c) **New property for the Microsoft SQL Server connection** -  You can now use an Azure Active Directory username and password for authentication.

d) **LDAP authentication** - Apache Impala connection can now use LDAP authentication for another way of verifying access to the connection.

e) **Connection name change: Cloudera Impala is now Apache Impala** - The Cloudera Impala connection is renamed to Apache Impala. Your previous settings for the connection remain the same. Only the connection name is changed.


### IBM IBM Knowledge Catalog
a) **Import, enrich, and assess the quality of data from additional data sources:**
   - Apache Impala
   - SAP OData
   - SingleStoreDB
   - Hive Metastore in Microsoft Azure

b) **Enhanced export of the lineage graph to PDF** - You can now export your lineage graph to an interactive PDF, that includes detailed information, such as:
   - Canvas summary
   - Time and date stamp
   - Details of each asset
   - Column lineage
   - Microsoft Azure Databricks

c) **New storage for profiling results** - Profiling results are now stored in an internal PostgreSQL database instead of the asset-files service. To retain profiling results after an upgrade to Cloud Pak for Data 5.0.3, you must migrate the results to the new storage as a post-upgrade step.

d) **Bulk edit draft artifacts** -  You can now edit multiple draft artifacts at once. Bulk edits are available for secondary categories, relationships, tags, stewards, and custom properties.

e) **Creating models is now optional for IBM Knowledge Catalog Premium and IBM Knowledge Catalog Standard** - The semantic capabilities in metadata enrichment are no longer enabled by default when you install IBM Knowledge Catalog Premium or IBM Knowledge Catalog Standard. You can now enable these capabilities by setting an installation option.
To retain the system setup when you upgrade one of these services from an earlier 5.0.x version, you must now set the enableSemanticAutomation option to true during the upgrade.

f) **Additional capabilities in IBM Knowledge Catalog Standard** - Data Refinery is now also included in IBM Knowledge Catalog Standard and you can optionally enable the Knowledge Graph component for this cartridge.

g) **Assign user groups as asset members** - You can now assign user groups as asset members. Previously, you could add only individual catalog users as asset members.

h) **Upload and update assets in bulk** - To upload and update multiple assets in bulk, you can now import and export CSV files with either asset metadata details or asset relationship details, or both.

i) **Configure asset removal** - Now, when you create a new catalog, you can also decide how you want to configure the removal of assets. You can either select to purge the assets automatically either immediately after the removal or 30 days after the removal. For previously created catalogs, you can change asset removal settings on the catalog Settings page.

j) **Enhanced governance artifact configuration** - You can now change different types of custom properties for multiple governance artifacts at the same time.

k) **Process workflow tasks in bulk** - When working with workflow tasks, you can now select a batch of compatible tasks that require the same action and then process them in bulk.

l) **Import metadata from every database** - Now, you don't have to specify the database to which you want to connect for the Informix, SAP ASE, and Microsoft SQL Server connections. With no database specified, you can import metadata from every database that is available for that connection.

m) **Enhancements in governance artifacts**
   - You can now change the primary or secondary category for multiple governance artifacts at once.
   - You can now make bulk edits when updating relationships in governance artifacts.
   - When viewing all governance artifacts of a specific type, you can now filter the list by a number of properties, including custom properties.


### Watson Studio
a) **Create git-integrated projects through API or CLI** - You can now create git-integrated projects through API or CLI.

b) **Upload data files to a folder in a project** - You can now upload data files directly to an existing folder of your choice if folders are enabled. Previously, you would upload a file to the root folder and move it into a different folder.


### Watson Studio Runtimes
a) **NLP transformer embedding models are included in Runtime 24.1** - In the Runtime 24.1 environment, you can now use natural language processing (NLP) transformer embedding models to create text embeddings that capture the meaning of a sentence or passage to help with retrieval-augmented generation tasks.

b) **New specialized NLP models are available in Runtime 24.1** - The following new, specialized NLP models are now included in the Runtime 24.1 environment:
   - A model that is able to detect and identify hateful, abusive, or profane content (HAP) in textual content.
   - Three pre-trained models that are able to address topics related to finance, cybersecurity, and biomedicine.
