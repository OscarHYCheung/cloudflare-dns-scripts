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

# Check if cloudflare.credentials.json exists
if [ ! -f "$cfCredentialsFile" ]; then
  echo "${cfCredentialsFile} not found."
  exit 1
fi

# Get the zoneId and apiToken from cloudflare.credentials.json
zoneId=$(jq -r ".[\"$domainName\"].zoneId" $cfCredentialsFile)
apiToken=$(jq -r ".[\"$domainName\"].apiToken" $cfCredentialsFile)
if [ "$zoneId" == "null" ] || [ "$apiToken" == "null" ]; then
  echo "Zone ID or API Token not found in cloudflare.credentials.json."
  exit 1
fi

# Request the DNS record ID for the domainName from Cloudflare
recordType="A"
response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records?type=$recordType" \
  -H "Authorization: Bearer $apiToken" \
  -H "Content-Type: application/json")

# Check if the response contains an error
if [[ $(echo "$response" | jq -r '.success') == "false" ]]; then
  echo "Failed to get DNS record ID for $domainName."
  echo "Error: $(echo "$response" | jq -r '.errors[0].message')"
  exit 1
fi

# Save to "${domainName}.id.json" and print to console
echo "$response" >"${srcPath}/${domainName}.id.json"
echo "The DNS record ID for $domainName is $(jq -r '.result[0].id' "${domainName}.id.json")."
