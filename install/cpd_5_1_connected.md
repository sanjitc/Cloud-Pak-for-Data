# CPD 5.1 Installation Testing

## Assumption
Environment base (internet connected)
- OCP 4.14
- ODF 4.14

Services to be installed
- Control plane 
- WKC

## Installing the IBM Software Hub command-line interface

Install tools:
```
yum install openssl httpd-tools podman skopeo wget tmux -y
```

Create a directory for the cpd-cli utility.
```
export CPD_WORKSPACE=/root/cpd510
mkdir -p ${CPD_WORKSPACE}
cd ${CPD_WORKSPACE}
```

Download the IBM Software Hub command-line interface 5.1.0.
```
wget http://icpfs1.svl.ibm.com/zen/cp4d-builds/cpd-cli/14.1.0/latest/cpd-cli-linux-EE-14.1.0.tgz
tar xvf cpd-cli-linux-EE-14.1.0.tgz

# Check the "cpd-cli-linux-EE*" directory get created the above tar extraction. It may be different in your case.
export PATH=${CPD_WORKSPACE}/cpd-cli-linux-EE-14.1.0-1291:$PATH
```

Update the CPD_CLI_MANAGE_WORKSPACE variable
```
export CPD_CLI_MANAGE_WORKSPACE=/root/cpd510
export OLM_UTILS_LAUNCH_ARGS="--network host"
```

Check out with this commands
```
cpd-cli version
---------------
cpd-cli
        Version: 14.1.0
        Build Date: 2024-11-20T16:13:40
        Build Number: 1106
        CPD Release Version: 5.1.0
```

Set up cpd-cli
```
# Get the entitlement key for cp.stg.icr.io
#https://wwwpoc.ibm.com/myibm/products-services/containerlibrary

# Get the entitlement key for icr.io
https://myibm.ibm.com/products-services/containerlibrary

podman login -u cp -p <entitlement key>

# define olm-utils image for 5.1.x
#export OLM_UTILS_IMAGE=cp.stg.icr.io/cp/cpd/olm-utils-v3:5.1.0
export OLM_UTILS_IMAGE=icr.io/cpopen/cpd/olm-utils-v3:5.1.0

podman rm olm-utils-play-v3 --force ## stop and delete running olm-utils container if any

podman rmi $OLM_UTILS_IMAGE  ## remove existing olm-utils image if any

cpd-cli manage restart-container

cpd-cli manage login-to-ocp --server=https://<your apiserver>:6443 -u <cluster admin> -p <cluster admin user's password>
```

## Creating an environment variables file 

