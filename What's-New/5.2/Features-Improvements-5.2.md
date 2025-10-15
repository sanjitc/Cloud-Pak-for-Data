### New features in CPD 5.2.0 and 5.2.1

 

IBM Software Hub platform

**1\.**    	**IBM Software Hub AI assistant**

\[Premium\] The IBM Software Hub AI assistant is a specialized assistant that can help you use the platform more efficiently. The assistant can query your environment to answer questions such as:

o   What is the current vCPU quota for the platform?  
o   Which pods are using the most memory?

In addition, the AI assistant is trained on the product documentation and can help you learn how to configure and manage your environment. For example, you can ask the assistant how to:

o   Make your environment more secure  
o   Get notified when a service exceeds its quota  
o   Automatically scale resources based on your workload

   
**2\.**    	**Configure API keys to expire automatically**

IBM Software Hub API keys do not expire by default. If you want to improve application security, you can configure API keys to automatically expire. You can choose how long API keys are valid after they are created based on your company's security policies.

 

**3\.**    	**Monitor and manage internal certificate renewal**

IBM Software Hub uses internal certificates to manage the communication between pods. In most cases, the certificates are renewed automatically. However, if the renewal occurs during peak business hours, it might cause service disruptions. To minimize the impact of certificate renewals, you can:

o   Monitor upcoming certificate renewals  
o   Change the renewal date for certificates

   
**4\.**    	**Scale, shut down, and restart services from the web client**

Do you prefer a user interface to a command-line interface? You can now complete the following administrative tasks from the IBM Software Hub web client:

o   Check the current scaling configuration of a service  
o   Change the scaling configuration of a service  
o   Shut down and restart services

   
**5\.**    	**Simplified process for mirroring models and optional images**

Previously, if you wanted to mirror models or optional images to a private container registry, you needed to mirror each image separately. Starting in IBM Software Hub Version 5.2.0, you can specify a comma-separated list of group names when you run the cpd-cli manage mirror-images command. With this change, you can mirror images in fewer steps.

Common core services

**1\.**    	**Access more data with new connectors**  
o   Collibra  
o   Hive metastore  
o   Microsoft Azure Fabric Warehouse  
o   IBM FileNet P8  
o   Microsoft OneDrive  
o   Microsoft SharePoint

 

**Updates**

o   Access your Oracle data source using a User Proxy

You can now access your Oracle database by using a User Proxy, which improves performance compared to using a Generic JDBC connection.

 

Scheduling service

**1\.**    	**Audit logging**

The scheduling service now integrates with the IBM Software Hub audit logging service. Auditable events for the scheduling service are forwarded to the security information and event management (SIEM) solution that you integrate with.

 

**2\.**    	**Schedule GPUs on remote physical locations**

\[Premium\] If you use remote physical locations to expand your IBM Software Hub deployment to remote clusters, you can now use the scheduling service to schedule NVIDIA GPUs on the remote physical locations.

If the remote cluster has a cluster autoscaler, you can use the \--max\_gpu option to allow the scheduling service to schedule additional GPUs if the workload exceeds the current available GPU.

 

IBM Knowledge Catalog

**1\.**    	**Manage identical data assets consistently**

Govern connected data assets that represent the same physical resource (identical data assets) across multiple governed catalogs and specific projects. Now, connected data assets reference the same set of asset properties (shared properties), so when shared properties and their values are updated, the changes are immediately visible on all identical data assets across the specified workspaces. 

 

**2\.**    	**Generate business terms with gen AI-powered glossary generation**

In IBM Knowledge Catalog Premium, facilitate data governance by automatically generating business terms and reducing the time that is needed to establish glossaries. Business terms are generated based on specific business need. Business terms have defined names and descriptions. The terms are already linked to specific data with automatically assigned relationships to other business terms in the glossary.

 

**3\.**    	**Publish SQL query assets to catalogs**

You can now publish SQL query asset types to catalogs. In governed catalogs, previews of SQL query data assets with data protection rules enforced are also available.

 

**4\.**    	**Define execution windows for metadata import jobs**

With execution windows, you can set your metadata import jobs to run only in the specified time ranges on selected days as needed. Your job runs will pause automatically if not complete within the configured execution window, and the jobs will resume when the next execution window starts.

**5\.**    	**Enhanced setup options for gen AI capabilities**

You can now enable the generative AI capabilities in IBM Knowledge Catalog Premium with one of these model options:

