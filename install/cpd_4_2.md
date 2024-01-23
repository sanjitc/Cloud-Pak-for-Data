

# Customer requirements:
CPDS is already at 2.0.2.1.

Customer desires to have the following services:

Cluster is internet accessible.

No kernel changes required, all have been done by CPDS upgrade.


# Install required Redhat command packages:
Skip this step since they have been done already
yum install -y httpd-tools podman ca-certificates openssl skopeo jq bind-utils python39
pip3 install PyYAML argparse

Checking cluster health after CPDS upgrade is required:
  
 Reference:
https://github.ibm.com/cpd-swat/cpd-upgrade-runbooks/blob/main/CPDS_Check.md

 
# CPDSystem Check
Oc login /OCP console login information
oc login --token=$(cat /root/.sa/token)
/opt/ibm/appliance/platform/xcat/config_files/coreos/.kadm/kubeadmin-password

cat /opt/ibm/appliance/platform/xcat/config_files/coreos/.kadm/kubeadmin-password
Private repository username and password
podman ps
```
CONTAINER ID  IMAGE                         COMMAND               CREATED      STATUS          PORTS                   NAMES
244971306b8a  docker.io/library/registry:2  /etc/docker/regis...  8 hours ago  Up 8 hours ago  0.0.0.0:5000->5000/tcp  mirror-registry
```
oc extract secret/pull-secret -n openshift-config
```
{"auths": {"hub.fbond:5000": {"auth": "b2NhZG1pbjpvY2FkbWlu","email": "root@hub.fbond"}}}
```
check the password and repository they used
echo 'b2NhZG1pbjpvY2FkbWlu' | base64 -d
```
ocadmin:ocadmin
```
Private registry hub.fbond:5000
oc get imageContentSourcePolicy cloud-pak-for-data-mirror -o yaml
```shell
Spec:
    Repository Digest Mirrors:
    Mirrors:
      hub.fbond:5000/opencloudio
      Source: quay.io/opencloudio
    Mirrors:
      hub.fbond:5000/cp
      Source: cp.icr.io/cp
    Mirrors:
      hub.fbond:5000/cp/cpd
      Source: cp.icr.io/cp/cpd
    Mirrors:
      hub.fbond:5000/cpopen
      Source: icr.io/cpopen
    Mirrors:
      hub.fbond:5000/db2u
      Source: icr.io/db2u
```
## Verify private registry available
curl -k -u ocadmin:ocadmin https://hub.fbond:5000/v2/_catalog?n=6000 | jq .repositories.[]
Location where CPD control plane case and foundation services cases exist
/opt/ibm/appliance/storage/platform/appmgt/installers/cpdimages
export OFFLINEDIR=/opt/ibm/appliance/storage/platform/appmgt/installers/cpdimages
Free Hard disk check(need more than 300G for CP4D images)
[root@e1n1 /]# /opt/ibm/appliance/storage/platform/registry/data/

```
[root@e1n1 /]# df -h
Filesystem                                   Size  Used Avail Use% Mounted on
devtmpfs                                      95G     0   95G   0% /dev
tmpfs                                         95G   96K   95G   1% /dev/shm
tmpfs                                         95G  203M   94G   1% /run
tmpfs                                         95G     0   95G   0% /sys/fs/cgroup
/dev/sda9                                    194G  174G   11G  95% /
/dev/sda1                                    969M  181M  722M  21% /boot
/dev/sda7                                     29G  984M   27G   4% /tmp
/dev/sda5                                     38G   27G  8.9G  76% /var
/dev/sda6                                     29G  288M   27G   2% /home
/dev/loop0                                   8.0G  8.0G     0 100% /install/rhel8.2/x86_64
/dev/sda8                                    4.7G  4.0G  512M  89% /var/log/audit
/dev/mapper/raid5_appvm1_vg-raid5_appvm1_lv  655G  316G  340G  49% /appvm1
ips                                          5.9T  8.2G  5.9T   1% /opt/ibm/appliance/storage/ips
platform                                     3.0T  1.3T  1.7T  44% /opt/ibm/appliance/storage/platform
tmpfs                                         19G  4.0K   19G   1% /run/user/0
shm                                           63M     0   63M   0% /var/lib/containers/storage/overlay-containers/244971306b8a7f6c1d9ecf80ce240e70e982063969af7fd984a9792026c48b00/userdata/shm
overlay                                       38G   27G  8.9G  76% /var/lib/containers/storage/overlay/80a1edf6031cbf3e0588886dea47ded903df8aa13496e19c9b0268bc0403c0e5/merged
```
HAProxy had done
•	CRIO setting had done
•	Foundation services 3.11 by default(4.0.2)
•	Express install (zen,ibm-common-servcies)
Check namespace and operator group
Verify ibm-common-services namespace
oc get project ibm-common-services
Verify operator group
oc get OperatorGroup -n ibm-common-services


