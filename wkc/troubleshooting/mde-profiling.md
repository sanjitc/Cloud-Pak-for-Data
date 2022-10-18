# Troubleshooting - Metadata Enrichment - Profiling
## Prods 

```
$ oc get pods | grep "wdp-profiling-"

wdp-profiling-66f8475bb8-fgblj                               0/1     Running                 985        15d
wdp-profiling-7675464d6d-9lmjl                               0/1     Running                 2629       40d
```

## Logs
Get all profiling related appliction logs from each `wdp-profiling` pods
```
$ oc rsh <wdp-profiling-*> bash
bash-4.4$ cd /logs
bash-4.4$ ls -l

total 1024
-rw-r-----. 1 1000650000 root 329937 Oct 18 19:45 messages.log
-rw-r-----. 1 1000650000 root 349125 Oct 18 19:45 trace.log
```
