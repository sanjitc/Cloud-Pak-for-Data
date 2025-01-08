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
export PATH=${CPD_WORKSPACE}/cpd-cli-linux-EE-14.1.0-1106:$PATH
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
#Get the entitlement key for cp.stg.icr.io
#https://wwwpoc.ibm.com/myibm/products-services/containerlibrary

podman login -u cp -p <entitlement key>

# define olm-utils image for 5.1.x
export OLM_UTILS_IMAGE=cp.stg.icr.io/cp/cpd/olm-utils-v3:5.1.0

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
