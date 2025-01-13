## What's new in Version 5.0 - 5.0.3 (Customized)

### Quick links
- [What's new in Version 5.0](https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=overview-whats-new)

### Cloud Pak for Data command-line interface
1) **Remove files and folders from the work directory** - If you need to restart your installation or upgrade from the beginning, you can use the cpd-cli manage clean-workspace command to clean the olm-utils-workspace/work directory. The command removes all of the files and folders, except for the log files, in the directory. The command also restarts the olm-utils container.

### IBM Cloud Pak for Data Common Core services 
1) **HTTP Proxy for connections** - You can use HTTP Proxy for managing inbound and outbound traffic with the following connectors:
   - Amazon RDS for PostgreSQL
   - IBM Cloud Databases for PostgreSQL
   - PostgreSQL
   - MySQL
   - Amazon RDS for Oracle
   - Oracle

2) **Access more data with a new connector** - You can now work with data from the following data sources: 
   - Elastic Cloud
   - Microsoft Azure Synapse Analytics
   - Vertica
   - Microsoft Azure Databricks
   - MicroStrategy
   - Milvus

3) **New property for the Microsoft SQL Server connection** -  You can now use an Azure Active Directory username and password for authentication.

4) **LDAP authentication** - Apache Impala connection can now use LDAP authentication for another way of verifying access to the connection.

5) **Use data source definitions to manage and protect data that is accessed from connections** - Data source definitions are a new type of asset that you define based on a connection or connected data asset's endpoints. When you create a data source definition, you can monitor where your data is stored across multiple projects, catalogs, or multi-node data sources. You can also apply the correct protection solution (enforcement engine) based on the data source definition.


### IBM Knowledge Catalog
1) **Import, enrich, and assess the quality of data from additional data sources:**
   - Apache Impala
   - SAP OData
   - SingleStoreDB
   - Hive Metastore in Microsoft Azure
   - MicroStrategy
   - OpenLineage

2) **Enhanced export of the lineage graph to PDF** - You can now export your lineage graph to an interactive PDF, that includes detailed information, such as:
   - Canvas summary
   - Time and date stamp
   - Details of each asset
   - Column lineage
   - Microsoft Azure Databricks

3) **New storage for profiling results** - Profiling results are now stored in an internal PostgreSQL database instead of the asset-files service. To retain profiling results after an upgrade to Cloud Pak for Data 5.0.3, you must migrate the results to the new storage as a post-upgrade step.

4) **Bulk edit draft artifacts** -  You can now edit multiple draft artifacts at once. Bulk edits are available for secondary categories, relationships, tags, stewards, and custom properties.

5) **Creating models is now optional for IBM Knowledge Catalog Premium and IBM Knowledge Catalog Standard** - The semantic capabilities in metadata enrichment are no longer enabled by default when you install IBM Knowledge Catalog Premium or IBM Knowledge Catalog Standard. You can now enable these capabilities by setting an installation option.
To retain the system setup when you upgrade one of these services from an earlier 5.0.x version, you must now set the enableSemanticAutomation option to true during the upgrade.

6) **Additional capabilities in IBM Knowledge Catalog Standard** - Data Refinery is now also included in IBM Knowledge Catalog Standard and you can optionally enable the Knowledge Graph component for this cartridge.

7) **Assign user groups as asset members** - You can now assign user groups as asset members. Previously, you could add only individual catalog users as asset members.

8) **Upload and update assets in bulk** - To upload and update multiple assets in bulk, you can now import and export CSV files with either asset metadata details or asset relationship details, or both.

9) **Configure asset removal** - Now, when you create a new catalog, you can also decide how you want to configure the removal of assets. You can either select to purge the assets automatically either immediately after the removal or 30 days after the removal. For previously created catalogs, you can change asset removal settings on the catalog Settings page.

10) **Enhanced governance artifact configuration** - You can now change different types of custom properties for multiple governance artifacts at the same time.

