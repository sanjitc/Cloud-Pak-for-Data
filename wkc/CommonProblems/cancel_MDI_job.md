# Cancel Medatadata Import job forcefully



1. Get accessToken -
```
curl -k -X GET https://<host>/v1/preauth/validateAuth \
    -H "Accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --user <username>:<password>
```
Note down the token


2. Save the below json into a file eg., replace.json
```
[{
 "op":"replace",
 "path":"/entity/job_run/state",
 "value":"Canceled"
}]
```

3. Cancel the job - Use the token from Step 1
```
curl -k -X PATCH "https://<host>/v2/jobs/${jobid}/runs/${jobrunid}?project_id=${projectid}" \
-H "content-type: application/json" \
-H "Authorization: Bearer <token>" \
-d @replace.json
```
