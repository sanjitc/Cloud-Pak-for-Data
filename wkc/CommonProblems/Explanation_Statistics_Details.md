
# Explanation of statistics information in the MDI job log
```
    "statistics" : {
      "discovered" : 53356,
      "discovered_with_children" : 53356,
      "submit_succ" : 53356,
      "submit_fail" : null,
      "create_succ" : 53355,
      "create_fail" : null,
      "create_retry" : null,
      "create_abort" : null,
      "create_skip" : 1,
      "create_succ_with_children" : 53355,
      "create_fail_with_children" : null,
      "details" : null,
      "number_of_new_assets" : 53149,
      "number_of_updated_assets" : 0,
      "number_of_removed_assets" : 0
    }
```

## Details of the numbers unser statistics section:
### Discovery/Read phase :
- **discovered** : number of discovered asset from the data source
- **submit_succ** : number of asset successfully submitted for creation
- **submit_fail** : number of asset failed to submit for creation

### In get detail/write phase:
- **create_succ** : number of asset successfully created/updated (This number includes assets newly added, updated, or with no changes)
- **create_fail** : number of asset failed to be created/updated
- **create_retry** : number of asset retried for assets creation
- **create_abort** : number of asset submitted however then aborted for creation
- **create_skip** : number of asset submitted however then skipped for creation

### Calculated during post-process:
- **number_of_new_assets** : The number of assets imported newly since last importing
- **number_of_updated_assets** : The number of assets updated since last importing
- **number_of_removed_assets** : The number of assets removed since last importing

## There are some counts "with_children":
There are some "xxx_with_children". That number is usually same as "xxx", but in case of asset types which has descendants (ex. ibm_bi_report, ibm_logical_model, ibm_physical_model), "xxx" only contains number of top level assets, and "xxx_with_children" contains number of top level and descendant assets.
These child assets can be importing from Manta. In such case, the "_with_children" count would contain top level and its descendants’ assets.
- **discovered_with_children** : number of discovered asset including child assets from the data source
- **create_succ_with_children** : number of assets were successfully created including child assets
- **create_fail_with_children** : number of assets failed to be created including child assets
