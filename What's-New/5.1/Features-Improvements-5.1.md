## What's new in Version 5.1 (Customized)
### Quick links
- [What's new in Version 5.1](https://www.ibm.com/docs/en/software-hub/5.1.x?topic=overview-whats-new#whats-new__50__title__1)


### Cloud Pak for Data Common Core Services
a) **Access more data with new connectors** 
   - Denodo
   - IBM watsonx.data™ Milvus
   - Microsoft Azure PostgreSQL

b) **Integrated service connections** - You can now add new connections using the information from existing service instances. This means that parameter values for the new connection can be automatically filled in from the existing instance.


### Analytics Engine powered by Apache Spark
a) **Automatic daily database snapshot backups** - IBM Analytics Engine now automatically backs up the metastore database each day. Administrators can restore the database from the snapshots.


### IBM Knowledge Catalog
a) **Enhanced gen AI based enrichment (IBM Knowledge Catalog Premium and IBM Knowledge Catalog Standard)**
- The granite-8b-code-instruct model replaces the previously used granite 13b model for generating asset and column descriptions. The new model provides more accurate results and needs less memory and storage.
- Business term abbreviations are now taken into account when display names are generated during metadata enrichment. If a source asset or column name matches any defined business term abbreviation, this abbreviation is used to expand the name.
- In the metadata enrichment results, you can now remove suggested display names or descriptions in bulk.

b) **Enhanced management and scheduling of metadata enrichment jobs**
- You can now configure execution windows for your metadata enrichment jobs to balance workloads. Jobs then run only within the configured time frames.
- On the new run metrics dashboard, you can monitor the progress of the individual enrichment tasks for an active metadata enrichment job run. In addition, you can explore run information for completed job runs to identify if and where issues occurred.

c) **Enhanced data quality monitoring (IBM Knowledge Catalog and IBM Knowledge Catalog Premium)**
Better target the data elements for monitoring of data quality:
- You can now configure data quality SLA rules without asset-level filters. The rules can be applied to any number of columns that have the same name or the same terms assigned, regardless of the containing data asset.
- You can now select and run data quality SLA rules as part of metadata enrichment. The rules are no longer enabled in the enrichment settings for the project.

d) **Segment data assets by column values to focus on the information you need**
You can now chunk data assets into smaller data assets based on selected column values to help you access only the data that you’re interested in. You can work with connected data assets in your project or directly select a data asset and column from a connection in your project without creating a connected data asset first.

e) **Import, enrich, and assess data quality of data from additional data sources** - You can now import metadata from Dremio data lakes, enrich that data, and assess its quality.

f) **Simplify the importing of metadata to better understand your data** - You can now import metadata by using a new experience that is integrated with IBM Manta Data Lineage service. The metadata import experience process is simplified and provides more lineage import configuration options, which can help you to understand how data flows in more detail.

g) **IBM Knowledge Catalog now store data in a Neo4j graph database** -  All editions of IBM Knowledge Catalog now use a Neo4j graph database to store lineage and relationship information. Neo4j provides greater data consistency while improving scaling and performance.

Neo4j is the graph database that is used with the IBM Manta Data Lineage service. If you want to use the MANTA Automated Data Lineage service as your lineage service or if you want to enable the relationship explorer feature, you can enable the use of FoundationDB instead of Neo4j during installation or upgrade.


### Watson Studio
a) **Schedule jobs in Git-based projects** -  You can now schedule jobs within Git-based projects. You can set up scheduling when you create the job.

