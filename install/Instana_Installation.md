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

- instana-operator.<namespace>.svc
- instana-operator.<namespace>.svc.<clusterDomain>

Replace _<namespace>_ with the namespace name where the Instana Enterprise operator will be installed.
Replace _<clusterDomain>_ with the domain name of the cluster where the Instana Enterprise operator will be installed.

b) Create the secret directly
```
kubectl create secret generic instana-operator-webhook \
    --type=kubernetes.io/tls \
    --from-file=tls.key=path/to/tls.key \
    --from-file=tls.crt=path/to/tls.crt \
    --from-file=ca.crt=path/to/ca.crt
```

2.2.3 Creating the values file
The values file contains the configurations of the Instana Enterprise operator. The available options that you can configure are listed in the [Instana Enterprise operator configuration options](https://www.ibm.com/docs/en/instana-observability/current?topic=installing-instana-enterprise-operator#instana-enterprise-operator-configuration-options) table.


