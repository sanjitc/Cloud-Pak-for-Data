# Troubleshooting - Rabbit MQ issues
## Prods 

```
rabbitmq-ha-*
```

## Logs

1.  Get the application log
```
oc exec rabbitmq-ha-0 -- rabbitmqctl report
```