### Reset olm-utils container privileges
Rename olm-utils container and reset privileges, otherwise both users cp and kubeadmin cannot work with any cpd-cli manage commands.  This applies to CPDS installed environment only.

podman ps

if olm-utils-play exists:
podman stop olm-utils-play
podman rename olm-utils-play podman-utils-play-orig

export CPDCLI_DIR=<cpd-cli install dir>
export CPDCLI_WORK=$CPDCLI_DIR/cpd-cli-workspace/olm-utils-workspace/work
podman run -–privileged –-name olm-utils-play –net=host –env CMD_PREFIX=manage -v $CPDCLI_WORK:/tmp/work  icr.io/cpopen/cpd/olm-utils:latest

rm -rf ${CPDCLI_WORK}
mkdir -p ${CPDCLI_WORK}


podman run -d --privileged --name olm-utils-play --env CMD_PREFIX=manage --tls-verify=false  -v "${CPDCLI_WORK}":/tmp/work --network host hub.fbond:5000/cpopen/cpd/olm-utils:latest

### check work directory ownship again to confirm:
ls -l $CPDCLI_DIR/cpd-cli-workspace/olm-utils-workspace

# Export the namespace environment variables
```
#==========================================================
# Cloud Pak for Data installation variables
#==========================================================
# ------------------------------------------------------------------------------
# Client workstation 
# ------------------------------------------------------------------------------
# export CPD_CLI_MANAGE_WORKSPACE=<enter a fully qualified directory>
# export OLM_UTILS_LAUNCH_ARGS=<enter launch arguments>
# ------------------------------------------------------------------------------
# Cluster
# ------------------------------------------------------------------------------
#export OCP_URL=<enter your Red Hat OpenShift Container Platform URL>
export OPENSHIFT_TYPE=self-managed
export IMAGE_ARCH=amd64

export OCP_USERNAME=kubeadmin
#export OCP_PASSWORD=<enter your password>
# export OCP_TOKEN=<enter your token>
# ------------------------------------------------------------------------------
# Projects. (assume express installation)
# ------------------------------------------------------------------------------\
export PROJECT_CPFS_OPS=ibm-common-services        
export PROJECT_CPD_OPS=ibm-common-services
export PROJECT_CATSRC=openshift-marketplace
export PROJECT_CPD_INSTANCE=zen
# export PROJECT_TETHERED=<enter the tethered project>

# ------------------------------------------------------------------------------
# Storage
# ------------------------------------------------------------------------------
export STG_CLASS_BLOCK=ocs-storagecluster-ceph-rbd
export STG_CLASS_FILE=ocs-storagecluster-cephfs
# ------------------------------------------------------------------------------
# IBM Entitled Registry
# ------------------------------------------------------------------------------
#export IBM_ENTITLEMENT_KEY=<enter your IBM entitlement API key>

# ------------------------------------------------------------------------------
# Private container registry
# ------------------------------------------------------------------------------
# Set the following variables if you mirror images to a private container registry.
#
# To export these variables, you must uncomment each command in this section.

export PRIVATE_REGISTRY_LOCATION=hub.fbond:5000 

export PRIVATE_REGISTRY_PUSH_USER=ocadmin
export PRIVATE_REGISTRY_PUSH_PASSWORD=ocadmin
export PRIVATE_REGISTRY_PULL_USER=ocadmin
export PRIVATE_REGISTRY_PULL_PASSWORD=ocadmin
# ------------------------------------------------------------------------------
# Cloud Pak for Data version
# ------------------------------------------------------------------------------
export VERSION=4.6.2
# ------------------------------------------------------------------------------
# Components
# ------------------------------------------------------------------------------
# Set the following variable if you want to install or upgrade multiple components at the same time.
#
# The following complete component list is for image mirroring purpose only.
export COMPONENTS=cpfs,cpd_platform,analyticsengine,cde,dp,dv,spss,rstudio ,ws,wkc,wml,openscale
```



~If you store passwords -
chmod 700 462.sh

Every time when opening a new terminal session, source this script will receive all environment variables:

source ./462.sh


Install CPD-CLI v12.0.2
Installing Version 12.0.2 of the cpd-cli from https://github.com/IBM/cpd-cli/releases:
curl -sLkO https://github.com/IBM/cpd-cli/releases/download/v12.0.2/cpd-cli-linux-EE-12.0.2.tgz

tar xzvf cpd-cli-linux-EE-12.0.2.tgz

cd cpd-cli-linux-EE-12.0.2-39


**************************
**.         Restart on Feb 9       **
**************************

Install CPD 4.6.2:
Login to OCP, IBM registry and to private registry:
Login into OCP:
./cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}

If only token is available:
./cpd-cli manage login-to-ocp  --token=${OCP_TOKEN} --server=${OCP_URL}

