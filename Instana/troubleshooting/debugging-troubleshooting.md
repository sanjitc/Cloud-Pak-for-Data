# Debugging and troubleshooting
![Instana On-Prem Architecture](https://github.com/sanjitc/Cloud-Pak-for-Data/blob/main/images/Instana-On-Prem-Architecture.png)

## Mustgather
For "error" or "troubleshooting" issues, proactively capture the required must-gather data and upload it to the ticket.
Include the date and time when the issue occurred. Ensure the must-gather captured covers the time when the issue was reproduced.

### Must-Gather Resources:
- Collect must-gather data for Self-hosted Instana **backend** environments (Kubernetes/OpenShift):
  [Self-hosted Instana backend environments running on Kubernetes/OpenShift](https://www.ibm.com/support/pages/how-collect-instana-doc-self-hosted-instana-backend-environments-kubernetesopenshift)
- Collect Agent logs:
  - [Getting the Instana Agent logs for Windows Host](https://www.ibm.com/support/pages/node/7015761)
  - [Getting Instana Agent logs for Linux Host](https://www.ibm.com/support/pages/node/7024752)
  - [Instana agent and k8sensor logs on Red Hat Openshift and Kubernetes environments](https://www.ibm.com/support/pages/node/6823809)

## Collect information (**backend**)
Create an archive file with information about your cluster. You can use the information in the file to troubleshoot issues, or share the file with the support team.

The archive file collects the following information:

- Container logs
- Resource manifests (in YAML format)
- stanctl logs
- System information that includes memory, CPU, and CPU usage
- Disk mounts and their usage
- Open files (allocated, free, and maximum)
- Backend logs
- Use the following command to create the archive file:
```
stanctl debug
```

## Adjust log level for Instana components (**backend**)
To adjust the level for Instana components, complete following steps:

1. Edit the Core Config file, for example, `$HOME/.stanctl/values/instana-core/custom-values.yaml`.

2. Configure a component’s log level in the Core or Unit CR. In the following example, the log level is changed to DEBUG for the butler component:
```
componentConfigs:
  - name: butler
    env:
      - name: COMPONENT_LOGLEVEL
        # Possible values are DEBUG, INFO, WARN, ERROR (not case-sensitive)
        value: DEBUG
```
3. Apply the custom values by running the following command:
```
stanctl backend apply
```

4. View the logs by running the following command:
```
kubectl logs <component name> -n instana-core
```

`<component name>` is the component name that you want to troubleshoot.

## Adjust log level for Instana Agent
If you have an issue on the agent side, collect the agent debug logs for the Instana team for further investigation.
Follow the steps to gather the Agent `DEBUG` logs that capture most details for diagnosis and then default `INFO` logs:
- Stop the agent (`<instana_install_dir>/bin/stop.sh`)
- Wipe the logs (delete all files in `<instana_install_dir>/data/logs`)
- Set log level to DEBUG (change the severity in the configuration file (`*instanaAgentDir*/etc/org.ops4j.pax.logging.cfg`)
```
log4j2.logger.instana.level=DEBUG
```
- Start the agent (`<instana_install_dir>/bin/start.sh`)
- Reproduce the issue and after ~15 minutes zip up the logs (in `<instana_install_dir>/data/logs`) and upload the zip file to the support case.

## Host agent cannot connect to the Instana backend on SLES hosts
After you install the host agent on the local host on SUSE Linux Enterprise Server (SLES) 15 SP5 hosts for self monitoring, the agent does not automatically connect to the Instana backend.

You must use the agent external URL to connect to the backend as a remote host. Use the following command:
```
stanctl agent apply --agent-endpoint-host agent-acceptor.<base_domain> --agent-endpoint-port 8443
```
