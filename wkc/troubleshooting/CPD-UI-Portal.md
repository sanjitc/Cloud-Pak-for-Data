### CPD UI pages failing with 500 error

Restarting of following pods helps with common "Error 500 - Something's wrong." 
```
oc delete pod -n <project> <dc-main pod name>
oc delete pod -n <project> <redis-ha-haproxy pod name>
oc delete pod -n <project> -l app=redis-ha  <--- (-l = lowercase L)
oc delete pod -n <project> <portal-main pod name>
oc delete pod portal-catalog
oc delete pod portal-project
oc delete pod portal-job
```
