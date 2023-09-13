## Internal catalog of a project
```
curl -sk --user $(oc get secret wdp-service-id --output=jsonpath='{.data.service-id-credentials}' | base64 -d | base64 -d) https://$CPD_URL/v2/projects/b3fd1b68-5b18-4b88-ac15-f782e68eaec9 | jq '.entity.catalog'
```
