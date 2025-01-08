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
