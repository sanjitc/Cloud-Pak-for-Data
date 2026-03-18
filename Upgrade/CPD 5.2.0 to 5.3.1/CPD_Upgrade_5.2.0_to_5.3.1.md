
# CPD Upgrade From 5.2.0 to 5.3.1

## Upgrade Context
- **OCP:** 4.16
- **CPD:** 5.2.0 → 5.3.1
- **Storage:** NFS
- **Components:** ibm-licensing, cpfs, cpd_platform, wkc, datastage_ent, analyticsengine, datalineage, ikc_standard, ikc_premium, semantic_automation
- **Airgapped:** Yes

# Table of Contents
- 1. Pre-upgrade
- 2. Upgrade
- 3. Post-upgrade tasks

# 1. Pre-upgrade
## 1.1 Checking the health of your cluster
```
cpd-cli health cluster
cpd-cli health nodes
cpd-cli health operators --operator_ns=${PROJECT_CPD_INST_OPERATORS} --control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
cpd-cli health operands --control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

## 1.2 Health check OCP & CPD
```
${OC_LOGIN}
oc get nodes,co,mcp

${CPDM_OC_LOGIN}
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[digit:]])/\1.*R' | grep -v 'Completed'
```

## 1.3 Backup before upgrade
> [!Note]
> Create a folder for 5.2.0 and maintain below created copies in that folder.

Login to the OCP cluster for cpd-cli utility.
```
cpd-cli manage login-to-ocp --username=${OCP_USERNAME} --password=${OCP_PASSWORD} --server=${OCP_URL}
```
### 1.3.1 Capture data for the CPD 5.2.0 instance. 
No sensitive information is collected. Only the operational state of the Kubernetes artifacts is collected. The output of the command is stored in a file named collect-state.tar.gz in the cpd-cli-workspace/olm-utils-workspace/work directory.
```
cpd-cli manage collect-state --cpd_instance_ns=${PROJECT_CPD_INSTANCE}
```
### 1.3.2 Make a copy of existing custom resources (Recommended)
```
oc project ${PROJECT_CPD_INSTANCE}

oc get ibmcpd ibmcpd-cr -o yaml > ibmcpd-cr.yaml

oc get zenservice lite-cr -o yaml > lite-cr.yaml

oc get CCS ccs-cr -o yaml > ccs-cr.yaml

oc get wkc wkc-cr -o yaml > wkc-cr.yaml

oc get analyticsengine analyticsengine-sample -o yaml > analyticsengine-cr.yaml

oc get DataStage datastage -o yaml > datastage-cr.yaml

oc get datalineage -o yaml > datalineage-cr.yaml

oc get watsonxai -o yaml > watsonxai-cr.yaml

oc get watsonxaiifm -o yaml > watsonxaiifm-cr.yaml
```

### 1.3.3 Backup the routes.
```
oc get routes -o yaml > routes.yaml
```
> [!CAUTION]
> Default CPD route must be "reencrypt" and not a "passthrough" termination.

### 1.3.4 Backup the RSI patches.
```
cpd-cli manage get-rsi-patch-info \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--all
```

## 1.4 Update the cpd-cli utility
```
wget https://github.com/IBM/cpd-cli/releases/download/v14.3.1/cpd-cli-linux-EE-14.3.1.tgz
tar -xvf cpd-cli-linux-EE-14.3.1.tgz
```
Ensure the cpd-cli manage plug-in has the latest olm-utils image.
Check and confirm the olm-utils-v4 container is up and running.
```
cpd-cli manage restart-container
podman ps | grep olm-utils-v4
```

## 1.5 Install Helm CLI
Install Helm by following the https://www.ibm.com/links?url=https%3A%2F%2Fhelm.sh%2Fdocs%2Fintro%2Finstall%2F

```
sudo dnf install helm
```

## 1.6 Updating your environment variables script
Make a copy of the environment variables script used by the existing 5.2.0 variables with the name like cpd_vars_531.sh.

Update the environment variables script cpd_vars_531.sh as follows.
```
vi cpd_vars_531.sh
```
1. Locate the VERSION entry and update the environment variable for VERSION.
```
export VERSION=5.3.1
```
2. Locate the COMPONENTS entry and confirm the COMPONENTS entry is accurate.
```
export COMPONENTS=ibm-licensing,cpfs,cpd_platform,wkc,datastage_ent, analyticsengine,datalineage,ikc_standard,ikc_premium,semantic_automation
```
3. Add a new section called Image pull configuration to your script and add the following environment variables
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=cri-updating-your-environment-variables-script
```
export IMAGE_PULL_SECRET=<hptv-pull-secret>
export IMAGE_PULL_CREDENTIALS=$(echo -n "$PRIVATE_REGISTRY_PULL_USER:$PRIVATE_REGISTRY_PULL_PASSWORD" | base64 -w 0)
export IMAGE_PULL_PREFIX=${PRIVATE_REGISTRY_LOCATION}
```
4. Locate the OLM_UTILS_IMAGE entry and update the value
```
export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
export OLM_UTILS_LAUNCH_ARGS=" --network=host"
```
5. Save the changes. 

6. Confirm that the script does not contain any errors.
```
bash ./cpd_vars_531.sh
```
7. Run this command to apply cpd_vars_531.sh
```
source ./cpd_vars_531.sh
```

## 1.7 Mirror CPD 5.3.1 images
### 1.7.1 Obtaining the olm-utils-v4 image
```
podman pull cp.icr.io/cp/cpd/olm-utils-premium-v4:${VERSION}.amd64 --tls-verify=false

