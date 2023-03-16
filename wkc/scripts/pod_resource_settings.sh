for i in $(oc get pods --no-headers | grep -i running | cut -f1 -d\ ); 
do 
   echo $i; 
   oc get pods -o jsonpath="{.metadata.name},{.metadata.annotations.productName},{.spec.containers[*].resources.requests.cpu},{.spec.containers[*].resources.limits.cpu},{.spec.containers[*].resources.requests.memory},{.spec.containers[*].resources.limits.memory},{.metadata.labels.icpdsupport/addOnId}{'\n'}" ${i} >> dump.txt; 
done 