Create an environment variables file cpd_vars.sh
```
#===============================================================================
# Cloud Pak for Data installation variables
#===============================================================================

# ------------------------------------------------------------------------------
# Client workstation 
# ------------------------------------------------------------------------------
# Set the following variables if you want to override the default behavior of the Cloud Pak for Data CLI.
#
# To export these variables, you must uncomment each command in this section.

export CPD_CLI_MANAGE_WORKSPACE=/root/cpd510
# export OLM_UTILS_LAUNCH_ARGS=<enter launch arguments>


# ------------------------------------------------------------------------------
# Cluster
# ------------------------------------------------------------------------------

export OCP_URL=https://api.673e6c440fef21364200defe.ocp.techzone.ibm.com:6443
export OPENSHIFT_TYPE=self-managed
export IMAGE_ARCH=amd64
export OCP_USERNAME=kubeadmin
export OCP_PASSWORD=<enter your password>
# export OCP_TOKEN=<sha256~.....>
export SERVER_ARGUMENTS="--server=${OCP_URL}"
# export LOGIN_ARGUMENTS="--username=${OCP_USERNAME} --password=${OCP_PASSWORD}"
export LOGIN_ARGUMENTS="--token=${OCP_TOKEN}"
export CPDM_OC_LOGIN="cpd-cli manage login-to-ocp ${SERVER_ARGUMENTS} ${LOGIN_ARGUMENTS}"
export OC_LOGIN="oc login ${OCP_URL} ${LOGIN_ARGUMENTS}"


# ------------------------------------------------------------------------------
# Projects
# ------------------------------------------------------------------------------

export PROJECT_CERT_MANAGER=ibm-cert-manager
export PROJECT_LICENSE_SERVICE=ibm-licensing
export PROJECT_SCHEDULING_SERVICE=ibm-cpd-scheduler
#export PROJECT_IBM_EVENTS=<enter your IBM Events Operator project>
# export PROJECT_PRIVILEGED_MONITORING_SERVICE=<enter your privileged monitoring service project>
export PROJECT_CPD_INST_OPERATORS=cpd-operators
export PROJECT_CPD_INST_OPERANDS=cpd-instance
# export PROJECT_CPD_INSTANCE_TETHERED=<enter your tethered project>
# export PROJECT_CPD_INSTANCE_TETHERED_LIST=<a comma-separated list of tethered projects>



# ------------------------------------------------------------------------------
# Storage
# ------------------------------------------------------------------------------

export STG_CLASS_BLOCK=ocs-storagecluster-ceph-rbd
export STG_CLASS_FILE=ocs-storagecluster-cephfs

# ------------------------------------------------------------------------------
# IBM Entitled Registry
# ------------------------------------------------------------------------------

export IBM_ENTITLEMENT_KEY=<enter IBM entitlement key>


# ------------------------------------------------------------------------------
# Private container registry
# ------------------------------------------------------------------------------
# Set the following variables if you mirror images to a private container registry.
#
# To export these variables, you must uncomment each command in this section.

# export PRIVATE_REGISTRY_LOCATION=<enter the location of your private container registry>
# export PRIVATE_REGISTRY_PUSH_USER=<enter the username of a user that can push to the registry>
# export PRIVATE_REGISTRY_PUSH_PASSWORD=<enter the password of the user that can push to the registry>
# export PRIVATE_REGISTRY_PULL_USER=<enter the username of a user that can pull from the registry>
# export PRIVATE_REGISTRY_PULL_PASSWORD=<enter the password of the user that can pull from the registry>


# ------------------------------------------------------------------------------
# Cloud Pak for Data version
# ------------------------------------------------------------------------------

export VERSION=5.1.0


# ------------------------------------------------------------------------------
# Components
# ------------------------------------------------------------------------------

export COMPONENTS=ibm-licensing,scheduler,cpfs,cpd_platform
# export COMPONENTS_TO_SKIP=<component-ID-1>,<component-ID-2>
```

Confirm that the script does not contain any errors. For example, if you named the script cpd_vars.sh, run:
```
bash ./cpd_vars.sh
```

Run this command to apply cpd_vars_485.sh
```
source cpd_vars.sh
```

