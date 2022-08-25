# Download and Install OADP Operator - Airgapped

## Download Processing on Jump Server

----------
### Install podman skopeo httpd-tools 
```
sudo su -

yum check-update
yum install -y skopeo httpd-tools podman jq  

exit
```

### Prepare Environment
Create download directories
```
mkdir /data/oadp
cd /data/oadp
```

Create env-vars-oadp file and update with your Red Hat Entitlement Credentials   
```
# Environment Variables
# make them availabe by running the following command from the command line
# source ./env-vars-oadp

#===============================================================================
# Red Hat Registry variables
#===============================================================================
# Download Server working directory
export HOMEDIR=/data/oadp 

# ------------------------------------------------------------------------------
# RED HAT Entitled Registry variables - MUST FILL IN WITH CLIENT'S RED HAT CREDENTIALS
# ------------------------------------------------------------------------------
export RH_ENTITLEMENT_USER=<redhat-userid>
export RH_ENTITLEMENT_PASSWORD=<redhat-user-password>
export RH_ENTITLEMENT_SERVER=registry.redhat.io


# ------------------------------------------------------------------------------
# Intermediary container registry variables
# ------------------------------------------------------------------------------
# Set the following variables if you use an intermediary container registry to
# mirror images to your private container registry.

export INTERMEDIARY_REGISTRY_HOST=localhost
export INTERMEDIARY_REGISTRY_PORT=15000
INTERMEDIARY_REGISTRY_LOCATION="${INTERMEDIARY_REGISTRY_HOST}:${INTERMEDIARY_REGISTRY_PORT}"
export INTERMEDIARY_REGISTRY_LOCATION
export INTERMEDIARY_REGISTRY_USER=admin
export INTERMEDIARY_REGISTRY_PASSWORD=password

# Required when using self signed certificates with a CN (temp registry))
export GODEBUG=x509ignoreCN=0 # needed if one is using self signed certificates with a CN
```
Instantiate the environment variables
```
source ./env-vars-oadp 
```

### Download files
Create download directory for files-4-transfer
```
mkdir -p $HOMEDIR/files-4-transfer
cd $HOMEDIR/files-4-transfer
```
#### Tool files
The following files will be required for either the download or install of the OADP Operator

**Note -- This focuses on OpenShift Container Storage v4.6. If you have a different version of OCS then you should update accordingly**   

```
# Updated OpenShift CLI for 4.6
wget -c https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.6.59/openshift-client-linux.tar.gz

# Red Hat opm tool for 4.6 to pare down the registry index for mirroring
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.6.59/opm-linux-4.6.59.tar.gz

# grpcurl command used to locate the operator package name
wget https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz

```

#### Download of Velero-plugin and the UBI-minimal
Download steps
```
CPU_ARCH=`uname -m`
echo $CPU_ARCH
BUILD_NUM=1
echo $BUILD_NUM

podman login ${RH_ENTITLEMENT_SERVER} -u ${RH_ENTITLEMENT_USER} -p "${RH_ENTITLEMENT_PASSWORD}"

podman pull docker.io/ibmcom/cpdbr-velero-plugin:4.0.0-beta1-${BUILD_NUM}-${CPU_ARCH}
podman save docker.io/ibmcom/cpdbr-velero-plugin:4.0.0-beta1-${BUILD_NUM}-${CPU_ARCH} > cpdbr-velero-plugin-img-4.0.0-beta1-${BUILD_NUM}-${CPU_ARCH}.tar

podman pull registry.redhat.io/ubi8/ubi-minimal:latest
podman save registry.redhat.io/ubi8/ubi-minimal:latest > ubi-minimal-img-latest.tar
```

### Create temp registry for download of OADP
Create the needed directories for the temp registry
```
mkdir -p registry/{auth,certs,data,images}

cd registry/certs
```
Create self signed certificates and password for registry
```
openssl req -newkey rsa:4096 -nodes -sha256 -keyout oadp-registry.key -x509 -days 365 -out oadp-registry.crt -subj "/C=US/ST=/L=/O=/CN=${INTERMEDIARY_REGISTRY_HOST}" 

cd $HOMEDIR

htpasswd -bBc ${HOMEDIR}/registry/auth/htpasswd admin password
```
Creates the temp registry
```
podman pull docker.io/library/registry:2

podman save -o ${HOMEDIR}/registry/images/registry-2.tar docker.io/library/registry:2

podman run --name oadp-registry --publish 15000:5000 \
     --detach \
     --volume ${HOMEDIR}/registry/data:/var/lib/registry:z \
     --volume ${HOMEDIR}/registry/auth:/auth:z \
     --volume ${HOMEDIR}/registry/certs:/certs:z \
     --env "REGISTRY_AUTH=htpasswd" \
     --env "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
     --env REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
     --env REGISTRY_HTTP_TLS_CERTIFICATE=/certs/oadp-registry.crt \
     --env REGISTRY_HTTP_TLS_KEY=/certs/oadp-registry.key \
     docker.io/library/registry:2
```

