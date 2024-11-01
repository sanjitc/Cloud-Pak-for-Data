# Pod reference table
The following table provides reference information on the pods making up CPD and its services.

|Pod name|Service|Scope*|Description*|Connected pods*|Impact of being down*|Impact of restart*|
|---|---|---|---|---|---|---|
|audit-trail-service|WKC|AD, QS|Used for storing AD, and QS job history and details. Removed in CPD V4.0.|c-db2oltp-iis-db2u-0, iis-xmetarepo||Do not restart while discovery runs|
|c-db2oltp-iis-db2u-0|WKC|AD, DQ, IAS, MI|XMeta metadata repository storing IAS, MI, and AD metadata (all legacy IGC metadata). Replaces iis-xmetarepo pod starting from CPD V4.0|iis-services, ia-analysis|AD, QS, and DQ jobs won't run. The IAS, MI, and DQ UIs won't be available.|Requires subsequent restart of iis-services pod.|
|c-db2oltp-wkc-db2u-0|WKC|general|Repository for DPS, wkc-glossary, wkc-workflow, lineage. Replaces wdp-db2-0 starting from CPD V4.0.|wkc-glossary-service, wkc-workflow-service, wdp-policy-service|Glossary, lieage, DPS and workflow will all be down.|Restarting will take 5-15 minutes to start the pod, while starting some of the services will be down.|
|c-db2u-dv-db2u-[1-*]|DV|DV|BigSQL Worker Nodes||||
|c-db2u-dv-db2u-0|DV|DV|BigSQL Head Node||||
|c-db2u-dv-dvapi|DV|DV|Backend DV APIs||||
|c-db2u-dv-dvcaching|DV|DV|Caching API server||||
|c-db2u-dv-dvutils-0|DV|DV|HDFS||||
|c-db2u-dv-hurricane-dv|DV|DV|BigSQL Scheduler and Metastore||||
|cassandra-0|WKC|IAS|Repository for relationship graph data|||Minor impact|
|catalog-api|WKC|general|Back-end catalog and asset service, used to store metadata for catalog, project, publishing operation etc.|wdp-couchdb, rabbitmq-ha, redis-ha-server, redis-ha-haproxy|Catalog assets won't be displayed.|Catalog assets temporarily won't be displayed.|
|couchdb|CPD|lite|Used to users and other metadata, not needed starting from V3.5||||
|dataconn-engine-opdiscovery|WKC|PRF, DPS|||||
|dataconn-engine-service|WKC|PRF, DPS|Manages dataconn-engine-spark-cluster instances|rabbitmq-ha, redis-ha-server, dataconn-engine-spark-cluster|Data flows will not be run.|There could be some missing logs for data flows which are updating at the time the pod is brought down.|
|dataconn-engine-spark-cluster|WKC|PRF, DPS|Runs data flows|rabbitmq-ha, redis-ha-server|Data flows will not be run.|Running data flows will not finish.|
|dc-main|WKC|general|Runs catalog management UIs. Responsible for authentication for catalog UI. Redis used as cache.|catalog-api, redis-ha-server||Minor impact|
|elasticsearch-master|WKC|GS|Runs elastic search engine for global search||||
|finley-ml|WKC|AD, QS|Implements term assignment machine learning capabilities.|||Running AD, QS, and DQ jobs may fail.|
|finley-public|WKC|MDE (Metadata Enrichment)|Implements term assignment machine learning capabilities for metadata enrichment.|rabbitmq-ha,catalog-api|Running MDE jobs may fail.|Running MDE jobs may fail.|
|gov-admin-ui|WKC|UG|Management UI of legacy IGC New. Used for customizing asset display page in IAS. Uses gov-app-config-service as backend.|||Affects UIs until pod is back.|
|gov-app-config-service|WKC|UG|Backend of gov-admin-ui||||
|gov-catalog-search|WKC|UG|Indexer which updates SOLR index upon receiving Kafka events|solr-0||tbd.|
|gov-enterprise-search|WKC|UG|UI serving the GraphExplorer visualization of enterprise Search graph data|shop4info-rest-0 and other shop4info services|||
|wkc-data-rules|WKC|DQ|||Data quality information couldn't be loaded||
|gov-quality-ui|WKC|AD, DQ|Data quality UI. Reads and writes to legacy Information Analyzer APIs.|iis-services||Affects UIs until pod is back.|
|gov-ui-commons|WKC|UG|Common bundle for UG UIs with resources such as fonts, icons etc., no functionality as such||||
|gov-user-prefs-service|WKC|UG|Microservice storing user specific configuration settings in key-value form, used by the UG UIs to save some personalized settings. Removed in CPD V4.0.||||
|ia-analysis|WKC|AD, QS, DQ|Backend for data quality projects. Also used for publishing QS results.|||Running AD and DQ jobs may fail. DQ UI does not work.|
|ibm-nginx|CPD|all|Proxy for handling all incoming http requests. Three instances for HA. Look into this pod if there is a UI issue but you don't see any activity in the corresponding UI pod.|several|Platform UIs and APIs won't be available.|Restarting one pod at a time should not bring downtime as the service is set up for high availablility.|
|ibm-cpd-sched[*]|Scheduler|scheduling|Placement of pods CPD pods and enforcement of resource management policies|All wprkload pods|CPD pods will remain in a pending state|Scheduler pods can safely be restarted | 
|igc-ui-react|WKC|IAS|Serving information assets, data discovery, and automation rules pages.|iis-services, gov-catalog-search-service|||
|iis-services|WKC|AD, DQ, IAS, MI|Legacy IIS services tier. Runs IAS, AD, QS, DQ, MI backend and UI components.|c-db2oltp-iis-db2u-0/iis-xmetarepo, kafka-0, zookeeper-0|AD, QS, and DQ jobs won't run. The IAS, MI, and DQ UIs won't be available.|All AD, QS, and DQ jobs are cancelled. The IAS, MI, and DQ UIs are restarted. Takes > 10 min to restart.|
|iis-xmetarepo|WKC|AD, DQ, IAS, MI|XMeta metadata repository storing IAS, MI, and AD metadata (all legacy IGC metadata). Replaced by c-db2oltp-iis-db2u-0 starting from CPD V4.0.|iis-services, ia-analysis|AD, QS, and DQ jobs won't run. The IAS, MI, and DQ UIs won't be available.|Requires subsequent restart of iis-services pod.|
|is-en-conductor|WKC|AD, DQ, DS|Legacy IIS engine tier. Runs DataStage jobs for AD, and DQ, as well as ODF.|kafka-0, zookeeper-0|AD and DQ jobs won't run.|Running AD and DQ jobs will fail.|
|is-engine-compute|WKC|AD, DS|Used for parallel execution of DataStage jobs for AD and DQ (if configured).|||Running AD and DQ jobs may fail.|
|jobs-api|||||||
|jobs-ui|||||||
|kafka|WKC|UG|Runs Apache Kafka. Used for AD/QS and for OMRS metadata sync.|is-en-conductor-0, zookeeper-0, iis-services, odf-fastanalyzer, omag|AD, QS, and DQ jobs won't run, internal OMRS sync won't work.|Running AD, SQ, and DQ jobs may fail.|
|metadata-discovery|WKC|general|WKC auto discovery feature on connections. This is back-end service for Metadata Import as well|catalog-api, rabbitmq-ha, redis-ha, projects-api, wdp-couchdb|Auto-discovery feature will be interrupted.|Asset creation of discovery process will resume.|
|metastoredb|Zen|CPD|provides core api to zen services. stores extension, users, monitoring data||||
|odf-fast-analyzer|WKC|QS|Backend for quick scan. Implements a local Hadoop cluster for running data discovery algorithms.|||Running QS jobs will fail.|
|omag|WKC|general|Responsible for the IIS/IGC side of OMRS synchronization of data assets and governance artifacts.|kafka-0, redis-ha, iis-services|No sync between information assets view and Default Catalog.|Restart may help to recover from internal sync issues.|
|portal-catalog|WKC|general|Running the WKC catalog UI and the global search result page.|c-db2oltp-wkc-db2u-0/wdp-db2, wkc-glossary-service|Catalog UI won't be available. Globals search does not work.|Catalog UI and global search temporarily not available.|
|portal-common-api|WKC|general|||||
|portal-dashboards|WKC|general|||||
|portal-job-manager|WKC||||||
|portal-main|WKC|general|UI for analytics projects.|catalog-api|Projects are not displayed.|Projects are temporarily not displayed.|
|portal-notifications|CCS|CPD,WKC|Send notification and email alert||||
|portal-projects|WKC|CPD UI|UI Project Functionality|||...|
|rabbitmq-ha|WKC|general|Used for internal messaging, a bit like Kafka in the UG stack|||No impact if restart one pod at a time since this service is HA|
|rabbitmq-ha-secret-job|WKC|general|One time job at install or upgrade time used to create secrets and certificates used by rabbitmq||Install of wkc-base-prereqs will fail if this job fails|n. a.|
|redis-ha-haproxy|WKC|general|Proxy service to redis-ha master.|redis-ha-server|WKC and WSL Uis will be down if haproxy service is down|haproxy starts quickly so downtime will be minimal.|
|redis-ha-server|WKC|general|Cache service for WKC UI and other backend microservices|redis-ha-haproxy|if all 3 pods are down the WKC and WSK Uis will be down|no impact if the pods are restarted 1 at a time since the service is HA|
|shop4info-event-consumer-0|WKC|UG|Enterprise search, receives events from Kafka||||
|shop4info-mappers-service|WKC|UG|Enterprise search related||||
|shop4info-rest-0|WKC|UG|Enterprise search, provides API interface||||
|shop4info-scheduler|WKC|UG|Enterprise search related||||
|shop4info-type-registry-service|WKC|UG|Enterprise search related||||
|solr|WKC|AD, DQ, IAS|Search index and data cache for IAS and DQ UIs. Staging area for QS results.|iis-services|DQ project and IAS UIs won't show assets. QS analysis and publish fails. |Affects DQ and IAS UIs until pod is back.|
|spawner-api|||spawns off new runtimes when a new notebook is created and keeps track of environments||||
|usermgmt|Zen|CPD|authent, authorization ,token generation, ie. User Access||||
|wdp-connect-connection|WKC|general|Provides access to the connection and datasource assets in the CAMS repository.|redis-ha-server, catalog-api, wdp-connect-connector|Connections cannot be created, or listed. Data flows referencing connected data assets will  not run. Any interaction with a data source that uses the connection service (e.g. discovery, preview, etc) will not function.|In progress operations may report errors or result in a long running spinner in the UI.  However, some operations may be processed once service resumes.  Alternatively, operation would have to be resubmitted.|
|wdp-connect-connector|WKC|general|Helper for wdp-connect-connection. Interacts directly with connectors.  No public interface.|redis-ha-server|Connections cannot be created, or listed. Data flows referencing connected data assets will  not run.  Any interaction with a data source that uses the connection service (e.g. discovery, preview, etc) will not function.|In progress operations may report errors or result in a long running spinner in the UI. However, some operations may be processed once service resumes. Alternatively, operation would have to be resubmitted.|
|wdp-couchdb|WKC|general|Repository for storing asset metadata for projects, catalogs, etc.||If all pods are down expect many issues with many services.|Restarting one pod at a time should not bring downtime as the service is set up for high availablility.|
|wdp-db2-0|WKC|general|Repository for DPS, wkc-glossary, wkc-workflow, lineage. Replaced by c-db2oltp-wkc-db2u-0 starting from CPD V4.0.|wkc-glossary-service, wkc-workflow-service, wdp-policy-service|Glossary, lieage, DPS and workflow will all be down.|Restarting will take 5-15 minutes to start the pod, while starting some of the services will be down.|
|wdp-lineage|WKC|general|Backend to serve WKC Activity lineage seen in the WKC Catalog Asset view on Lineage tab||||
|wdp-policy-service|WKC|DPS|Backend to do policy enforcement for data protection rules||||
|wdp-profiling|WKC|general|Profiling tab in WKC asset browser|wdp-profiling-ui, spark*|Profiling of data sets will not be done. Enforcing governance will be impacted.||
|wdp-profiling-messaging|WKC|general|Profiling tab in WKC asset browser||Profiling of data sets will not be done. Enforcing governance will be impacted.||
|wdp-profiling-ui|WKC|general|Implements profiling tab in WKC asset browser UI.|wdp-profiling|Viewing profiling results will be impacted. Data class information of columns will be missing in asset preview.||
|wdp-shaper|WKC|general|Data refinery||||
|wkc-bi-data-service|WKC|Reporting|Reporting for IBM Knowledge Catalog|wkc-bi-data-service|||
|wkc-glossary-service|WKC|general|Backend for WKC glossary interacts with OMAG via Kafka and uses RabbitMQ for DPS. Connects to Db2 (BGDB ), XMETA (ILGDB), uses Redis|c-db2oltp-wkc-db2u-0/wdp-db2-0, kafka-0, rabbitmq-ha-0, redis, wkc-workflow-service, wdp-policy-service, wkc-search|||
|wkc-gov-ui|WKC|WKC|UI for WKC governance artifacts and workflow. Used for starting AD and QS jobs.|wkc-glossary-service, wkc-workflow-service, wdp-search, wkc-policy-service, catalog-api, shop4info-rest-0||Affects UIs until pod is back.|
|wkc-mde-service-manager|WKC|MDE (metadata enrichment)|Managing MDE jobs and routing the different tasks of the jobs to other services ( profiling, term assignment, finley-public )|catalog-api, rabbitmq-ha, projects-api, wdp-couchdb, wdp-profiling, finley-public, wkc-term-assignment|Metadata enrichment jobs will fail.|Metadata enrichment jobs will resume, depending on the state of the job, the jobs may fail, but can be restarted manually via MDE UI.|
|wkc-metadata-imports-ui|WKC|general|UI for importing asset metadata into project and running metadata enrichment.||||
|wkc-search|WKC|GS|Global Search||||
|wkc-term-assignment|WKC|MDE (metadata enrichment)|Automatically assigning terms during metadata enrichment|finley-public,rabbitmq-ha,catalog-api|Metadata enrichment jobs will fail.||
|wkc-workflow-service|WKC|WF|Backend for wkc governance artifacts workflow capabilities|c-db2oltp-wkc-db2u-0/wdp-db2, wkc-glossary-service|||
|zen-core|Zen|CPD|homepage, navigation, banner||||
|zen-core-api|Zen|CPD|vault, CyberArk||Unable to access data sources||
|zookeeper|WKC|UG|Maintaining configuration information for Kafka and Solr. Used by AD/QS.|is-en-conductor-0, zookeeper-0, iis-services, odf-fastanalyzer, omag||Requires subsequent restart of kafka pod.|
|manta-admin-gui|WKC|Manta|||||
|manta-admin|WKC|Manta|||||
|manta-configuration-service|WKC|Manta|||||
|manta-dataflow|WKC|Manta|||||
|manta-flow-agent|WKC|Manta|||||
|manta-open-manta-designer|WKC|Manta|||||

(\*) *AD: Automated discovery, QS: Quick scan, IAS: Information assets, MI: Metadata import, DS: DataStage, UG: Unified governance, WKC: Watson Knowledge Catalog, ODF: Open discovery framework, PRF: Profiling, DPS: Data protection service, GS: Global search, WF: workflow*