## Set up for Non-GA test
```
directory=$CPD_CLI_MANAGE_WORKSPACE/work
GITHUB_USER=<github userid>
GITHUB_TOKEN=
STG_USER=cp
ENTITLEMENT_KEY=

cat <<EOF > $directory/resolvers_auth.yaml
resolversAuth:
  resources:
    cases:
      repositories:
        DevGitHub:
          credentials:
            basic:
              username: ${GITHUB_USER}
              password: ${GITHUB_TOKEN}
        cloudPakCertRepo:
          credentials:
            basic:
              username: ${GITHUB_USER}
              password: ${GITHUB_TOKEN}
        customZenRepo:
          credentials:
            basic:
              username: ${GITHUB_USER}
              password: ${GITHUB_TOKEN}
    containerImages:
      registries:
        entitledStage:
          credentials:
            basic:
              username: ${STG_USER}
              password: ${ENTITLEMENT_KEY}
EOF

version=5.1.0
path=dev

cat <<EOF > $directory/resolvers.yaml
resolvers:
  resources:
    cases:
      repositories:
        DevGitHub:
          repositoryInfo:
            url: "https://raw.github.ibm.com/PrivateCloud-analytics/cpd-case-repo/$version/$path/case-repo-$path"
        cloudPakCertRepo:
          repositoryInfo:
            url: "https://raw.github.ibm.com/IBMPrivateCloud/cloud-pak/master/repo/case"
      caseRepositoryMap:
      - cases:
        - case: "ibm-ccs"
          version: "*"
        - case: "ibm-datarefinery"
          version: "*"
        - case: "ibm-wsl-runtimes"
          version: "*"
        - case: "ibm-db2uoperator"
          version: "*"
        - case: "ibm-iis"
          version: "*"
        - case: "ibm-db2aaservice"
          version: "*"
        - case: "ibm-wsl"
          version: "*"
        - case: "*"
          version: "*"
        repositories:
        - DevGitHub
      - cases:
        - case: "*"
          version: "*"
        repositories:
        - cloudPakCertRepo

EOF

cat <<EOF > $directory/play_env.sh
export CASECTL_RESOLVERS_LOCATION=/tmp/work/resolvers.yaml
export CASECTL_RESOLVERS_AUTH_LOCATION=/tmp/work/resolvers_auth.yaml
export CASE_TOLERATION='--skip-verify'
export GITHUB_TOKEN=${GITHUB_TOKEN}

export CASE_REPO_PATH=https://\$GITHUB_TOKEN@raw.github.ibm.com/PrivateCloud-analytics/cpd-case-repo/$version/$path/case-repo-$path

## pick up the in-development Bedrock from staging instead of prod
export CPFS_CASE_REPO_PATH=https://\$GITHUB_TOKEN@raw.github.ibm.com/IBMPrivateCloud/cloud-pak/master/repo/case

## pick up yet-to-be released opencontent cases from staging instead of prod
export OPENCONTENT_CASE_REPO_PATH=https://\$GITHUB_TOKEN@raw.github.ibm.com/IBMPrivateCloud/cloud-pak/master/repo/case

EOF
```

Validate if downloading the CASE files working:
```
cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION}
```

## CPD deployment
Updating the global image pull secret
Log the cpd-cli in to the Red Hat® OpenShift® Container Platform cluster: 
```
${CPDM_OC_LOGIN}
```

Update the global image pull secret
```
# 1. Get the current pull secret and save to file /tmp/dockerconfig.json
oc get secret/pull-secret -n openshift-config -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d > /tmp/dockerconfig.json

# 2. For updating every registry, you need to run the below steps once
# You need to include the secret for all of the below registries
# - cp.stg.icr.io


## 2a. Set up the variables
registry=cp.stg.icr.io
username=cp
password=<entitlement key for accessing staging image registry>

#You can get the entitlement key with below link
#https://wwwpoc.ibm.com/myibm/products-services/containerlibrary

pull_secret=$(echo -n "$username:$password" | base64 -w 0)

## 2b. Update the file using jq
jq --argjson obj '{"auth": "'$pull_secret'"}' '.auths += {"'$registry'": $obj}' /tmp/dockerconfig.json > /tmp/temp.json && mv /tmp/temp.json /tmp/dockerconfig.json -f

# 3. Apply the global pull secret
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=/tmp/dockerconfig.json
```

Get the status of the nodes. 
```
cpd-cli manage oc get nodes
```

Wait until all the nodes are Ready before you proceed to the next step. For example, if you see Ready,SchedulingDisabled, wait for the process to complete.

