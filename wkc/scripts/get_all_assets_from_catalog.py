# Python script to dump all assets from the catalog. You need to update <CPD URL>, <USER NAME>, <PASSWORD>, <CATALOG ID> values. 
# Then run it as "python scriptfilenane.py"

import json
import warnings

from requests import Session, HTTPError
from subprocess import PIPE, Popen
from pprint import pprint

warnings.filterwarnings('ignore')

def scanCatalogDataAssets(catalog_id):
 session = Session()
 catalog_assets = []
 command = """curl -k -X POST https://<CPD URL>/icp4d-api/v1/authorize -H 'cache-control: no-cache' -H 'content-type: application/json' -d '{"username":"<USER NAME>", "password":"<PASSWORD>"}' 2> /dev/null| jq -r '.token'"""
 out = Popen(command, shell=True, stdout=PIPE)
 token = str(out.communicate()[0], 'UTF-8').strip("\n")
 headers = {"Authorization": f"Bearer {token}"}
 url = f"https://<CPD URLL>/v2/asset_types/data_asset/search?catalog_id={catalog_id}"

 def append_remaining_assets(payload={"query": "*:*", "limit": 200}):
  try:
   response = session.post(
     url,
     headers=headers,
     json=payload,
     verify=False)
   response.raise_for_status()
   res = response.json()
   catalog_assets.extend(res["results"])
   if "next" in res:
    append_remaining_assets(res["next"])
  except HTTPError as err:
   print(f"An HTTP error occurred: {err}")
   return
  except Exception as err:
   print(f"Other error occurred: {err}")
   return
 append_remaining_assets()
 pprint(catalog_assets)
 print(f"Number of assets returned: {len(catalog_assets)}")
 return catalog_assets

scanCatalogDataAssets("<CATALOG ID>")
