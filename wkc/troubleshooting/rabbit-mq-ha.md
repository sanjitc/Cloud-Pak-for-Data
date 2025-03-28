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

## How to access RabbitMQ console
1) Find credentials for access console
   - Get the rabbitmq-username and rabbitmq-password from `oc get secret rabbitmq-ha -oyaml`
   - Decdoe them using `echo -n 'XXXXXXXXXX'|base64 -d` 

2) Forward local ports to `rabbitmq-ha` pod 
   - From a client machine CMD (Windows/Mac/Linux) 
      (From OCP console, download `oc` cmmandline tool in respect to the client),
   - Login to cluster using `oc` CLI and set appropriate projcet 
   - Forward the port using `oc port-forward rabbitmq-ha-0 15671:15671`

3) Access RabbitMQ console from client machine browser: `https://localhost:15671/#/queues`

## Logs

1.  Get the application log
```
oc exec rabbitmq-ha-0 -- rabbitmqctl report
```
