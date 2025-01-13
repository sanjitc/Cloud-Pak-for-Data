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

c) **New property for the Microsoft SQL Server connection** -  You can now use an Azure Active Directory username and password for authentication.

d) **LDAP authentication** - Apache Impala connection can now use LDAP authentication for another way of verifying access to the connection.

e) **Connection name change: Cloudera Impala is now Apache Impala** - The Cloudera Impala connection is renamed to Apache Impala. Your previous settings for the connection remain the same. Only the connection name is changed.


### IBM IBM Knowledge Catalog
a) **Import, enrich, and assess the quality of data from additional data sources:**
   - Apache Impala
   - SAP OData
   - SingleStoreDB

b) **Enhanced export of the lineage graph to PDF** - You can now export your lineage graph to an interactive PDF, that includes detailed information, such as:
   - Canvas summary
   - Time and date stamp
   - Details of each asset
   - Column lineage

c) **New storage for profiling results** - Profiling results are now stored in an internal PostgreSQL database instead of the asset-files service. To retain profiling results after an upgrade to Cloud Pak for Data 5.0.3, you must migrate the results to the new storage as a post-upgrade step.

d) **Bulk edit draft artifacts** -  You can now edit multiple draft artifacts at once. Bulk edits are available for secondary category, relationships, tags, stewards, and custom properties.

