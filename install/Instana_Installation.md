# Instana Installation

## Table of Content

```
Part 1: Installation Option
1.1 Self-Hosted Custom Edition
1.2 Prerequisites

```

## Part 1: Installation Option
### 1.1 [Self-Hosted Custom Edition (Kubernetes or Red Hat OpenShift Container Platform)](https://www.ibm.com/docs/en/instana-observability/current?topic=backend-installation-options#option-2-sitedatakeywordselfkub)
<img width="937" alt="image" src="https://github.com/user-attachments/assets/e1c5a2fd-150e-4117-8884-de755f76226f">
The Custom Edition is the most scalable, flexible, strong high-availability options, and ease of deployment and management. Create a new self-hosted Instana backend in a Red Hat OpenShift container platform or Kubernetes cluster. 

### 1.2 [Prerequisites](https://www.ibm.com/docs/en/instana-observability/current?topic=backend-installing-custom-edition#prerequisites)
Supported versions
- Kubernetes:	1.22
- Red Hat OpenShift: 4.13 (Linux® x86_64)

Outbound network access requirements. 
- List of all remote systems that need to be reachable during installation and operation.
- set the firewall and proxy properly to allow the following outbound network access:
  ```
  Port/Protocol
  443/TCP   https://artifact-public.instana.io
            https://instana.io
            https://icr.io/instana
            https://packages.instana.io
            https://setup.instana.io
            https://agents.instana.io/helm
  ```
- Required third-party data store operators [Online](https://www.ibm.com/docs/en/instana-observability/current?topic=64-preparing#preparing-for-online-installation) [Offline](https://www.ibm.com/docs/en/instana-observability/current?topic=64-preparing#preparing-for-offline-installation)
- 