### OADP download process
#### Login to registries (intermediate and Red Hat)
```
podman login ${INTERMEDIARY_REGISTRY_LOCATION} -u ${INTERMEDIARY_REGISTRY_USER} -p ${INTERMEDIARY_REGISTRY_PASSWORD} --tls-verify=false
podman login ${RH_ENTITLEMENT_SERVER} -u ${RH_ENTITLEMENT_USER} -p "${RH_ENTITLEMENT_PASSWORD}"
```

#### Get the OADP Operator catalog name
Run the container for the red hat operator index
```
podman run -p50051:50051 -it registry.redhat.io/redhat/redhat-operator-index:v4.6
```

#### Open a second command line on the jump server to get package name

Get the name of the operator for download 
```
cd /data/oadp

grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out

cat packages.out | grep oadp

# returned --> redhat-oadp-operator

exit
```

#### Prepare Index for Mirror of OADP 4.6 Operator

**Note -- This focuses on OpenShift Container Storage v4.6. If you have a different version of OCS then you should update accordingly**  

Back to original jump server command line window
```
cd $HOMEDIR
```
Unpack the red hat opm tool to pare down the catalog index
```
tar xvf $HOMEDIR/files-4-transfer/opm-linux-4.6.59.tar.gz
```
Pare the catalog index and push it to the temp registry (oadp vs oadp-operator)
```
./opm index prune -f registry.redhat.io/redhat/redhat-operator-index:v4.6 -p redhat-oadp-operator -t ${INTERMEDIARY_REGISTRY_LOCATION}/oadp/redhat-operator-index:v4.6

podman push ${INTERMEDIARY_REGISTRY_LOCATION}/oadp/redhat-operator-index:v4.6 --tls-verify=false
```
#### Mirror the OADP Operator for OCP 4.6
Get the credentials for the red hat mirror
```
REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json
```
Create the directory for the mirrored files
```
mkdir ${HOMEDIR}/files
cd ${HOMEDIR}/files
```
Mirror the files down (oadp vs oadp-operator)
```
oc adm catalog mirror ${INTERMEDIARY_REGISTRY_LOCATION}/oadp/redhat-operator-index:v4.6 file:///local/index -a ${REG_CREDS} --insecure
```
Finished with
```
wrote mirroring manifests to manifests-redhat-operator-index-1660567863

To upload local images to a registry, run:

	oc adm catalog mirror file://local/index/oadp/redhat-operator-index:v4.6 REGISTRY/REPOSITORY
```
#### Pack (tar) the operator files to transfer to CPDS
The v2 directory which was created by the mirror command contains the operator
```
tar -czvf oadp-operator.tgz v2

# copy to transfer directory
mv /data/oadp/oadp-operator.tgz /data/oadp/files-to-transfer/.
```

### Transfer files to Target System


## Install the operator on the target cluster
## Prepare Environment
Create env-vars-oadp file and update with your Red Hat Entitlement Credentials   
```
# Environment Variables
# make them availabe by running the following command from the command line
#  source ./env-vars-oadp

#===============================================================================
# Red Hat Registry variables
#===============================================================================

# Download Server
export HOMEDIR=<working_directory>  # This is your working directory


# ------------------------------------------------------------------------------
# Set the following variables if you mirror images to a private container registry.
#

export PRIVATE_REGISTRY_SERVER=<registry_server>
export PRIVATE_REGISTRY_SERVER_PORT=<registry_port>
export PRIVATE_REGISTRY_LOCATION=$PRIVATE_REGISTRY_SERVER:$PRIVATE_REGISTRY_SERVER_PORT
export PRIVATE_REGISTRY_PUSH_USER=<registry_push_id>
export PRIVATE_REGISTRY_PUSH_PASSWORD=<registry_push_pw>
export PRIVATE_REGISTRY_PULL_USER=<registry_pull_id>
export PRIVATE_REGISTRY_PULL_PASSWORD=<registry_pull_pw>


# if using self signed certificates with a CN then the following is required
export GODEBUG=x509ignoreCN=0  # needed if one is using self signed certificates with a CN
```
Initialize the environment variables
```
source ./env-vars-oadp
```
### Mirror the OADP package to the registry (Option B from the Red Hat instructions)
https://docs.openshift.com/container-platform/4.6/operators/admin/olm-restricted-networks.html#olm-mirror-catalog_olm-restricted-networks  

**Set the required red hat creds**
```
REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json
```

Change to the directory with the download files
```
cd ${HOMEDIR}/
```
Run the red hat mirror command to push the images to the private registry
**Note -- This focuses on OpenShift Container Storage v4.6. If you have a different version of OCS then you should update accordingly**  
```
oc adm catalog mirror file://local/index/oadp/redhat-operator-index:v4.6 ${PRIVATE_REGISTRY_LOCATION}/oadp  -a ${REG_CREDS} --insecure
```
### Create Image Content Source Policy
The oc adm catalog mirror command generates an imageContentSourcePolicy.yaml file. That file is needed for directing OpenShift ro the images for OADP.This will be used to create the ImageContentSourcePolicy

