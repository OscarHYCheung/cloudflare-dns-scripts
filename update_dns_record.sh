#!/bin/bash

# Get and check the domainName argument
domainName="$1"
if [ -z "$domainName" ]; then
  echo "Domain name not provided. Usage: $0 <domainName>"
  exit 1
fi

# Get the path to the script directory
scrPath=$(dirname "$(realpath "$0")")

# Check if cloudflare.credentials.json exists
cfCredentialsFile="${scrPath}/cloudflare.credentials.json"
if [ ! -f "$cfCredentialsFile" ]; then
  echo "${cfCredentialsFile} not found."
  exit 1
fi

# Get the DNS record ID from the JSON file
recordId=$(jq -r '.result[0].id' "${cfCredentialsFile}/${domainName}.id.json")
if [ "$recordId" == "null" ]; then
  echo "DNS record ID not found in ${cfCredentialsFile}/${domainName}.id.json."
  exit 1
fi

# Get the zoneId and apiToken from cloudflare.credentials.json
zoneId=$(jq -r ".[\"$domainName\"].zoneId" ${cfCredentialsFile})
apiToken=$(jq -r ".[\"$domainName\"].apiToken" ${cfCredentialsFile})
if [ "$recordId" == "null" ] || [ "$zoneId" == "null" ] || [ "$apiToken" == "null" ]; then
  echo "Record ID, Zone ID, or API Token not found in ${cfCredentialsFile}."
  exit 1
fi

# Get last IP address stored
ipFile="${scrPath}/${domainName}.ip.json"
if [ -f "$ipFile" ]; then
  lastIp=$(jq -r '.ip' "$ipFile")
else
  lastIp=""
fi

# Get current IP address and compare with the last IP address
currentIp=$(curl -s https://httpbin.org/ip | jq -r '.origin')
if [ "$currentIp" == "$lastIp" ]; then
  echo "IP has not changed. No update needed."
  exit 0
fi

# Update the Cloudflare DNS record with the new IP address when it has changed
echo "IP has changed to $currentIp. Updating Cloudflare..."
updateResponse=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$recordId" \
  -H "Authorization: Bearer $apiToken" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$domainName\",\"content\":\"$currentIp\",\"ttl\":1,\"proxied\":true}")

# Check if the update was successful
if [[ $(echo "$updateResponse" | jq -r '.success') == "true" ]]; then
  # Save the new IP address to the file if the update was successful
  echo "Cloudflare DNS record for $domainName updated successfully."
  echo "{\"ip\":\"$currentIp\"}" >"$ipFile"
else
  # Print the response if the update failed
  echo "Failed to update Cloudflare DNS record for $domainName."
  echo "Response: $updateResponse"
fi
