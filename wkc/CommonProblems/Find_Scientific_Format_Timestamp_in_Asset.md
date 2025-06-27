## /v3/search couldn't fine the the asset due to timestamp in the scientific format, instead of regular Epoch format. 

- Search query to fetch problematic assets:
```
curl -X 'POST' \
  'https://${host}/v2/asset_types/data_asset/search?project_id=e${project_id}&hide_deprecated_response_fields=false' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer ${token}' \
  -H 'Content-Type: application/json' \
  -d '{
  "query": "*:* AND data_profile.completed_date:[* TO 176*]",
  "limit": 100,
  "include": "entity"
}'
```
Payload:
```
{
  "query": "*:* AND data_profile.completed_date:[* TO 17*]",
  "limit": 100,
  "include": "entity"
}
```

- Update the timestamp with
```
curl -X 'PATCH' \
  'https://{host}/v2/assets/<asset id>/attributes/data_profile?catalog_id=<catalog id>' \
  -H 'accept: */*' \
  -H 'Authorization: Bearer {token}' \
  -H 'Content-Type: application/json' \
  -d '[
  { "op": "replace", "path": "/<value of "entity.data_profile" path i.e., 468bf561-6c90-468a-9c19-ee225fc6bb98>/entity/data_profile/execution/completed_date", "value": "<A time stamp value i.e., 2022-04-25T17:32:58.653Z>" }
]'
```
