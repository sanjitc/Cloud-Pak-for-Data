# RSI Patch - Delete - Reinstall
cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}

Inactivate:
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--patch_name=asset-files-api-annotation-selinux \
--state=inactive
Delete:
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--patch_name=asset-files-api-annotation-selinux
Inactivate:
cpd-cli manage create-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--patch_name=asset-files-api-pod-spec-selinux \
--state=inactive
Delete:
cpd-cli manage delete-rsi-patch \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--patch_name=asset-files-api-pod-spec-selinux
10:03
**********************Re-install********************************
Install the RSI patches
 Create a json patch file named annotation-spec.json under cpd-cli-workspace/olm-utils-workspace/work/rsi with the following content:
[{"op":"add","path":"/metadata/annotations/io.kubernetes.cri-o.TrySkipVolumeSELinuxLabel","value":"true"}]
Create a json patch file named specpatch.json under cpd-cli-workspace/olm-utils-workspace/work/rsi with the following content:
[{"op":"add","path":"/spec/runtimeClassName","value":"selinux"}]
 - Reinstall the asset-files-api-annotation-selinux.
cpd-cli manage create-rsi-patch --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --patch_type=rsi_pod_annotation --patch_name=asset-files-api-annotation-selinux --description="This is annotation patch is for 
