## CCS CR Reconciliation problem on 4.6.5:
- SF - TS015141757
- Git - https://github.ibm.com/dap/dap-planning/issues/32155
- While CCS is reconciling monitor the CCS operator pod log. Once it is in the "runtime-manager-upgrade-job" process,  modify runtime-manager-upgrade-job, alter the `activeDeadlineSeconds: 1200`  to  `activeDeadlineSeconds: 9600`
```
 oc get job runtime-manager-upgrade-job -oyaml > runtime-manager-upgrade-job.yaml
 vim runtime-manager-upgrade-job.yaml         <-- Active Deadline Seconds:  1200s  ->  9600s
 oc delete -f runtime-manager-upgrade-job.yaml
 oc apply -f runtime-manager-upgrade-job.yaml
 oc get po | grep runtime-manager-upgrade-job
 oc logs runtime-manager-upgrade-job-cksnz -f
```
