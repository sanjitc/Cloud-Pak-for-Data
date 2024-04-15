```
metadata:
  creationTimestamp: "2023-01-12T20:15:58Z"
  labels:
    app: runtime-base
    app.kubernetes.io/component: runtime-manager-upgrade-job
    app.kubernetes.io/instance: runtime-base
    app.kubernetes.io/managed-by: runtime-base
    app.kubernetes.io/name: runtime-manager-upgrade-job
    component: runtime-manager-upgrade-job
    icpdsupport/addOnId: ccs
    icpdsupport/app: runtime-manager-upgrade-job
    release: runtime-base
  managedFields:
  - apiVersion: batch/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:labels:
          .: {}
          f:app: {}
          f:app.kubernetes.io/component: {}
          f:app.kubernetes.io/instance: {}
          f:app.kubernetes.io/managed-by: {}
          f:app.kubernetes.io/name: {}
          f:component: {}
          f:icpdsupport/addOnId: {}
          f:icpdsupport/app: {}
          f:release: {}
        f:ownerReferences:
          .: {}
          k:{"uid":"a7f50f13-6ccc-4c85-a179-8d175392a2ee"}:
            .: {}
            f:apiVersion: {}
            f:kind: {}
            f:name: {}
            f:uid: {}
      f:spec:
        f:activeDeadlineSeconds: {}
        f:backoffLimit: {}
        f:completions: {}
        f:parallelism: {}
        f:template:
          f:metadata:
            f:annotations:
              .: {}
              f:cloudpakId: {}
              f:cloudpakInstanceId: {}
              f:cloudpakName: {}
              f:images: {}
              f:productChargedContainers: {}
              f:productCloudpakRatio: {}
              f:productID: {}
              f:productMetric: {}
              f:productName: {}
              f:productVersion: {}
            f:labels:
              .: {}
              f:app.kubernetes.io/instance: {}
              f:app.kubernetes.io/managed-by: {}
              f:app.kubernetes.io/name: {}
              f:component: {}
              f:icpdsupport/addOnId: {}
              f:icpdsupport/app: {}
          f:spec:
            f:affinity:
              .: {}
              f:nodeAffinity:
                .: {}
                f:requiredDuringSchedulingIgnoredDuringExecution:
                  .: {}
                  f:nodeSelectorTerms: {}
            f:containers:
              k:{"name":"runtime-manager-upgrade"}:
                .: {}
                f:command: {}
                f:env:
                  .: {}
                  k:{"name":"CPD_SI_MOUNT_PATH"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"CPD_UPGRADE_VERSION"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"DEPLOYMENT_LOCATON"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"LOG_LEVEL"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"NAMESPACE"}:
                    .: {}
                    f:name: {}
                    f:valueFrom:
                      .: {}
                      f:fieldRef:
                        .: {}
                        f:apiVersion: {}
                        f:fieldPath: {}
                  k:{"name":"NGINX_HOST_URL"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"RTM_K8S_USER_AGENT"}:
                    .: {}
                    f:name: {}
                    f:valueFrom:
                      .: {}
                      f:fieldRef:
                        .: {}
                        f:apiVersion: {}
                        f:fieldPath: {}
                  k:{"name":"RUNTIMES_DEPLOY_MODE"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                  k:{"name":"SATELLITE_LOCATION_ENABLED"}:
                    .: {}
                    f:name: {}
                    f:value: {}
                f:image: {}
                f:imagePullPolicy: {}
                f:name: {}
                f:resources:
                  .: {}
                  f:limits:
                    .: {}
                    f:cpu: {}
                    f:memory: {}
                  f:requests:
                    .: {}
                    f:cpu: {}
                    f:memory: {}
                f:securityContext:
                  .: {}
                  f:allowPrivilegeEscalation: {}
                  f:capabilities:
                    .: {}
                    f:drop: {}
                  f:privileged: {}
                  f:readOnlyRootFilesystem: {}
                  f:runAsNonRoot: {}
                f:terminationMessagePath: {}
                f:terminationMessagePolicy: {}
                f:volumeMounts:
                  .: {}
                  k:{"mountPath":"/etc/cp4d/credentials/cpd-si"}:
                    .: {}
                    f:mountPath: {}
                    f:name: {}
                    f:readOnly: {}
            f:dnsPolicy: {}
            f:restartPolicy: {}
            f:schedulerName: {}
            f:securityContext: {}
            f:serviceAccount: {}
            f:serviceAccountName: {}
            f:terminationGracePeriodSeconds: {}
            f:volumes:
              .: {}
              k:{"name":"cpd-si"}:
                .: {}
                f:name: {}
                f:projected:
                  .: {}
                  f:defaultMode: {}
                  f:sources: {}
    manager: OpenAPI-Generator
    operation: Update
    time: "2023-01-12T20:15:58Z"
  - apiVersion: batch/v1
    fieldsType: FieldsV1
    fieldsV1:
      f:status:
        f:completionTime: {}
        f:conditions: {}
        f:startTime: {}
        f:succeeded: {}
    manager: kube-controller-manager
    operation: Update
    time: "2023-01-12T20:16:10Z"
  name: runtime-manager-upgrade-job
  namespace: hptv-stgcloudpak
  ownerReferences:
  - apiVersion: ccs.cpd.ibm.com/v1beta1
    kind: CCS
    name: ccs-cr
    uid: a7f50f13-6ccc-4c85-a179-8d175392a2ee
  resourceVersion: "602040277"
  uid: 16297800-349c-4b01-8d77-4b5f6fd380bd
spec:
  activeDeadlineSeconds: 1200
  backoffLimit: 6
  completions: 1
  parallelism: 1
  selector:
    matchLabels:
      controller-uid: 16297800-349c-4b01-8d77-4b5f6fd380bd
  template:
    metadata:
      annotations:
        cloudpakId: eb9998dcc5d24e3eb5b6fb488f750fe2
        cloudpakInstanceId: a5304923-da2e-41d5-8d77-ea934d4108b2
        cloudpakName: IBM Cloud Pak for Data
        images: |
          runtime-manager-api@sha256: 4.5.3-1194
        productChargedContainers: All
        productCloudpakRatio: "1:1"
        productID: eb9998dcc5d24e3eb5b6fb488f750fe2
        productMetric: VIRTUAL_PROCESSOR_CORE
        productName: IBM Cloud Pak for Data Common Core Services
        productVersion: 4.5.3
      creationTimestamp: null
      labels:
        app.kubernetes.io/instance: runtime-base
        app.kubernetes.io/managed-by: runtime-base
        app.kubernetes.io/name: runtime-manager-upgrade-job
        component: runtime-manager-upgrade-job
        controller-uid: 16297800-349c-4b01-8d77-4b5f6fd380bd
        icpdsupport/addOnId: ccs
        icpdsupport/app: runtime-manager-upgrade-job
        job-name: runtime-manager-upgrade-job
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64
      containers:
      - command:
        - /runtime-manager
        - --upgrade
        env:
        - name: LOG_LEVEL
          value: INFO
        - name: RUNTIMES_DEPLOY_MODE
          value: CP4D
        - name: DEPLOYMENT_LOCATON
          value: cpd
        - name: SATELLITE_LOCATION_ENABLED
          value: "false"
        - name: CPD_UPGRADE_VERSION
          value: 4.5.3
        - name: NGINX_HOST_URL
          value: https://internal-nginx-svc.hptv-stgcloudpak.svc:12443
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: RTM_K8S_USER_AGENT
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        - name: CPD_SI_MOUNT_PATH
          value: /etc/cp4d/credentials/cpd-si
        image: cp.icr.io/cp/cpd/runtime-manager-api@sha256:8a9bbf0a780cf188b6b0f15d3d32aeafce7b9022f781d9d5c54f86b0c8490495
        imagePullPolicy: IfNotPresent
        name: runtime-manager-upgrade
        resources:
          limits:
            cpu: 150m
            memory: 192Mi
          requests:
            cpu: 15m
            memory: 64Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          privileged: false
          readOnlyRootFilesystem: false
          runAsNonRoot: true
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/cp4d/credentials/cpd-si
          name: cpd-si
          readOnly: true
      dnsPolicy: ClusterFirst
      restartPolicy: OnFailure
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: runtime-assemblies-operator
      serviceAccountName: runtime-assemblies-operator
      terminationGracePeriodSeconds: 0
      volumes:
      - name: cpd-si
        projected:
          defaultMode: 420
          sources:
          - secret:
              items:
              - key: service-id-credentials
                path: APP_ENV_CUSTOM_SERVICE_TO_SERVICE_AUTH_TOKEN
              name: wdp-service-id
status:
  completionTime: "2023-01-12T20:16:10Z"
  conditions:
  - lastProbeTime: "2023-01-12T20:16:10Z"
    lastTransitionTime: "2023-01-12T20:16:10Z"
    status: "True"
    type: Complete
  startTime: "2023-01-12T20:15:58Z"
  succeeded: 1
```