Get the name of the redhat-operator-index directory
```
ls manifests-index/oadp/ 
```
Use cat to look at the generated ImageContentSourcePolicy yaml file
```
cat manifests-index/oadp/redhat-operator-index-xxxxxx/imageContentSourcePolicy.yaml
```
returns something similar to this (EXAMPLE) 
This must be updated by changing all references of `local/index` to `registry.redhat.io` 
```
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: index-oadp-operator-redhat-operator-index
spec:
  repositoryDigestMirrors:
  - mirrors:
    - <server>:<port>/oadp-operator/oadp-oadp-velero-plugin-for-csi-rhel8
    source: local/index/oadp-operator/redhat-operator-index/oadp/oadp-velero-plugin-for-csi-rhel8
  - mirrors:
    - <server>:<port>/oadp-operator/oadp-oadp-velero-plugin-for-aws-rhel8
    source: local/index/oadp-operator/redhat-operator-index/oadp/oadp-velero-plugin-for-aws-rhel8
  - mirrors:
  ...
```
The changed file will look like this (added commands to save as a new yaml file)

```
:q!
```
Apply this file. This will be a machine configuration change so it will take a while to complete.
```
oc apply -f $HOMEDIR/yaml/oadp-imageContentSourcePolicy.yaml

watch "oc get mcp ; echo ; echo; oc get nodes"
```


### Create the CatalogSource
The oc adm catalog mirror command generates a catalogsource.yaml file. In that file you can find the location for the 
OADP image. You will need to copy that line out of the generated catalogsource.yaml file to use when you create
the cataloag source for the air-gapped OADP operator.
```
# Get the name of the redhat-operator-index directory
ls manifests-index/oadp-operator/ 

# do a cat using the redhat-operator-index directory
cat manifests-index/oadp-operator/redhat-operator-index-xxxxxx/catalogSource.yaml 
```
returns something similar to this (EXAMPLE) You will need to copy the line `image: xxxx`
```
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: index/oadp-operator/redhat-operator-index
  namespace: openshift-marketplace
spec:
  image: ${$PRIVATE_REGISTRY_SERVER:$PRIVATE_REGISTRY_SERVER_PORT}/oadp/local-index-oadp-operator-redhat-operator-index:v4.6
  sourceType: grpc

```
Replace the `image: ` line with the one just copied above 
```
cat << EOF > $HOMEDIR/yaml/oadp-catsrc.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: oadp-operator-catalog
  namespace: openshift-marketplace 
spec:
  sourceType: grpc
  image: ${$PRIVATE_REGISTRY_SERVER:$PRIVATE_REGISTRY_SERVER_PORT}/oadp/local-index-oadp-redhat-operator-index:v4.6 
  displayName: OADP Operator Catalog
  publisher: 'Red Hat' 
  updateStrategy:
    registryPoll: 
      interval: 30m
EOF
```

Apply the create catsrc
```
oc apply -f $HOMEDIR/yaml/oadp-catsrc.yaml
```
Verify the CatalogSource completes
```
oc get catalogsource -n openshift-marketplace | grep oadp

oc get pods -n openshift-marketplace | grep oadp-operator-catalog

oc get packagemanifest -n openshift-marketplace | grep oadp
```

### Create the Operator Group for oadp-operator namespace
Create OperatorGroup
```
cat <<EOF  > $HOMEDIR/yaml/oadp-operatorgroup.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: oadp-operatorgroup
  namespace: oadp-operator
spec:
  targetNamespaces:
  - oadp-operator
EOF
```
Apply
```
oc apply -f $HOMEDIR/yaml/oadp-operatorgroup.yaml
```
### Create the subscription

Create the subscription for the operator
```
cat << EOF > $HOMEDIR/yaml/oadp-subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/redhat-oadp-operator.openshift-adp: ""
  name: redhat-oadp-operator
  namespace: oadp-operator
spec:
  channel: stable-1.0
  installPlanApproval: Automatic
  name: redhat-oadp-operator
  source: oadp-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: oadp-operator.v1.0.3
EOF
```
Apply the sub
```
oc apply -f $HOMEDIR/yaml/oadp-subscription.yaml
```
Check Subscription triggered: Returns oadp-operator.v1.0.3
```
oc get sub -n oadp-operator redhat-oadp-operator -o jsonpath='{.status.installedCSV} {"\n"}'
```
Check the CSV is ready: Returns Succeeded : install strategy completed with no errors
```
oc get csv -n oadp-operator oadp-operator.v1.0.3 -o jsonpath='{ .status.phase } : { .status.message} {"\n"}'
```
Check deployment that operator is ready:   Returns  1
```
oc get deployments -n oadp-operator -l olm.owner="oadp-operator.v1.0.3" -o jsonpath="{.items[0].status.availableReplicas} {'\n'}"
```