podman login ${PRIVATE_REGISTRY_LOCATION} -u ${PRIVATE_REGISTRY_PUSH_USER} -p ${PRIVATE_REGISTRY_PUSH_PASSWORD}

podman tag cp.icr.io/cp/cpd/olm-utils-premium-v4:${VERSION}.amd64 ${PRIVATE_REGISTRY_LOCATION}/cp/cpd/olm-utils-premium-v4:${VERSION}.amd64 

podman push ${PRIVATE_REGISTRY_LOCATION}/ cp/cpd/olm-utils-premium-v4:${VERSION}.amd64
```
### 1.7.2 Downloading CASE packages 
```
cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION}
```

### 1.7.3 Mirroring images directly to the private container registry
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=mipcr-mirroring-images-directly-private-container-registry-1

Log in to the IBM Entitled registry:
```
cpd-cli manage login-entitled-registry ${IBM_ENTITLEMENT_KEY}
```
Log in to the private container registry.

The following command assumes that you are using a private container registry that is secured with credentials:
```
cpd-cli manage login-private-registry \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PUSH_USER} \
${PRIVATE_REGISTRY_PUSH_PASSWORD}

cpd-cli manage mirror-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--target_registry=${PRIVATE_REGISTRY_LOCATION} \
--arch=${IMAGE_ARCH} \
--case_download=false
```
Mirror the required vLLM images for Inference foundation models (ibm-watsonx-ai-ifm)
```
skopeo copy --all \
--src-username cp \
--src-password ${IBM_ENTITLEMENT_KEY} \
--src-tls-verify=false \
--dest-username ${PRIVATE_REGISTRY_PUSH_USER} \
--dest-password ${PRIVATE_REGISTRY_PUSH_PASSWORD} \
--dest-tls-verify=false \
docker://cp.icr.io/cp/cpd/vllm@sha256:cc95bc7619549a5fb9342f8c41c613df5cd65b4e1f90b408db062559a2fdcff9 \
docker://${PRIVATE_REGISTRY_LOCATION}/cp/cpd/vllm@sha256:cc95bc7619549a5fb9342f8c41c613df5cd65b4e1f90b408db062559a2fdcff9
```

## 1.8 Final checks before start the upgrade
### 1.8.1 Pre-upgade check 
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=hub-upgrading-software

### 1.8.2 Uninstall all hotfixes
Needs to check all CRs for any custom image used.

### 1.8.3 Backup the RSI patches
```
cpd-cli manage get-rsi-patch-info \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--all
```
### 1.8.4 Final health check OCP & CPD
Check OCP status
Log onto the bastion node, in the termial log into OCP and run this command.
```
oc get co
```
Make sure all the cluster operators are in AVAILABLE status. And not in PROGRESSING or DEGRADED status.
Run this command and make sure all nodes are in Ready status.
```
oc get nodes
```
Run this command and make sure all the machine configuretion pool are in a healthy status.
```
oc get mcp
```
Check Cloud Pak for Data status
Log onto the bastion node, and make sure the IBM Cloud Pak for Data command-line interface is installed properly.
Run this command in the terminal and make sure the Lite and all the services' status are in Ready status.
```
${CPDM_OC_LOGIN}
cpd-cli manage get-cr-status --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
Run this command and make sure all pods are healthy.
```
oc get po --no-headers --all-namespaces -o wide | grep -Ev '([[:digit:]])/\1.*R' | grep -v 'Completed'
```
Check the private container registry status if installed
Log into bastion node, where the private container registry is usually installed, as root. Run this command in the terminal and make sure it succeeds.
```
podman login --username $PRIVATE_REGISTRY_PULL_USER --password $PRIVATE_REGISTRY_PULL_PASSWORD $PRIVATE_REGISTRY_LOCATION --tls-verify=false
```
You can run this command to verify the images are in the private container registry.
```
curl -k -u ${PRIVATE_REGISTRY_PULL_USER}:${PRIVATE_REGISTRY_PULL_PASSWORD} https://${PRIVATE_REGISTRY_LOCATION}/v2/_catalog?n=6000 | jq .
```

