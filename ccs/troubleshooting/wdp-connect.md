### Troubleshooting - Metadata Enrichment - Profiling
### Pods
```
wdp-connect-connection*
wdp-connect-connector*
```

### Logs
```
oc get pods --all-namespaces | grep wdp-connect-connect
oc exec "<name of wdp-connect-connection pod>" -- tar czf - logs 2>/dev/null > wdp-connect-connection.tar.gz
oc exec "<name of wdp-connect-connector pod>" -- tar czf - logs 2>/dev/null > wdp-connect-connector.tar.gz
```
