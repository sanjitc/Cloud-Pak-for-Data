## How to update the Agent configuration within Instana?
- [This is just a reference] When you did your Agent install, you did something like this:
```
helm install instana-agent \
  --repo https://agents.instana.io/helm \
  --namespace instana-agent \
  --set 'openshift=true' \
  --set agent.key=wxyz  \
  --set agent.downloadKey=abcdefg \
  --set agent.endpointHost=agent-acceptor.instana2.tivlab.raleigh.ibm.com  \
  --set agent.endpointPort=443 \
  --set zone.name='zone1' \
  --set cluster.name='cluster1' \
  --set agent.configuration_yaml="$(cat values.yaml)" \
  --set k8s_sensor.deployment.enabled=true \
  --set k8s_sensor.deployment.replicas=2 \
  instana-agent
```
- Within the `values.yaml` file, you add yaml that comes from the `configuration.yaml`. Each Instana sensor has documented yaml. For example, here is the yaml to ignore a process:
```
com.instana.ignore:
  processes:
    - '/opt/mqm/amqp/bin/../../java/jre64/jre/bin/java'
    - 'DataFlowEngine'
  arguments:
    #    - '-Dbroker.networkaddressCacheTtl=60'
```
- After updating the values.yaml, you run a helm upgrade command similar to what's below:
```
helm upgrade --namespace instana-agent instana-agent \
--repo https://agents.instana.io/helm instana-agent  \
--set agent.configuration_yaml="$(cat values.yaml)" --reuse-values
```