# 2. Upgrade
## 2.1 Migrate to Red Hat OpenShift certificate manager
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=upgrading-migrating-red-hat-openshift-certificate-manager

The IBM Certificate Manager is deprecated.

### 2.1.1. Backing up your existing certificates before migrating to Red Hat OpenShift certificate manager
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=manager-backing-up-your-existing-certificates

### 2.1.2. Uninstalling IBM Certificate manager
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=manager-uninstalling-certificate

### 2.1.3. Mirroring Red Hat OpenShift certificate manager images to a private container registry
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=manager-mirroring-red-hat-openshift-certificate-images

> [!Note]
> Make sure you can obtain your Red Hat pull secret from the Red Hat OpenShift Cluster Manager.

> [!Note]
> Ensure that the oc-mirror plug-in V2 is installed on the client workstation. For more information, see Mirroring images for a disconnected installation by using the oc-mirror plugin v2 in the Red Hat OpenShift Container Platform documentation.

### 2.1.4. Installing the Red Hat OpenShift Container Platform cert-manager Operator
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=manager-installing-cert-operator

<b>Installing the cert-manager Operator for Red Hat OpenShift</b>

Log in to the OpenShift Container Platform web console.

Navigate to Operators → OperatorHub.

Enter `cert-manager` Operator for Red Hat OpenShift into the filter box.

Select the cert-manager Operator for Red Hat OpenShift version from Version drop-down list, and click Install.

On the Install Operator page:

Update the Update channel, if necessary. The channel defaults to `stable-v1`, which installs the latest stable release of the cert-manager Operator for Red Hat OpenShift.

Choose the Installed Namespace for the Operator. The default Operator namespace is `cert-manager-operator`.

If the `cert-manager-operator` namespace does not exist, it is created for you.

choose the `AllNamespaces` installation mode. 

Select an Update approval strategy Automatic

Verification

Navigate to Operators → Installed Operators.

Verify that cert-manager Operator for Red Hat OpenShift is listed with a Status of Succeeded in the cert-manager-operator namespace.

## 2.2 Upgrade shared cluster components
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=pyc-upgrading-shared-cluster-components

### 2.2.1 If you're not sure which project the License Service is in, run the following command:
```
oc get deployment -A | grep ibm-licensing-operator
```
If you're not sure whether the scheduling service is installed on the cluster, run the following command:
```
oc get scheduling -A
```
If the scheduling service is installed, ensure that the COMPONENTS variable in your environment variables script includes the scheduler component.

