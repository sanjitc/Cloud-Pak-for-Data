# CCS Reconcoliation Problem

### 1. On CPD 4.6.5 CCS reconciliation failing during "runtime-manager-upgrade-job". 
It encountered timeout (activeDeadlineSeconds) while executing this job.
a. Get the job description in YAML format
```
oc get job runtime-manager-upgrade-job -oyaml > runtime-manager-upgrade-job.yaml
```
b. Increase the timeout from 1200 to 4800 secounds. 
Make the change under the spec section in the YAML file. 
```
vim runtime-manager-upgrade-job.yaml
spec:
  activeDeadlineSeconds: 4800
```
c. Monitor CCS operator pod log. Once is starts executing the "runtime-manager-upgrade-job", run following:
```
oc delete -f runtime-manager-upgrade-job.yaml
oc apply -f runtime-manager-upgrade-job.yaml
oc get po | grep runtime-manager-upgrade-job
oc logs runtime-manager-upgrade-job-cksnz -f
```
