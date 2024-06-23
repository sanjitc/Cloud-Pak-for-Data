## Multi-Attach error for volume
Two couchdb pods can't start.
```
$ oc get pods | egrep -v 'Running|Completed'
NAME                                               READY   STATUS      RESTARTS        AGE     IP              NODE                            NOMINATED NODE   READINESS GATES
wdp-couchdb-0                                      0/2     Init:0/1    0               152m    <none>          worker3.vz265.cp.fyre.ibm.com   <none>           <none>
wdp-couchdb-1                                      0/2     Init:0/1    0               152m    <none>          worker5.vz265.cp.fyre.ibm.com   <none>           <none>
```
Both of them complains about `Multi-Attach error for volume: Volume is already exclusively attached to one node and can't be attached to another`:
```
$ oc describe pod wdp-couchdb-0
Name:             wdp-couchdb-0
... ...
Events:
  Type     Reason              Age                   From                     Message
  ----     ------              ----                  ----                     -------
  Normal   Scheduled           152m                  default-scheduler        Successfully assigned wkc/wdp-couchdb-0 to worker3.vz265.cp.fyre.ibm.com
  Warning  FailedAttachVolume  152m                  attachdetach-controller  Multi-Attach error for volume "pvc-739c0b97-02fc-4121-9fa0-f6c39242a248" Volume is already exclusively attached to one node and can't be attached to another

$ oc describe pod wdp-couchdb-1
Name:             wdp-couchdb-1
... ...
Events:
  Type     Reason              Age                   From                     Message
  ----     ------              ----                  ----                     -------
  Normal   Scheduled           152m                  default-scheduler        Successfully assigned wkc/wdp-couchdb-1 to worker5.vz265.cp.fyre.ibm.com
  Warning  FailedAttachVolume  152m                  attachdetach-controller  Multi-Attach error for volume "pvc-01c8f7fc-a12f-44ce-8440-27eb395139c0" Volume is already exclusively attached to one node and can't be attached to another
  Warning  FailedMount         150m                  kubelet                  Unable to attach or mount volumes: unmounted volumes=[database-storage], unattached volumes=[vm-config ssl-certs clouseau-config config-storage database-storage config shared-data config-storage2 secrets-mount]: timed out waiting for the condition
```

## Checked cephfs status. 
```
$ oc exec -it $(oc get po -n openshift-storage | grep ceph-tools | awk '{ print $1 }') -n openshift-storage -- /bin/bash
bash-4.4$ ceph status
  cluster:
    id:     5ffa0df5-eec2-4af6-96c3-d3051f058e41
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum a,b,c (age 6h)
    mgr: a(active, since 6h)
    mds: 1/1 daemons up, 1 hot standby
    osd: 9 osds: 9 up (since 6h), 9 in (since 2w)
    rgw: 1 daemon active (1 hosts, 1 zones)
 
  data:
    volumes: 1/1 healthy
    pools:   12 pools, 449 pgs
    objects: 4.73M objects, 326 GiB
    usage:   1.0 TiB used, 4.3 TiB / 5.3 TiB avail
    pgs:     449 active+clean
 
  io:
    client:   3.0 KiB/s rd, 1.6 MiB/s wr, 2 op/s rd, 24 op/s wr
 
bash-4.4$ ceph health detail
HEALTH_OK
```

## Find volumeattachment on the nodes.
```
$ oc get volumeattachment |grep pvc-739c0b97-02fc-4121-9fa0-f6c39242a248
csi-1105b6e3f4ab47d83c3b6f475ed374ef0560aa65d44a1aa985a1ce96356e3758   openshift-storage.rbd.csi.ceph.com      pvc-739c0b97-02fc-4121-9fa0-f6c39242a248   worker1.vz265.cp.fyre.ibm.com   true       20h

$ oc get volumeattachment csi-1105b6e3f4ab47d83c3b6f475ed374ef0560aa65d44a1aa985a1ce96356e3758 -o yaml
apiVersion: storage.k8s.io/v1
kind: VolumeAttachment
metadata:
  creationTimestamp: "2024-04-03T16:47:57Z"
  name: csi-1105b6e3f4ab47d83c3b6f475ed374ef0560aa65d44a1aa985a1ce96356e3758
  resourceVersion: "18673498"
  uid: 3fc24000-599b-44be-b65b-dcf88095f26b
spec:
  attacher: openshift-storage.rbd.csi.ceph.com
  nodeName: worker1.vz265.cp.fyre.ibm.com
  source:
    persistentVolumeName: pvc-739c0b97-02fc-4121-9fa0-f6c39242a248
status:
  attached: true

$ oc get volumeattachment |grep pvc-01c8f7fc-a12f-44ce-8440-27eb395139c0 
csi-da4b996864b6bfe6e609e23637bff55c869290af7e795c70b19e7e7396b9cc39   openshift-storage.rbd.csi.ceph.com      pvc-01c8f7fc-a12f-44ce-8440-27eb395139c0   worker6.vz265.cp.fyre.ibm.com   true       8d

$ oc get volumeattachment csi-da4b996864b6bfe6e609e23637bff55c869290af7e795c70b19e7e7396b9cc39
NAME                                                                   ATTACHER                             PV                                         NODE                            ATTACHED   AGE
csi-da4b996864b6bfe6e609e23637bff55c869290af7e795c70b19e7e7396b9cc39   openshift-storage.rbd.csi.ceph.com   pvc-01c8f7fc-a12f-44ce-8440-27eb395139c0   worker6.vz265.cp.fyre.ibm.com   true       8d
```
In this example the pod is trying to scheduled on worker5, but the volumeattachment is on worker6.
Remove the volumeattachment that running on worker6.
```
$ oc delete volumeattachment csi-da4b996864b6bfe6e609e23637bff55c869290af7e795c70b19e7e7396b9cc39
```
After remove the old volumeattachment restart failed pods. 



