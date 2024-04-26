### Troubleshooting - Metadata Enrichment - Profiling
### Pods
```
wdp-connect-connection*
wdp-connect-connector*
```

### Logs
```
oc exec "wdp-connect-connetion..." -- tar czf - logs 2>/dev/null > wdp-connect-connection.tar.gz
oc exec "wdp-connect-connetor..." -- tar czf - logs 2>/dev/null > wdp-connect-connector.tar.gz
```
