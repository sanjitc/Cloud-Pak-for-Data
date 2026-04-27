# New Features in CPD 5.3.0–5.3.1

## IBM Software Hub

### 5.3.0

1. **Send monitoring data to Instana®**
   Deploy an Instana agent to send monitoring data for real-time insights and root-cause analysis.

2. **Manage automatic scaling from the web client**
   Enable or disable Horizontal Pod Autoscaler directly from the UI.

3. **Integrate with Git to promote assets**
   Use Git repositories (e.g., GitHub) to sync assets across environments.

4. **Bring your own applications** *(Premium)*
   Deploy custom applications locally or remotely on the platform.

5. **Easy-to-read health reports** *(Premium)*
   AI assistant displays monitoring data in tabular summaries.

6. **Dig deeper into monitoring data** *(Premium)*
   Links to detailed monitoring pages for deeper insights.

7. **GitOps with Argo CD** *(Premium)*
   Use Argo CD with Helm charts stored in Git for deployment management.

---

## IBM Software Hub APIs

### 5.3.0

* Updated endpoints with pagination support:

  * `/v3/service_instances/{id}/users`
  * `/v3/service_instances/{id}/groups`
  * `/v3/service_instances/{id}/groups/{group_id}/members`

* Deprecated endpoints:

  * `/usermgmt/v2/groups`
  * `/usermgmt/v1/usermgmt/users`
  * `/zen-data/v2/serviceInstance/...`

### 5.3.1

* New endpoint:

  * `/usermgmt/v4/groups/{group_id}/members`
  * Supports pagination (default 25, max 100 users)

---

## Common Core Services

### 5.3.0

* New connectors:

  * Amazon DynamoDB, Google Drive, Informatica PowerCenter
  * Microsoft SharePoint Files, OpenSearch

* Enhancements:

  * Azure Data Lake Storage write support
  * Gzip support for Amazon S3
  * PostgreSQL v18 support
  * Match360 → IBM Master Data Management rename

* Security fixes:

  * Multiple CVEs addressed across 2023–2026

---

## IBM Knowledge Catalog

### 5.3.0

* Create SQL assets using natural language *(Tech preview)*
* Disable generative AI per project *(Premium)*
* Catalog-specific custom properties
* Manage columns in UI
* Improved term assignment tuning
* Import PK/FK and visualize relationships
* Governance artifact versioning

### 5.3.1

* Manage relationships at governance rule level
* Generate plain-language descriptions for data quality rules
* Support for Aurora MySQL/PostgreSQL
* Publish data quality rules to catalogs
* Improved roles and visibility
* Enhanced Relationship Explorer:

  * Ownership visualization
  * Resynchronization
  * Mandatory properties

---

## IBM Manta Data Lineage

### 5.3.0

* Export lineage to Collibra
* Starting parent concept in lineage graph
* Improved visualization and filtering

### 5.3.1

* New lineage data sources:

  * Power BI, SAS, Talend, SSAS, etc.
* New agent version 1.4.0 (older versions deprecated)
* Enhanced lineage graph filtering and visualization
* Ability to create assets from lineage sources

---

## Watson Machine Learning

### 5.3.0

* Support for:

  * R 4.4
  * Python 3.12 (runtime-25.1)
  * TensorFlow with GPU

* AutoAI optimization for score vs runtime

### 5.3.1

* New GenAI deployment spec: `genai-A25-py3.12`
* Deprecation of Runtime 24.1 specs

---

## Watson Studio

### 5.3.0

* Permanent project admins
* New Documentation editor for projects

### 5.3.1

* Stop notebook jobs automatically on failure

---

## Summary

CPD 5.3.x introduces major improvements in:

* Observability and monitoring
* GitOps and automation
* Data governance and quality
* Expanded data source connectivity
* AI/ML deployment enhancements
* Improved UI-driven management
