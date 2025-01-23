## Capture wkc-data-lineage-service log with DEBUG level:

1. Set wkc-cr to maintenance mode

2. Run command
```
oc edit deployment wkc-data-lineage-service
```
In the opened editor locate `-env` section and add underneath
```
      - env:
        - name: SPRING_APPLICATION_JSON
          value: '{"logging.level.com.ibm.wdp":"DEBUG"}'
```
(Note that SPRING_APPLICATION_JSON may already be there if you did this procedure before, then only log level should be changed to DEBUG).

Save the file and wait for wkc-data-lineage-service  pod to restart.
```
oc get pod | grep wkc-data-lineage-service
```

3. Right after the service is back up and running start collections the logs
```
oc logs -f wkc-data-lineage-service-<podid> > lineage.log
```
4. Click on get lineage for problematic asset and wait for the timeout to occur. Stop the tail command a minute later.
5. Revert logs back to INFO by running
`oc edit deployment wkc-data-lineage-service` and replacing the
```
      - env:
        - name: SPRING_APPLICATION_JSON
          value: '{"logging.level.com.ibm.wdp":"INFO"}'
```