./cpd-cli manage login-to-ocp --server=https://api.localcluster.fbond:6443 --token=$(oc whoami -t))) t)
Login to IBM Repository
./cpd-cli manage login-entitled-registry ${IBM_ENTITLEMENT_KEY}. --insecure-skip-tls-verify=true

Login to private registry

./cpd-cli manage login-private-registry ${PRIVATE_REGISTRY_LOCATION} ${PRIVATE_REGISTRY_PUSH_USER} ${PRIVATE_REGISTRY_PUSH_PASSWORD} 

Update the global image pull secret

cpd-cli manage add-cred-to-global-pull-secret \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PULL_USER} \
${PRIVATE_REGISTRY_PULL_PASSWORD}

Set image content source policy to pull from private registry:

./cpd-cli manage apply-icsp ${PRIVATE_REGISTRY_LOCATION}

Copy olm-utils images from IBM repo to private registry:
./cpd-cli manage copy-image --from=icr.io/cpopen/cpd/olm-utils:latest --to=${PRIVATE_REGISTRY_LOCATION}/cpd/olm-utils:latest
A.	Load olm-utils images from local dir to private registry:
cpd-cli manage load-image \
--source-image=<source-image-location-and-name> \
[--tag=<target-image-location-and-name>]

The command returns the following message when the image is loaded
Loaded image: icr.io/cpopen/cpd/olm-utils:latest
B.	copy from IBM repo to private registry
cpd-cli manage copy-image \
--from=icr.io/cpopen/cpd/olm-utils:latest \
--to=${PRIVATE_REGISTRY_LOCATION}/cpd/olm-utils:latest

Depending on network situation, select either plan A or plan B for image download:
A.	Mirror images from IBM Repo to internal registry then to private registry
Validate that you have access to the images

./cpd-cli manage list-images --components=${COMPONENTS} --release=${VERSION} --inspect_source_registry=true

cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=127.0.0.1:12443 \
--arch=${IMAGE_ARCH}

Confirm that the images were mirrored to the intermediary container registry:

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=127.0.0.1:12443 \
--case_download=false

cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--source_registry=127.0.0.1:12443 \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--arch=${IMAGE_ARCH} \
--case_download=false

Confirm that the images were mirrored to the private container registry:

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--case_download=false
B. Mirror directly from IBM Repo to Private Registry:

cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--arch=${IMAGE_ARCH}

Confirm that the images were mirrored to the private container registry:

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--case_download=false


Install operators and subscriptions
Export COMPONENTS=cpfs,cpd_platform,analyticsengine,cde,dp,dv,spss,ws,wkc,wml

./cpd-cli manage apply-olm --release=${VERSION} \
--components=${COMPONENTS} --preview=true

To preview the commands you can go to cpd-cli-workspace/olm-utils-workspace/work/preview.sh

After wml and ws operators are installed then run apply-olm for openscale.

./cpd-cli manage apply-olm --release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--components=openscale


./cpd-cli manage get-olm-artifacts --subscription_ns=${PROJECT_CPFS_OPS}


oc patch NamespaceScope ${PROJECT_CPD_INSTANCE} \
-n ${PROJECT_CPFS_OPS} \
--type=merge \
--patch='{"spec": {"csvInjector": {"enable": true} } }'

cpd-cli manage get-olm-artifacts 
--subscription_ns=${PROJECT_CPFS_OPS}

Setup Install_Options.yaml
Create a file called install-options.yml in the work directory. The file path for the IBM Cloud Pak for Data command-line interface work directory is cpd-cli-workspace/olm-utils-workspace/work.

Add the following content to the new file:
```
custom_spec:
  wkc:
    install_wkc_core_only: True
    enableKnowledgeGraph: False
    enableDataQuality: True       
    enableMANTA: False
    wkc_db2u_set_kernel_params: True
    iis_db2u_set_kernel_params: True
```
Upgrading the services
Pass 1: bedrock
./cpd-cli manage apply-cr \
--components=cpfs,cpd_platform \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true

Pass 2:  Dependent Services 
./cpd-cli manage apply-cr \
--components=analyticsengine,cde,dp,dv,spss,rstudio \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true

Pass 3: Depending Services
./cpd-cli manage apply-cr \
--components=ws,wml \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true

Openscale requires wml and ws to be installed and running first.

Pass 4: Depending Service
./cpd-cli manage apply-cr \
--components=openscale,wkc \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true \
--param-file=/tmp/work/install-options.yml


Verify installation status
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE}


Get url and details of CP4D Web Client /Control Plane
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=environment-changing-admin-user-password

./cpd-cli manage get-cpd-instance-details --cpd_instance_ns=${PROJECT_CPD_INSTANCE} --get_admin_initial_credentials=true

To change the default admin user password:

