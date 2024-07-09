# Cloudflare DNS Record Scripts

This repository contains 2 scripts that can be used to fetch DNS record IDs from Cloudflare for a given domain, and update the A record for the given domain to current IP address.

## Prerequisites

- **jq**: This script uses `jq` for parsing JSON. Ensure you have `jq` installed on your system.
- **curl**: The script uses `curl` to make requests to the Cloudflare API. Ensure `curl` is installed.

## Setup

1. **Cloudflare API Token and Zone ID**: You need to have a Cloudflare API token and the Zone ID for the domain you wish to query. These should be stored in a file named `cloudflare.credentials.json` in the same directory as the script. The format of the file should be:

```json
{
  "<domainName>": {
    "zoneId": "<zoneId>",
    "apiToken": "<apiToken>"
  }
}
```

The API token should have the permission to edit the DNS records of the corresponding zone.

2. **A Record Name**: The script assumes that there is an A record already created in the Cloudflare. And you will need to use the name of the DNS record, normally the domain name.

## Usage

### Fetch DNS Record ID

To fetch the DNS record ID for the given domain, run the following command:

```bash
./get_dns_record_id.sh <domainName>
```

The script will save the DNS record ID in a file named `<domainName>.id.json`, and this file will be used by the update script.

### Update A Record

To update the A record for the given domain to the current IP address, run the following command:

```bash
./update_dns_record.sh <domainName>
```

Please ensure you run the `get_dns_record_id.sh <domainName>` script successfully before, which will create the `<domainName>.id.json` file.

### Update Periodically

You can use a cron job to update the A record periodically. For example, to update the A record every 5 minutes, add the following line to your crontab using `crontab -e`:

```bash
*/5 * * * * /path/to/update_dns_record.sh <domainName>
```

If the script is working as expected, it will only send requests to the Cloudflare API when the IP address has changed. So that it should be fine to run it even every minute.
