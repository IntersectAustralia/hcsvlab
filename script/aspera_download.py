'''
HCSvLab Aspera download python script

Sample usage:
  python aspera_download.py --key API_KEY --item_list_id 34 --destination ~/Downloads

Be sure to fill in API_URL, ASCP_COMMAND and ASCP_KEY to the correct values on your machine

API_URL: Alveo host you are using; QA URL, Staging URL etc.
ASCP_COMMAND: link to the ascp binary, differs on different systems
ASCP_KEY: link to the openssh key that comes with the aspera connect plugin

'''

import os
import argparse
import urllib2
import urllib
import json
import tempfile
import subprocess

API_URL = "https://alveo-qa.intersect.org.au"
ASCP_COMMAND = "ascp"
ASCP_KEY = "~/asperaweb_id_dsa.openssh"

def get_arguments():
  parser = argparse.ArgumentParser()
  parser.add_argument('--key', required=True, action="store", type=str, help="Alveo API key")
  parser.add_argument('--item_list_id', required=True,  action="store", type=int, help="Item list id")
  parser.add_argument('--destination', required=True,  action="store", type=str, help="Download destination")
  args = parser.parse_args()
  return args

def perform_transfer(transfer_spec, destination):
  spec = json.loads(transfer_spec)["transfer_spec"]

  args = [ASCP_COMMAND]
  args.extend(["-i", ASCP_KEY])
  args.extend(["-O", str(spec["fasp_port"])])
  args.extend(["-P", str(spec["ssh_port"])])
  args.extend(["-l", str(spec["target_rate_kbps"])])
  args.extend(["-y", "1"])
  args.extend(["-t", str(spec["http_fallback_port"])])
  args.extend(["--policy", spec["rate_policy"]])
  args.extend(["--mode", "RECV"])
  args.extend(["--host", spec["remote_host"]])
  args.extend(["--user", spec["remote_user"]])

  with tempfile.NamedTemporaryFile(delete=False) as temp:
    for path in spec["paths"]:
      temp.write(path["source"] + "\n")
      temp.write(path["destination"] + "\n")

    args.extend(["--file-pair-list", temp.name])
    args.append(destination)
    # print(args)

    token = spec["token"]
    # print(token)

    env = os.environ.copy()
    env["ASPERA_SCP_TOKEN"] = token

    print("export ASPERA_SCP_TOKEN=" + token)
    print(" ".join(args))

    subprocess.call(" ".join(args), env=env, shell=True)

def perform_api_download(key, item_list_id, destination):
  headers = {'X-API-KEY': key, 'Accept': 'application/json'}
  url = API_URL + '/item_lists/' + str(item_list_id) + '/aspera_transfer_spec'
  
  req = urllib2.Request(url, data={}, headers=headers)

  try:
    opener = urllib2.build_opener(urllib2.HTTPHandler())
    response = opener.open(req)
  except urllib2.HTTPError as err:
    raise APIError(err.code, err.reason, "Error accessing API")

  transfer_spec = response.read()
  perform_transfer(transfer_spec, destination)


if __name__ == '__main__':
  args = get_arguments()
  perform_api_download(args.key, args.item_list_id, args.destination)