### 2.2.2  Log in to the Red Hat OpenShift Container Platform cluster:
```
${CPDM_OC_LOGIN}
```
Verify install plans allow upgrade approval
```
 oc get ip -A
```
If approval is manual and approved is false, change approved to true to allow the upgrade.  One can change approved back to false after upgrade is completed.
```
oc patch installplan <installplan-name> -n <namespace> --type merge -p '{"spec":{"approved":true}}'
```
Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```

### 2.2.3 Upgrade the License Service.
Confirm the project in which the License Service is running.
```
oc get deployment -A |  grep ibm-licensing-operator
```
Make sure the project returned by the command matches the environment variable PROJECT_LICENSE_SERVICE in your environment variables script `cpd_vars_531.sh`.

Upgrade the License Service.
```
cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```

### 2.2.4 Confirm that the License Service pods are Running or Completed:
```
oc get pods --namespace=${PROJECT_LICENSE_SERVICE}
```

## 2.3 Creating image pull secrets for an instance of IBM Software Hub (Upgrading from Version 5.2 to Version 5.3)
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=uish-creating-image-pull-secrets-instance-1

Follow the steps from the above link. Consider the `Private container registry` option.

## 2.4 Prepare to upgrade IBM Software Hub
### 2.4.1 Run the cpd-cli manage login-to-ocp command to log in to the cluster
```
${CPDM_OC_LOGIN}
```
### 2.4.2 Updating the cluster-scoped resources for the platform and services
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=puish-updating-cluster-scoped-resources-instance
```
cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cluster_resources=true
```
Change to the work directory. The default location of the work directory is `cpd-cli-workspace/olm-utils-workspace/work`.
```
cd cpd-cli-workspace/olm-utils-workspace/work
```
Log in to Red Hat® OpenShift® Container Platform as a cluster administrator.
```
${OC_LOGIN}
```
Apply the cluster-scoped resources from the `cluster_scoped_resources.yaml` file.
```
oc apply -f cluster_scoped_resources.yaml \
--server-side \
--force-conflicts
```
Have a record of the resources that you generated.
```
mv cluster_scoped_resources.yaml ${VERSION}-${PROJECT_CPD_INST_OPERATORS}-cluster_scoped_resources.yaml
```

### 2.4.3 Applying your entitlements to monitor and report use against license terms
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=aye-applying-your-entitlements-without-node-pinning-1

Applying your entitlements without node pinning
```
cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=cpd-enterprise

cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=ikc-premium

cpd-cli manage apply-entitlement \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--entitlement=data-lineage \
--production=false
```

## 2.5 Upgrade IBM Software Hub
### 2.5.1. Run the cpd-cli manage login-to-ocp command to log in to the cluster.
```
${CPDM_OC_LOGIN}
```
### 2.5.2 Upgrade the required operators and custom resources for the instance.
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=uish-upgrading-software-hub

See all available license URLs
```
cpd-cli manage get-license --release=${VERSION}


cpd-cli manage install-components \
--license_acceptance=true \
--components=cpd_platform \
--release=${VERSION} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--run_storage_tests=false \
--upgrade=true
```
Once the above command `cpd-cli manage install-components` is complete, make sure the status of the IBM Software Hub is in 'Completed' status.
```
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \ 
--components=cpd_platform
```
### 2.5.3 Apply the RSI patches
Run the following command to re-apply your existing custom patches.
```
cpd-cli manage apply-rsi-patches --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```
Check the RSI patches status again: 
```
cpd-cli manage get-rsi-patch-info --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --all

