# Instana Installation

## Table of Content

```
Part 1: Installation Option
1.1 Self-Hosted Custom Edition
1.2 Prerequisites

Part 2: Installation procedure
2.1 Install the kubectl plug-in
2.2 Installing the Instana Enterprise operator
    2.2.1 Creating image pull secrets
    2.2.2 Creating TLS secrets for admission webhook
    2.2.3 Creating the values file

2.3 Installing third-party data store operators
    2.3.1 Preparing for offline installation
    2.3.2 Installing data stores on Linux x86_64

2.4 Installing the Instana Enterprise operator
    2.4.1 Install Instana Enterprise operator using custom certificates
    2.4.2 Updating the backend version
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
Storage requirements.
- Required third-party data store operators: [[Online]](https://www.ibm.com/docs/en/instana-observability/current?topic=64-preparing#preparing-for-online-installation) [[Offline]](https://www.ibm.com/docs/en/instana-observability/current?topic=64-preparing#preparing-for-offline-installation)
- BeeInstana Kubernetes Operator: [[Offline]] (https://www.ibm.com/docs/en/instana-observability/current?topic=stores-installing-beeinstana-operator#installing-the-beeinstana-kubernetes-operator-offline-air-gapped) 
- Kafka and Strimzi are compatible with the filesystem type on block storage, which can be either XFS or ext4.
- The storage for raw spans requires Read Write Many (RWX) access mode storage such as FS (CephFS or NFS) or S3-compatible storage from any provider.

## Part 2: Installation procedure
### 2.1 [Install the kubectl plug-in](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-instana-kubectl-plug-in#sitedatakeywordrhel-or-centos)
2.1.1 Add the repository by running the following command as the root user. Replace <download_key> with your download key.
```
export DOWNLOAD_KEY="<download_key>"

cat << EOF > /etc/yum.repos.d/Instana-Product.repo
[instana-product]
name=Instana-Product
baseurl=https://_:$DOWNLOAD_KEY@artifact-public.instana.io/artifactory/rel-rpm-public-virtual/
enabled=1
gpgcheck=0
gpgkey=https://_:$DOWNLOAD_KEY@artifact-public.instana.io/artifactory/api/security/keypair/public/repositories/rel-rpm-public-virtual
repo_gpgcheck=1
EOF
```

2.1.2 Install the Instana kubectl plug-in by running the following command:
```
yum clean expire-cache -y
yum update -y
yum install -y instana-kubectl-plugin
```

2.1.3 If the versionlock plug-in is not installed on your host, run the following command to install the plug-in.
```
yum install python3-dnf-plugin-versionlock
```

2.1.4 To avoid automated updates, run the following command:
```
yum versionlock add instana-kubectl-plugin
```

### 2.2 [Installing the Instana Enterprise operator](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-instana-enterprise-operator)
The Instana Enterprise operator will be installed using the kubectl plug-in.

2.2.1 Creating image pull secrets
Unless you have your own Docker registry that mirrors artifact-public.instana.io and don't require pull secrets, you need to create an image pull secret for the namespace where the Instana Enterprise operator will be installed.

a) Create a namespace where the Instana Enterprise operator will be installed. Replace <namespace_name> with the namespace name that you want, such as instana-operator.
```
kubectl create ns <namespace_name>
```
b) Install the secret in the namespace that you created.
```
kubectl create secret docker-registry <secret-name> \
    --namespace=<namespace_name> \
    --docker-username=_ \
    --docker-password=<agent_key> \
    --docker-server=artifact-public.instana.io
