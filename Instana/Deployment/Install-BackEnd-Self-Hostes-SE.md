# Installing Instana backend self-hosted standard edition and data stores

## 1. Documentation:
   https://www.ibm.com/docs/en/instana-observability/1.0.302?topic=edition-installing

## 2. Prerequisites

## 3. Instana backend server installation
   
Instana server installation Instructions for air-gapped

3.1 For an air-gapped environment, an air-gapped package must be created first on a bastion host using the Instana cli tool stanctl.
       Follow the instructions from - https://www.ibm.com/docs/en/instana-observability/1.0.301?topic=edition-installing#adding-instana-repository
       Mirroring the repositories - https://www.ibm.com/docs/en/instana-observability/1.0.301?topic=edition-installing#mirroring-the-repositories
       
3.2 The latest version of the Instana cli tool stanctl must be installed from the Instana repository using packackge manager as described in the public documentation.
       Follow the instructions from - https://www.ibm.com/docs/en/instana-observability/1.0.301?topic=edition-installing#installing-stanctl-command-line-tool
       
3.3 Take sales_key and download_key from the settings.hcl.

3.4 Create the air-gapped package by using the following command.
```
stanctl air-gapped package --download-key <download_key> --sales-key <sales_key>  --license-file /path/to/license.json --instana_version 3.297.455-0
```

3.5  Transfer the resulting tar package to the Instana air-gapped host.
Make the Instana cli binary available with the command below.
```
tar -xzf </path/to/instana-airgapped.tar.gz> -C /usr/local/bin --strip-components 1 airgapped/stanctl
```

3.6  Import all artifacts with:
```
stanctl air-gapped import --file </path/to/instana-airgapped.tar.gz>
```

3.7  Now the Instana can be installed.
```
stanctl up --cluster-data-dir  /var/lib/rancher/k3s  --volume-data /instana/data --volume-objects /instana/objects --volume-analytics /instana/analytics --volume-metrics /instana/metrics --unit-tenant-name prod  --unit-unit-name instana --download-key <download_key> --sales-key <sales_key> --install-type production --multi-node-enable --multi-node-ips  <<IP for node1>,<IP for node2>,<IP for node3> --air-gapped --core-base-domain instana.prod.xyz.com --core-use-tu-url-path
```