Enter the URL in a web browser and log in to the web client as the admin user with the default password. 
Change the password: 
a.	Click your avatar in the toolbar.
b.	Click Profile and settings.
c.	Open the Password tab.
d.	Enter the default password in the Current password field.
e.	Enter and confirm the new password.
f.	Click Save.
Supported browsers: Edge, Crome and Firefox.

Post-Installation:
Create custom security context constraint  (SCC) for WKC service

./cpd-cli manage apply-scc --cpd_instance_ns=${PROJECT_CPD_INSTANCE} 
--components=wkc

DB2, DB2 Warehouse SCC are created automatically when installed.


OCP Upgrade
4.8.37 -> 4.9.54 -> 4.10.47

There are two options to perform OCP upgrade: the command line upgrade instructions are provided below.  There’s an easier OCP upgrade through OpenShift Console.  Select your channel to be eus-4.10 and few clicks to go from current 4.8.37 to 4.9.54 to 4.10.47.
 

oc patch clusterversion version --type merge -p '{"spec": {"channel": "eus-4.10"}}'

curl -H "Accept: application/json" https://api.openshift.com/api/upgrades_info/v1/graph?channel=eus-4.10&arch=amd64 | jq '.'

$ export CURRENT_VERSION=4.8.37;
$ export CHANNEL_NAME=eus-4.10;
$
$ curl -sH 'Accept:application/json' "https://api.openshift.com/api/upgrades_info/v1/graph?channel=${CHANNEL_NAME}" | jq -r --arg CURRENT_VERSION "${CURRENT_VERSION}" '. as $graph | $graph.nodes | map(.version=='\"$CURRENT_VERSION\"') | index(true) as $orig | $graph.edges | map(select(.[0] == $orig)[1]) | map($graph.nodes[.].version) | sort_by(.)'
[
  "4.8.37",
  "4.9.54"
]


$ curl -sH 'Accept:application/json' "https://api.openshift.com/api/upgrades_info/v1/graph?channel=${CHANNEL_NAME}" | jq -r --arg CURRENT_VERSION "${CURRENT_VERSION}" '. as $graph | $graph.nodes | map(.version=='\"$CURRENT_VERSION\"') | index(true) as $orig | $graph.edges | map(select(.[0] == $orig)[1]) | map($graph.nodes[.].version) | sort_by(.)'
[
  "4.9.54",
  “4.10.47”
]


OCS Upgrade
CP4D Upgrade SWAT Team does not do storage upgrade.  
Since OCP and OCS are bundled together with CPDS, they need to be upgraded together too on CPDS 2.0.2.x.
Here is a wiki document in public domain:
https://github.ibm.com/privatecloud-ap/cpds-nodeos/wiki/OCP-OCS-Upgrade-in-a--connected-environment-using-Openshift-Console-UI




Post installation tasks to be performed by Administrators

Analytics Engine Power by Spark:
Project Admin needs to perform the following post installation tasks:
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=spark-post-installation-setup

Watson Knowledge Catalog:
Project Admin needs to perform the following post installation mandatory and optional tasks:
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=catalog-post-installation-setup

Settting up the default catalog:
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=setup-setting-up-your-default-catalog

Watson Query ( formally Data Virtualization, DV)
Project Admin needs to perform the following post installation tasks, including hardware resource configuration of the service to be provisioned:
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=query-post-installation-setup

Watson Studio:

Project Admin and System Admin need to perform the following post installation tasks:
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=ws-post-installation-setup


Watson Studio Runtime:

Runtime 22.2 with Python 3.10
This runtime is installed by default with the Watson Studio service in Cloud Pak for Data 4.6. It provides compute environments for data scientists to run JupyterLab and Jupyter notebooks in the Python 3.10 coding language in Watson Studio analytics projects.
Runtime 22.1 with Python 3.9
This runtime provides compute environments for data scientists to run JupyterLab and Jupyter notebooks in the Python 3.9 coding language in Watson Studio analytics projects.
Runtime 22.2 with Python 3.10 with GPU
If you have GPU nodes in your cluster, data scientists can use this runtime to run Python 3.10 notebooks and experiments that train compute-intensive machine learning models in Watson Studio analytics projects.
Runtime 22.1 with Python 3.9 with GPU
If you have GPU nodes in your cluster, data scientists can use this runtime to run Python 3.9 notebooks and experiments that train compute-intensive machine learning models in Watson Studio analytics projects.
Runtime 22.2 on R 4.2
This runtime provides compute environments for data scientists to run Jupyter notebooks in the R 4.2 coding language in Watson Studio analytics projects.
Runtime 22.1 with R 3.6
This runtime provides compute environments for data scientists to run Jupyter notebooks in the R 3.6 coding language in Watson Studio analytics projects.


https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=services-watson-studio-runtimes
