# Troubleshooting - Rabbit MQ issues
## Prods 

```
rabbitmq-ha-*
```
## Check queues
```
oc exec rabbitmq-ha-0 -- rabbitmqctl list_queues
```
## Logs

1.  Get the application log
```
oc exec rabbitmq-ha-0 -- rabbitmqctl report
```