cat $CPD_CLI_WORK_DIR/get_rsi_patch_info.log
```
## 2.6 Install Red Hat OpenShift AI
### 2.6.1 Mirroring Red Hat OpenShift AI images to a private container registry
https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#mirroring-images-to-a-private-registry-for-a-disconnected-installation_install <br>
Create an ImageSetConfiguration definition file named imageset-config.yaml
```
cat << EOF > ./imageset-config.yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:${OPENSHIFT_VERSION}
      packages:
        - name: rhods-operator
          channels:
            - name: stable-2.25
              minVersion: 2.25.4
              maxVersion: 2.25.4
  additionalImages:
    - name: quay.io/modh/text-generation-inference@sha256:8419f73485c75b4eb0095d31879cc1a94e2be38a0ece08bc7923cef9cdd9444a
    - name: quay.io/rhoai/odh-model-registry-job-async-upload-rhel9@sha256:2791e74c01749df5a5526f799211bcd5087c7c1e92a0ac947ede8d7ee642f9ca
    - name: quay.io/modh/fms-hf-tuning@sha256:1ad46fe1a23f41f190c49ec2549c64f484c88fe220888a7a5700dd857ca243cc
    - name: quay.io/modh/ray@sha256:595b3acd10244e33fca1ed5469dccb08df66f470df55ae196f80e56edf35ad5a
    - name: quay.io/modh/ray@sha256:6b135421b6e756593a58b4df6664f82fc4b55237ca81475f2867518f15fe6d84
    - name: quay.io/modh/ray@sha256:28a8745be454b0e881ce6c200599ddfcb3366b707a5b53cfa73087d599555158
    - name: quay.io/modh/ray@sha256:900c35ec2fe4279b958e044c781a179c8cfe0c584e8af16e253814dba01816e6
    - name: registry.redhat.io/rhelai1/instructlab-nvidia-rhel9@sha256:b3dc9af0244aa6b84e6c3ef53e714a316daaefaae67e28de397cd71ee4b2ac7e
    - name: registry.redhat.io/openshift4/ose-oauth-proxy-rhel9@sha256:d3056b35d9a205b9f2c48d924f199c5ac23904eb18d526e4bff229e7c7181415
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:2217d8a9cbf84c2bd3e6c6dc09089559e8a3905687ca3739e897c4b45e2b00b3
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:e2296a1386e4d9756c386b4c7dc44bac6f61b99b3b894a10c9ff2d8d5602ca4e
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:4ba72ae7f367a36030470fa4ac22eca0aab285c7c3f1c4cdcc33dc07aa522143
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:eec50e5518176d5a31da739596a7ddae032d73851f9107846a587442ebd10a82
    - name: quay.io/modh/odh-minimal-notebook-container@sha256:39068767eebdf3a127fe8857fbdaca0832cdfef69eed6ec3ff6ed1858029420f
    - name: quay.io/modh/cuda-notebooks@sha256:55598c7de919afc6390cf59595549dc4554102481617ec42beaa3c47ef26d5e4
    - name: quay.io/modh/cuda-notebooks@sha256:81484fafe7012792ecdda28fef89287219c21b99c4e79a504aff0b265d94b429
    - name: quay.io/modh/cuda-notebooks@sha256:a484d344f6feab25e025ea75575d837f5725f819b50a6e3476cef1f9925c07a5
    - name: quay.io/modh/cuda-notebooks@sha256:f6cdc993b4d493ffaec876abb724ce44b3c6fc37560af974072b346e45ac1a3b
    - name: quay.io/modh/cuda-notebooks@sha256:00c53599f5085beedd0debb062652a1856b19921ccf59bd76134471d24c3fa7d
    - name: quay.io/modh/odh-pytorch-notebook@sha256:20f7ab8e7954106ea5e22f3ee0ba8bc7b03975e5735049a765e021aa7eb06861
    - name: quay.io/modh/odh-pytorch-notebook@sha256:2403b3dccc3daf5b45a973c49331fdac4ec66e2e020597975fcd9cb4a625099b
    - name: quay.io/modh/odh-pytorch-notebook@sha256:806e6524cb46bcbd228e37a92191c936bb4c117100fc731604e19df80286b19d
    - name: quay.io/modh/odh-pytorch-notebook@sha256:97b346197e6fc568c2eb52cb82e13a206277f27c21e299d1c211997f140f638b
    - name: quay.io/modh/odh-pytorch-notebook@sha256:b68e0192abf7d46c8c6876d0819b66c6a2d4a1e674f8893f8a71ffdcba96866c
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:d0ba5fc23e2b3846763f60e8ade8a0f561cdcd2bf6717df6e732f6f8b68b89c4
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:3e51c462fc03b5ccb080f006ced86d36480da036fa04b8685a3e4d6d51a817ba
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:39853fd63555ebba097483c5ac6a375d6039e5522c7294684efb7966ba4bc693
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:e2cab24ebe935d87f7596418772f5a97ce6a2e747ba0c1fd4cec08a728e99403
    - name: quay.io/modh/odh-generic-data-science-notebook@sha256:76e6af79c601a323f75a58e7005de0beac66b8cccc3d2b67efb6d11d85f0cfa1
    - name: quay.io/modh/cuda-notebooks@sha256:99d3fb964e635873214de4676c259a96c2ea25f3f79cc4bead5bc9f39aba34c0
    - name: quay.io/modh/cuda-notebooks@sha256:0e57a0b756872636489ccd713dc9f00ad69d0c481a66ee0de97860f13b4fedcd
    - name: quay.io/modh/cuda-notebooks@sha256:3da74d732d158b92eaada0a27fb7067fa18c8bde5033c672e23caed0f21d6481
    - name: quay.io/modh/cuda-notebooks@sha256:88d80821ff8c5d53526794261d519125d0763b621d824f8c3222127dab7b6cc8
    - name: quay.io/modh/cuda-notebooks@sha256:6fadedc5a10f5a914bb7b27cd41bc644392e5757ceaf07d930db884112054265
    - name: quay.io/modh/odh-trustyai-notebook@sha256:a1b863c2787ba2bca292e381561ed1d92cf5bc25705edfb1ded5e0720a12d102
    - name: quay.io/modh/odh-trustyai-notebook@sha256:70fe49cee6d5a231ddea7f94d7e21aefd3d8da71b69321f51c406a92173d3334
    - name: quay.io/modh/odh-trustyai-notebook@sha256:fe883d8513c5d133af1ee3f7bb0b7b37d3bada8ae73fc7209052591d4be681c0
    - name: quay.io/modh/odh-trustyai-notebook@sha256:8c5e653f6bc6a2050565cf92f397991fbec952dc05cdfea74b65b8fd3047c9d4
    - name: quay.io/modh/codeserver@sha256:92f2a10dde5c96b29324426b4325401e8f4a0d257e439927172d5fe909289c44
    - name: quay.io/modh/codeserver@sha256:1fd51b0e8a14995f1f7273a4b0b40f6e7e27e225ab179959747846e54079d61e
    - name: quay.io/modh/codeserver@sha256:b1a048f3711149e36a89e0eda1a5601130fb536ecc0aabae42ab6e4d26977354
    - name: quay.io/modh/rocm-notebooks@sha256:199367d2946fc8427611b4b96071cb411433ffbb5f0988279b10150020af22db
    - name: quay.io/modh/rocm-notebooks@sha256:1f0b19b7ae587d638e78697c67f1290d044e48bfecccfb72d7a16faeba13f980
    - name: quay.io/modh/rocm-notebooks@sha256:f94702219419e651327636b390d1872c58fd7b8f9f6b16a02c958ffb918eded3
