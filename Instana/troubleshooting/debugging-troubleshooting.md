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

## Adjust log level for Instana components
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

Replace `<component name>` is the component name that you want to troubleshoot.