11) **Process workflow tasks in bulk** - When working with workflow tasks, you can now select a batch of compatible tasks that require the same action and then process them in bulk.

12) **Import metadata from every database** - Now, you don't have to specify the database to which you want to connect for the Informix, SAP ASE, and Microsoft SQL Server connections. With no database specified, you can import metadata from every database that is available for that connection.

13) **Enhancements in governance artifacts**
    - You can now change the primary or secondary category for multiple governance artifacts at once.
    - You can now make bulk edits when updating relationships in governance artifacts.
    - When viewing all governance artifacts of a specific type, you can now filter the list by a number of properties, including custom properties.

14) **Data quality enhancements** - You can now add data assets or columns with the new relationship type Validates data quality of to any type of data quality rule to have the quality score and any data quality issues reported for this item on the Data quality page. With this enhancement, data quality rules with externally managed bindings and SQL-based data quality rules can now also contribute to the quality scores of assets and columns.

15) **Data protection rules are no longer enforced in projects** - Data protection rules are now only enforced in governed catalogs or by a deep enforcement solution. Assets that are added into projects from a governed catalog no longer have preview, download, or profiling restricted by data protection rules.

16) **Enhanced project list view in catalogs** - Now, when you are adding assets from a catalog to a project, you can view more than 100 projects in your project list page and add up to 50 assets at a time to your project.

17) **Enhancements in governance artifacts** - 
    - You can now make changes to multiple governance artifacts at once. Bulk edits are available when updating tags and stewards. 
    - Now you can move any category either to the top level or to any other category as a sub-category. The collaborators are also moved provided they have required permissions on the new parent category. 
    - You can now add custom properties and relationships for reference data sets.
    - Notifications about changes in governance artifacts, for example, when an artifact is added, updated, or deleted, can now be forwarded to external applications or users.

18) **Relationship Explorer to visualize your metadata** - Relationship Explorer is now available to help better understand your data. This new feature helps you to visualize, explore and govern your metadata. Discover how your governance artifacts and data assets relate with each other in a single view.

### Analytics Engine powered by Apache Spark
1) **Auto-scaling Spark workloads** - You can now enable the auto-scaling feature for a Spark application by adding the configuration setting ae.spark.autoscale.enable=true to the existing application configuration. A Spark application that has auto-scaling enabled can automatically determine the number of executors required by the application based on the application's usage.


### Watson Studio
1) **Create git-integrated projects through API or CLI** - You can now create git-integrated projects through API or CLI.

2) **Upload data files to a folder in a project** - You can now upload data files directly to an existing folder of your choice if folders are enabled. Previously, you would upload a file to the root folder and move it into a different folder.

3) **Tag projects for easy retrieval** - You can now assign tags to projects to make them easier to group or retrieve. Assign tags when you create a new project or from the list of all projects. Filter the list of projects by tag to retrieve a related set of projects.


### Watson Studio Runtimes
1) **NLP transformer embedding models are included in Runtime 24.1** - In the Runtime 24.1 environment, you can now use natural language processing (NLP) transformer embedding models to create text embeddings that capture the meaning of a sentence or passage to help with retrieval-augmented generation tasks.

2) **New specialized NLP models are available in Runtime 24.1** - The following new, specialized NLP models are now included in the Runtime 24.1 environment:
   - A model that is able to detect and identify hateful, abusive, or profane content (HAP) in textual content.
   - Three pre-trained models that are able to address topics related to finance, cybersecurity, and biomedicine.

3) **Runtime 24.1 is now available for use with Python and R** - You can now use Runtime 24.1, which includes the latest data science frameworks on Python 3.11 and on R 4.3, to run your code in Watson Studio Jupyter notebooks and in RStudio. 

4) **A new version of Jupyter notebooks editor is now available** - If you're running your notebook in environments that are based on Runtime 23.1 and 24.1, you can now:
   - Automatically debug your code
   - Automatically generate a table of contents for your notebook
   - Toggle line numbers next to your code
   - Collapse cell contents and use side-by-side view for code and output, for enhanced productivity

