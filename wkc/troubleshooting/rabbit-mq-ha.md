# Troubleshooting - Rabbit MQ issues
## Prods 

```
rabbitmq-ha-*
```
## Check queues from CLI
```
oc exec rabbitmq-ha-0 -- rabbitmqctl list_queues
```
## Check queues from Rabbit Console
```
1) oc create route passthrough rmqadmin --
2) oc get secret rabbitmq-ha -o json | jq -r '.data."rabbitmq-username"' |base64 -d
   oc get secret rabbitmq-ha -o json | jq -r '.data."rabbitmq-password"' |base64 -d
3) oc get route rmqadmin
4) Access the Rabbit console using the route/URL from browser
```

## Logs

1.  Get the application log
```
oc exec rabbitmq-ha-0 -- rabbitmqctl report
```
