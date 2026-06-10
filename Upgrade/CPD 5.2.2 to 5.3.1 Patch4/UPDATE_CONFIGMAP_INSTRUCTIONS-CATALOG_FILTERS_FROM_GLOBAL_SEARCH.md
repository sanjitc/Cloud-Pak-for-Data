# Instructions: Update ccs-features-configmap

## Overview

The `enableCatalogFiltersFromGS` feature flag determines where catalog asset filters are retrieved from. When enabled, the catalog will populate asset filter options from **Global Search** instead of CAMS.

### Benefits of Enabling This Feature

- The filters will populate faster compared to CAMS

## Objective

Update the `ccs-features-configmap` ConfigMap in the `<namespace>` namespace to set `enableCatalogFiltersFromGS` to `true`, enabling catalog filters to be populated from Global Search.

**Note**: Replace `<namespace>` with your actual namespace (e.g., `wkc`).

## Prerequisites
- Access to the OpenShift cluster with appropriate permissions
- `oc` CLI tool installed and configured
- Logged into the cluster: `oc login`

## Method 1: Using `oc patch` (Recommended - Quick Update)

This method directly updates the specific field without editing the entire ConfigMap:

```bash
oc patch configmap ccs-features-configmap -n <namespace> \
  --type merge \
  -p '{"data":{"enableCatalogFiltersFromGS":"true"}}'
```

### Force a CCS CR reconciliation:
```bash
oc patch ccs ccs-cr -n <namespace> --type merge -p '{"spec":{"forceReconcile":"true"}}'
oc patch ccs ccs-cr -n <namespace> --type merge -p '{"spec":{"forceReconcile":""}}'
```

### Verify the change:
```bash
oc get configmap ccs-features-configmap -n <namespace> -o jsonpath='{.data.enableCatalogFiltersFromGS}'
```

Expected output: `true`

## Method 2: Using `oc edit` (Interactive)

This method opens the ConfigMap in your default editor for manual editing:

```bash
oc edit configmap ccs-features-configmap -n <namespace>
```

1. Locate the `data` section
2. Find the line: `enableCatalogFiltersFromGS: 'false'`
3. Change it to: `enableCatalogFiltersFromGS: 'true'`
4. Save and exit the editor
5. The changes will be applied automatically

### Force a CCS CR reconciliation:
```bash
oc patch ccs ccs-cr -n <namespace> --type merge -p '{"spec":{"forceReconcile":"true"}}'
oc patch ccs ccs-cr -n <namespace> --type merge -p '{"spec":{"forceReconcile":""}}'
```

## Verification Steps

After updating, verify the ConfigMap was updated successfully:

```bash
# View the entire ConfigMap
oc get configmap ccs-features-configmap -n <namespace> -o yaml

# View only the data section
oc get configmap ccs-features-configmap -n <namespace> -o jsonpath='{.data}' | jq

# View specific field
oc get configmap ccs-features-configmap -n <namespace> -o jsonpath='{.data.enableCatalogFiltersFromGS}'
```

## Important Notes

1. **Restart Pods**: `portal-catalog` pods will restart automatically after reconciliation is done. Here is a way to restart the pod manually
   ```bash
   # List the portal-catalog deployment
   oc get deployment portal-catalog -n <namespace>
   
   # View deployment details
   oc describe deployment portal-catalog -n <namespace>
   
   # Restart the portal-catalog deployment to pick up the new configuration
   oc rollout restart deployment/portal-catalog -n <namespace>
   
   # Verify the restart is complete
   oc rollout status deployment/portal-catalog -n <namespace>
   ```

2. **Permissions**: Ensure you have the necessary permissions to edit ConfigMaps in the `<namespace>` namespace.

3. **Backup**: Before making changes, consider backing up the current ConfigMap:
   ```bash
   oc get configmap ccs-features-configmap -n <namespace> -o yaml > ccs-features-configmap-backup.yaml
   ```

## Rollback

If you need to revert the change:

```bash
oc patch configmap ccs-features-configmap -n <namespace> \
  --type merge \
  -p '{"data":{"enableCatalogFiltersFromGS":"false"}}'
```

Or restore from backup:
```bash
oc apply -f ccs-features-configmap-backup.yaml
```

## Troubleshooting

If the update fails:

1. Check your permissions:
   ```bash
   oc auth can-i update configmap -n <namespace>
   ```

2. Verify the ConfigMap exists:
   ```bash
   oc get configmap ccs-features-configmap -n <namespace>
   ```

3. Verify the environment variable in the pod:
   ```bash
   oc exec -it portal-catalog-584f8b6bcb-724ps -n ikc -- bash
   
   env | grep -i filter
   FEATURE_CATALOG_FILTERS_FROM_GLOBAL_SEARCH=true
   ```