```

2.2.2 Creating TLS secrets for admission webhook
The operator comes with an admission webhook for defaulting, validation, and version conversion. Ensure that the TLS secret instana-operator-webhook of type kubernetes.io/tls is present. You can use ~~either cert-manager or~~ custom certificates. The secret must contain the following entries:

- ca.crt
- tls.crt
- tls.key

a) The certificate (tls.crt) must contain the following DNS names:

- instana-operator.`<namespace>`.svc
- instana-operator.`<namespace>`.svc.`<clusterDomain>`

Replace `<namespace>` with the namespace name where the Instana Enterprise operator will be installed.

Replace `<clusterDomain>` with the domain name of the cluster where the Instana Enterprise operator will be installed.

b) Create the secret directly
```
kubectl create secret generic instana-operator-webhook \
    --type=kubernetes.io/tls \
    --from-file=tls.key=path/to/tls.key \
    --from-file=tls.crt=path/to/tls.crt \
    --from-file=ca.crt=path/to/ca.crt
```

2.2.3 Creating the values file
The `values` file contains the configurations of the Instana Enterprise operator. The available options that you can configure are listed in the [Instana Enterprise operator configuration options](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-instana-enterprise-operator#instana-enterprise-operator-configuration-options) table. Update the `imagePullSecrets` field with the image pull secret that you created earlier. 

Create a `values.yaml` file in the working directory and add the following lines:
```
image:
  registry: <my.registry.com>

imagePullSecrets:
  - name: <image_pull_secret>
```

### 2.3 [Installing third-party data store operators](https://www.ibm.com/docs/en/instana-observability/current?topic=edition-setting-up-data-stores)
2.3.1 [Preparing for offline installation](https://www.ibm.com/docs/en/instana-observability/current?topic=64-preparing#preparing-for-offline-installation)

1) Prepare a bastion host that can access both the internet and your own internal image registry.

2) Install Helm on the bastion host.
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

3) Add the operator Helm chart repos.
```
helm repo add instana https://artifact-public.instana.io/artifactory/rel-helm-customer-virtual --username=_ --password=<download_key>
helm repo update
```

4) Download the Helm charts.
```
helm pull instana/ibm-clickhouse-operator --version=v1.2.0
helm pull instana/zookeeper-operator --version=1.0.0
helm pull instana/strimzi-kafka-operator --version=0.41.0
helm pull instana/eck-operator --version=2.9.0
helm pull instana/cloudnative-pg --version=0.20.0
helm pull instana/cass-operator --version=0.45.2
helm pull instana/cert-manager --version=1.13.2
```

5) Pull operator images
- Cassandra
```
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/cass-operator:1.18.2_v0.15.0
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/system-logger:1.18.2_v0.4.0
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/k8ssandra-client:0.2.2_v0.5.0
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cassandra:4.1.4_v0.18.0
```
- ClickHouse
```
docker pull artifact-public.instana.io/clickhouse-operator:v1.2.0
docker pull artifact-public.instana.io/clickhouse-openssl:23.8.10.43-1-lts-ibm
```

- Elasticsearch
```
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/elasticsearch:2.9.0_v0.13.0
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/elasticsearch:7.17.24_v0.11.0
```

- Kafka
```
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/strimzi:0.41.0_v0.11.0
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/kafka:0.41.0-kafka-3.6.2_v0.10.0
```

- PostgreSQL by using CloudNativePG
```
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/cloudnative-pg:v1.21.1_v0.7.0
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/cnpg-containers:15_v0.9.0
```

- ZooKeeper
```
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/operator/zookeeper:0.2.15_v0.13.0
docker pull artifact-public.instana.io/self-hosted-images/3rd-party/datastore/zookeeper:3.8.4_v0.14.0
docker pull artifact-public.instana.io/self-hosted-images/k8s/kubectl:v1.31.0_v0.1.0
```
6) If you are using your bastion host as the Instana host in your air-gapped environment, you do not need to complete the following steps. However, if your bastion host and the air-gapped host are different, complete these steps:

- On your bastion host, download the Helm binary for the operating system of your air-gapped host.
```
wget https://get.helm.sh/helm-v3.15.2-linux-amd64.tar.gz
```

- Copy the Helm binary file, operator images, and Helm charts from your bastion host to the host that is in your air-gapped environment.

- Install Helm on the air-gapped host. Run these commands from the location of the Helm binary file.
```
tar –xvzf helm-v3.15.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
```

2.3.2 [Installing data stores on Linux x86_64](https://www.ibm.com/docs/en/instana-observability/current?topic=64-installing)
You must install ZooKeeper before you install ClickHouse.
1) [Cassandra](https://www.ibm.com/docs/en/instana-observability/current?topic=64-installing#:~:text=Focus%20sentinel-,Cassandra,-ZooKeeper)
2) [ZooKeeper](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-zookeeper)
3) [ClickHouse](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-clickhouse)
4) [Elasticsearch](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-elasticsearch)
5) [Kafka](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-kafka)
6) [PostgreSQL](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-postgres)

After you install each data store and add the appropriate usernames and passwords to the `config.yaml` file, the `config.yaml` file looks like the following example:
```
datastoreConfigs:
  kafkaConfig:
    adminUser: strimzi-kafka-user
    adminPassword: <RETRIEVED_FROM_SECRET>
    consumerUser: strimzi-kafka-user
    consumerPassword: <RETRIEVED_FROM_SECRET>
    producerUser: strimzi-kafka-user
    producerPassword: <RETRIEVED_FROM_SECRET>
  elasticsearchConfig:
    adminUser: elastic
    adminPassword: <RETRIEVED_FROM_SECRET>
    user: elastic
    password: <RETRIEVED_FROM_SECRET>
  postgresConfigs:
    - user: postgres
      password: <RETRIEVED_FROM_SECRET>
      adminUser: postgres
      adminPassword: <RETRIEVED_FROM_SECRET>
  cassandraConfigs:
    - user: instana-superuser
      password: <RETRIEVED_FROM_SECRET>
      adminUser: instana-superuser
      adminPassword: <RETRIEVED_FROM_SECRET>
  clickhouseConfigs:
    - user: clickhouse-user
      password: <USER_GENERATED_PASSWORD>
      adminUser: clickhouse-user
      adminPassword: <USER_GENERATED_PASSWORD>
