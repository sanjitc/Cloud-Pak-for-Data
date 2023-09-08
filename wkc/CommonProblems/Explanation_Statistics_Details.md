
# Explanation of statistics information in the MDI job log

![image](https://github.com/sanjitc/Cloud-Pak-for-Data/assets/17136230/4e1e641b-76b8-4619-b496-89f4997c24d3)


## Details of the numbers unser statistics section:

- **discovered** : number of discovered asset from the data source
- **submit_succ** : number of asset successfully submitted to process
- **submit_fail** : number of asset failed to submitted to process
- **create_succ** : number of asset successfully processed (This number includes assets newly added, updated, or with no changes)
- **create_fail** : number of asset failed to process
- **create_retry** : number of asset retried to process
- **create_abort** : number of asset stopped to process
- **create_skip** : number of asset skipped to process

There are some "xxx_with_children". That number is usually same as "xxx", but in case of asset types which has descendants (ex. ibm_bi_report, ibm_logical_model, ibm_physical_model), "xxx" only contains number of top level assets, and "xxx_with_children" contains number of top level and descendant assets.
- **discovered_with_children** : number of discovered asset and its descendant assets from the data source
- **create_succ_with_children** : number of asset and its descendant assets successfully processed
- **create_fail_with_children** : number of asset failed to process and its descendant assets