EOF
```

## 2.7 Upgrade WKC
Create the install-options.yml file in the cpd-cli work directory (For example: cpd-cli-workspace/olm-utils-workspace/work)
<br><b>These need to be checked</b>
```
---
# ............................................................................
# IBM Knowledge Catalog Premium parameters
# ............................................................................
non_olm:
  ikcPremium:
    enableDataQuality: False
    enableKnowledgeGraph: False
    useFDB: False
    enableAISearch: False
    enableSemanticAutomation: False
    enableSemanticEnrichment: True
    enableSemanticEmbedding: False
    enableTextToSql: False
    enableModelsOn: 'cpu'
    customModelTextToSQL: granite-3-3-8b-instruct
```

Upgrade with the custom option
```
cpd-cli manage install-components \
--license_acceptance=true \
--components=${IKC_TYPE} \
--release=${VERSION} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--param-file=/tmp/work/install-options.yml \
--upgrade=true
```
Check ccs progress first:
```
watch oc get ccs 
```
Check WKC Premium progress:
```
oc get ikc_premium
```

## 2.8 Upgrade DataLineage
```
cpd-cli manage install-components \
--license_acceptance=true \
--components=datalineage \
--release=${VERSION} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--upgrade=true
```
Check DataLineage progress:
```
oc get datalineage
```


## 2.9 Upgrade DataStage
```
cpd-cli manage install-components \
--license_acceptance=true \
--components=datastage_ent \
--release=${VERSION} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--upgrade=true
```
Check DataStage progress
```
oc get DataStage
```

# 3. Post-upgrade tasks
RSI patches, hotfix links, and DataStage patches.

