## What's an orphaned catalog?
An orphaned catalog is one where all the users that were members of that catalog no longer exist, or where all the users of that catalog have been removed as members.  Because only members of a catalog can access that catalog, such a catalog is no longer accessible -- at all -- by anyone.

## How to Recover an Orphaned Catalog
### Prerequisite
1. A non-user service id access token to use through-out this process
2. The user-id of the user you'll assign to the orphaned catalog as the new administrative user.

### The steps to follow
There are three steps you need to follow to recover an orphaned catalog:
1. Get get a non-user service id bearer token to use through-out this process.
2. Pick an existing user that will become the new administrator (owner) of that catalog and get that user's IAM-ID (that's the internal id used by IBM Catalog Asset Manager).
3. Call the CAMS API to assign that user to the orphaned catalog as an administrator.

**Step 1: Get the non-user service id token**
- For this step you need to be logged onto OpenShift:
```
oc login <cluster_address> -u <openshift user> -p <openshift user's password>
```
- Get the serviceId token from the wdp-service-id secret. 

- Now get a bearer token for that service id.  This is documented in the [IBM Cloud Pak for Data Platform API Authentication Documentation](https://cloud.ibm.com/apidocs/cloud-pak-data/cloud-pak-data-5.0.0#authentication).

**Step 2: Retrieve the current uid of the desired new administrator user.**

You'll need to know the user's username.  Ask them for it if you don't already know it.  It's the name they use when they log into IBM CloudPak for Data.  Once you have the user's name, call the [Get User By Name](https://cloud.ibm.com/apidocs/cloud-pak-data/cloud-pak-data-5.0.0#getuserbyname) API.  You'll need the authorization token of a user who has the privileges to access the user management information for that user.  Try the one you got from Step 1 above.  Or, get one for the very user you'll be adding as the administrator of the orphaned catalog by calling [IBM Cloud Pak for Data Platform API Authentication Documentation](https://cloud.ibm.com/apidocs/cloud-pak-data/cloud-pak-data-5.0.0#authentication) using that user's userid/password combination.
You'll have a response that looks something like this:
```
{
  "authenticator": "external",
  "uid": 1000331015,     <---- look for this
  "created_timestamp": 1655162210393,
...
}
```

**Step 3: Assign the User as Admin for the Catalog**

Here's the information you'll have ready at hand to proceed with this step:
1. An authorization token to perform the API call assigning the user as the orphaned catalog's admin (from Step 1).
2. The user-id of the user you'll be assigning as the administrator.
3. The catalog-id (i.e. the GUID) of the orphaned catalog.
Now you are ready to go.  This can be done by using the following API call.
This is done via the [POST /v2/catalogs/{catalog_id}/members](https://cloud.ibm.com/apidocs/data-ai-common-core-cpd/data-ai-common-core-cpd-5.1.0#addnewmembersv2) api call.

## Validate catalog is accessible
After adding the new admin uid as a member of the catalog (step 4), you should be able to login to the UI as that user and access the catalog, browse assets, make further changes to access control, or delete the catalog.