o   Use a Granite model that is started on the internal containers with CPUs for LLM-based enrichment.  
o   Use local watsonx.ai inference foundation models (watsonx\_ai\_ifm) that require GPU for LLM-based enrichment, and term generation and assignment.  
o   Work with external watsonx.ai models in an existing IBM watsonx.ai instance on a remote IBM Cloud Pak for Datacluster or in IBM watsonx as a Service for LLM-based enrichment, and term generation and assignment.

 

**6\.**    	**Automate data quality analysis**

Instead of running a basic data quality analysis with a fixed set of predefined checks in metadata enrichment, you can now have data quality checks automatically generated for your data. You can immediately run these suggested checks as another step in the enrichment . Or, you can review and adjust the checks, and then add the run step to the enrichment before you re-enrich your data.

Data quality checks can be generated based on profiling results, generated based on constraints that are defined in assigned business terms, or you can manually add them to check an entire data asset or specific columns. Users can decide whether these checks should be applied without further review, or review and then have the reviewed ones applied. Available types of data quality checks include the checks that were available in earlier releases and a set of new checks, for example, checks for historical stability and referential integrity.

 

**7\.**    	**Provide additional context for name generation in metadata enrichment**

In IBM Knowledge Catalog Premium, you can now configure default enrichment settings to provide additional context to the model when you run metadata enrichment with the option to generate display names by using generative AI:

o   Use data from the sample that is generated by profiling  
o   Use a custom set of abbreviations  
o   Use assets with assigned display names

 

**8\.**    	**Rule-based term assignment**

You can now set up rules and rule groups for how you want terms to be assigned to data assets and columns. Upload the rules to a project as a CSV file for consumption by the term assignment service.

 

**9\.**    	**Import, enrich, and assess data quality of data from additional data sources**

You can now import metadata from remote file systems by using an FTP connection, enrich that data, and assess its quality.

 

**10\.**   **Add governance artifacts with View permission on the target**

You can now create a custom relationship type for governance artifacts that have only a Viewer permission on the target of the relationship. If you create this kind of relationship type, more people within the organization will be able to create necessary relationships.

 

**11\.**   **View indirect relationships on the relationship explorer canvas**

You can now see indirect relationships between items on the canvas. Indirect relationship appears when some items were hidden on the canvas and other items connects through them. Those relationships are indicated by a dashed line.

 

**12\.**   **Use AI search to find assets and artifacts**

The search experience is enhanced with LLM-based technology. You can now use AI search when searching for artifacts and assets. By extracting and rewriting your search queries with semantically equivalent terms, intelligent search provides more relevant and comprehensive results, even if your exact words are not present in the indexed content. Such results are marked with the AI icon. With AI search you can navigate through complex data catalogs effortlessly, improving data discovery by surfacing assets that would otherwise remain hidden due to mismatched terminology.

   
**13\.**   **Relationship explorer shows all SLA rules and reference data sets relationships**

The Relationship explorer now shows more relationships:

o   All items that are connected to SLA rules are displayed.  
o   Relationships between reference data values in the same or various reference data sets are displayed. One-to-one and one-to-many relationships are shown. 

These enhanced relationship visualizations provide a more complete governance view and improve impact analysis and compliance tracking.

   
**14\.**   **Select models for use with the gen AI capabilities**

If your deployment is set up to run the models for the gen AI capabilities on a remote instance of watsonx.ai™, you can now choose to work with other supported foundation models instead of the default ones. 

   
**15\.**   **Use definition-based data quality rules with external bindings multiple times in your DataStage flows**

(Tech preview) You can now create data quality rules that you can use any number of times in one or more DataStage flows. Create a definition-based rule with external bindings in the project. Then, add the rule to a DataStage flow by selecting it from the Asset Browser stage as many times as needed. When you update the respective data quality rule asset, the changes are automatically reflected in any flow that contains the rule. For each rule that you run, you can decide which associated DataStage flows are run.

 

**16\.**   **Import Knowledge Accelerators with the new user interface**

You can now import Knowledge Accelerators with the end-to-end setup interface offering a guided experience that requires no advanced technical skills. The import tool simplifies installation, so you can quickly adopt Knowledge Accelerators and drive value from data governance tools.

 

**17\.**   **Import sample predefined business terms with the Knowledge Accelerators UI**

You can now install a sample of 100 predefined business terms by using the Knowledge Accelerators importing UI. Use the sample business terms to classify personal data across key concepts such as Person, Organization, Employment Record, Contact Information, and Finance Information.

 

**Updates**

The following updates were introduced in this release:

o   For new projects, the default method for generating display names in metadata enrichment is now Generative AI.  
o   You can now select assets or columns from multiple pages for bulk actions in metadata enrichment.  
o   You can now run data quality rules on data from Salesforce.com data sources and create query-based data assets from such data sources.  
o   The Data Quality feature is now also available on Power (ppc64le) hardware.  
o   When you're creating metadata imports for discovery and lineage, you can now edit your goals after the job is completed. If you can't use a goal with the selected DSD or connection, the goal isn’t available on the Define goals page.  
o   Custom properties and relationships can now be restricted by categories.  
o   Text is now set as default when creating a new reference set.  
o   When bulk-editing categories, you can now make edits to collaborators.

* Accept or reject the display names or descriptions that are generated for data assets and columns in bulk from the metadata enrichment results (IBM Knowledge Catalog Premium).  
* Data quality SLA assessments are now also run when the data quality score of an asset changes as the result of running a data quality rule. An instance administrator can disable data quality SLA assessments for results of rule runs for the entire deployment.  
* The Knowledge Accelerators Data Privacy content has been updated to include new classified business terms in areas of Social Media, Biometrics and Location tracking. The existing classifications to guide the identification of personal information (PI) and sensitive personal information (SPI) have also been updated.  
* The following reporting enhancements were introduced:  
  * Include custom properties outside of a property group  
  * Include custom properties scoped to catalog and project

 

 

IBM Manta Data Lineage

**1\.**    	**Connect to Microsoft Azure Databricks by using the Manta agent**

You can now import lineage metadata from the Microsoft Azure Databricks data source by using an agent. You can install the Manta agent on the external data source if connecting directly from IBM Cloud Pak for Data is not possible or optimal.

 

**2\.**    	**New Apache Hive data source for lineage metadata import**

You can now import lineage metadata from the Apache Hive data source. After the data is imported, you can visualize it on a lineage graph.

 

**3\.**    	**Connect to new data sources by using the Manta agent**  
You can now import lineage metadata from the following data sources by using an agent:

·   	Amazon RDS for PostgreSQL  
·   	Amazon Redshift  
·   	Greenplum  
·   	IBM Cloud Databases for PostgreSQL  
·   	PostgreSQL  
You can install a Manta agent on a system with direct access to a data source if connecting directly from IBM Cloud Pak for Data is not possible.

 

**4\.**    	**Connect to Google BigQuery with Workload Identity Federation authentication methods**  
When you import lineage metadata from a Google BigQuery data source, you can now use a connection with these authentication methods:

·   	Workload Identity Federation with an access token

·   	Workload Identity Federation with a token URL.

These methods are used when authentication is solved by an external service.

**5\.**    	**New data sources for lineage metadata import**  
You can now import lineage metadata from the following additional data sources:  
·   	Qlik Sense  
·   	Teradata  
After the data is imported, you can visualize it on a lineage graph.

 

**6\.**    	**Select the type of display name for items on the lineage graph**

You can select a different type of display name for items. You can choose the current name, original name, or the AI-generated name that is suggested by metadata enrichment as the display name for lineage assets.

   
**7\.**    	**Customize lineage visualization with enhanced filters**  
You can now adjust the initial view of your lineage by using advanced filters. Decide on the scope of data and type of assets that you want to see on your lineage.

**Updates**  
The following updates were introduced in this release:  
·   	Column-level lineage has been enhanced so that it is easier to follow the flow of data.  
·   	When you view lineage for PostgreSQL assets, you can view the source code of the transformation asset to check the details of the transformation logic.  
·   	MicroStrategy reports and dossiers that have prompts are now displayed on lineage.  
·   	Lineage is now created for OpenLineage events that do not have input metadata defined, but have output and job metadata.  
·   	You can now share a link to your lineage canvas with others by clicking **Copy shared link** in the **Share** panel.

 

Watson Studio

**1\.  Easily navigate through and view all job runs by using the updated jobs dashboard**  
You can now use the jobs dashboard to view job runs across projects in more detail and with more flexibility. You can use the dashboard in the following ways:

o   To view job runs grouped by folders  
o   To filter runs by job type, run status, time range, and project or folder  
o   To access job definitions, run details, and associated assets

   
**2\.**    	**View failed-to-start jobs in the jobs dashboard**  
In the Jobs dashboard, you can now view and filter scheduled job runs that failed to start due to configuration issues such as expired credentials or missing assets. Jobs that did not start as scheduled are now marked with the **Failed to start** status.

 