```

### 2.4 [Installing the Instana Enterprise operator](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-instana-enterprise-operator#installing-the-instana-enterprise-operator-1)
2.4.1 Install Instana Enterprise operator using custom certificates
Applying manifests directly. This option creates CRDs and installs the Operator deployment and associated resources on the Kubernetes cluster.
Install the Instana Enterprise operator in a specified namespace by using custom certificates, run the following command:
```
kubectl instana operator apply --values values.yaml --ca-bundle-base64=<base64-encoded ca.crt file> --namespace=instana-operator
```

2.4.2 Updating the backend version
The Instana backend is deployed with a default release version. Ideally, use the latest patch release or update to an available higher Instana backend version.

1) To upgrade to a higher Instana backend version, you can use the following subcommands of the `versions` command. All commands have an optional `--download-key` flag. If you do not specify the flag, the download key of the existing installation is used.

- The `identify` subcommand provides a list of currently available Instana backend versions that are compatible with the installed Custom Edition.
- The `list-images` subcommand prints a list of images of the Instana Kubernetes operator and all Instana components. You can use the --instana-version flag to specify the operator version. If you do not use the flag, all available operator versions are listed, and you can then select a version.
- The update command upgrades an existing installation to a new version. You can specify the upgrade version by using the `--instana-version` flag. Otherwise, all supported upgrade versions are displayed. You can then select a version. Alternatively, you can configure the backend version that you want to upgrade to in the core spec and apply the spec. See the following sample code.
```
...
spec:
  imageConfig:
    tag: 3.xxx.xxx-0
...
```
2) Verify the Instana backend upgrade by running the following commands:
```
kubectl get core -n instana-core
kubectl get units -n instana-units
```
Check [notes](https://www.ibm.com/docs/en/instana-observability/current?topic=ice-upgrading#upgrade-notes) for release-specific requirements.