Set up ImageDigestMirrorSet and ImageTagMirrorSet
```
oc apply -f - << EOF
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
  name: cpd-icsp
spec:  
  imageDigestMirrors:
  - mirrors:
      - docker-na.artifactory.swg-devops.com/hyc-cp4d-team-bootstrap-docker-local
      - docker-na.artifactory.swg-devops.com/hyc-cp4d-team-bootstrap-2-docker-local  
      - docker-na-public.artifactory.swg-devops.com/hyc-cloud-private-daily-docker-local/ibmcom
      - cp.stg.icr.io/cp
      - cp.stg.icr.io/cp/cpd
    source: icr.io/cpopen
  - mirrors:
      - docker-na-public.artifactory.swg-devops.com/hyc-cloud-private-daily-docker-local/ibmcom
      - cp.stg.icr.io/cp
      - cp.stg.icr.io/cp/cpd
    source: icr.io/cpopen/cpfs
  - mirrors:
      - cp.stg.icr.io/cp
      - cp.stg.icr.io/cp/cpd
    source: cp.icr.io/cp/cpd

---

apiVersion: config.openshift.io/v1
kind: ImageTagMirrorSet
metadata:
  name: cpd-icsp
spec:  
  imageTagMirrors:
  - mirrors:
      - docker-na.artifactory.swg-devops.com/hyc-cp4d-team-bootstrap-docker-local
      - docker-na.artifactory.swg-devops.com/hyc-cp4d-team-bootstrap-2-docker-local  
      - docker-na-public.artifactory.swg-devops.com/hyc-cloud-private-daily-docker-local/ibmcom
      - cp.stg.icr.io/cp
      - cp.stg.icr.io/cp/cpd
    source: icr.io/cpopen
  - mirrors:
      - docker-na-public.artifactory.swg-devops.com/hyc-cloud-private-daily-docker-local/ibmcom
      - cp.stg.icr.io/cp
      - cp.stg.icr.io/cp/cpd
    source: icr.io/cpopen/cpfs
  - mirrors:
      - cp.stg.icr.io/cp
      - cp.stg.icr.io/cp/cpd
    source: cp.icr.io/cp/cpd

EOF
```

Changing required node settings

Changing load balancer timeout settings

https://ibmdocs-test.dcs.ibm.com/docs/en/SSNFH6_5.1_test?topic=settings-changing-load-balancer

Changing the process IDs limit

Run the following command to create the KubeletConfig that defines the podPidsLimit: 
```
oc apply -f - << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: cpd-pidslimit-kubeletconfig
spec:
  kubeletConfig:
    podPidsLimit: 16384
  machineConfigPoolSelector:
    matchExpressions:
    - key: pools.operator.machineconfiguration.openshift.io/worker
      operator: Exists
EOF
```

Manually creating projects (namespaces) for the shared cluster components
```
oc new-project ${PROJECT_LICENSE_SERVICE}
oc new-project ${PROJECT_SCHEDULING_SERVICE}
```

Installing shared cluster components

Install the License Service:
```
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--cert_manager_ns=${PROJECT_CERT_MANAGER} \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```

Wait for the cpd-cli to return the following message before proceeding to the next step:
```
[SUCCESS]... The apply-cluster-components command ran successfully.
```

Install the Scheduler Service:
```
cpd-cli manage apply-scheduler \
--release=${VERSION} \
--license_acceptance=true \
--scheduler_ns=${PROJECT_SCHEDULING_SERVICE}
```

Manually creating projects (namespaces) for CPD instance 

Log in to Red Hat® OpenShift® Container Platform as a cluster administrator. 
```
${OC_LOGIN}
```

Create the operators project for the instance: 
```
oc new-project ${PROJECT_CPD_INST_OPERATORS}
```

Create the operands project for the instance:
```
oc new-project ${PROJECT_CPD_INST_OPERANDS}
```

Applying the required permissions to the projects (namespaces) for CPD instance

Log the cpd-cli in to the Red Hat® OpenShift® Container Platform cluster: 
```
${CPDM_OC_LOGIN}
```

Run the cpd-cli manage authorize-instance-topology to apply the required permissions to the projects.
```
cpd-cli manage authorize-instance-topology \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

## Installing IBM Software Hub
