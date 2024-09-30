### 1. Installing the IBM Cloud Pak for Data command-line interface
(CPD documentation: https://www.ibm.com/docs/en/cloud-paks/cp-data/4.8.x?topic=workstation-installing-cloud-pak-data-cli) 
1.1. Download cpd-cli Version 13.1.6 for Linex Enterprise Edition - https://github.com/IBM/cpd-cli/releases
```
wget https://github.com/IBM/cpd-cli/releases/download/v13.1.6/cpd-cli-linux-EE-13.1.6.tgz
```
1.2 Extract the contents of the `cpd-cli` package.
```
tar xzvf cpd-cli-linux-EE-13.1.6.tgz
```
1.3. Set necessary environment variables to run `cpd-cli`.
```
export PATH=<fully-qualified-path-to-the-cpd-cli>:$PATH

```

### 2. Collecting information required to install IBM Cloud Pak for Data
2.1. Obtaining your IBM entitlement API key for IBM Cloud Pak for Data
(Container software library on My IBM: https://myibm.ibm.com/products-services/containerlibrary)

2.2. Determining which IBM Cloud Pak for Data components to install
```
cert-manager,wkc,
```
