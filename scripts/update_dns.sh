#!/bin/bash
# Cloudflare Dynamic DNS updater
# Detects the current public IP and updates the A records of the
# self-hosted services when it changes. Runs via cron.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env"

LAST_IP_FILE="$SCRIPT_DIR/.last_ip"

IP=$(curl -s https://api.ipify.org)

# Nothing to do if the IP hasn't changed since the last run
if [[ -f "$LAST_IP_FILE" && "$(cat "$LAST_IP_FILE")" == "$IP" ]]; then
    exit 0
fi

update_record() {
    local record_id="$1"
    local record_name="$2"
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$record_id" \
        -H "Authorization: Bearer $AUTH_KEY" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$IP\",\"ttl\":60,\"proxied\":false}" \
        > /dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') updated $record_name -> $IP"
}

update_record "$RECORD_ID_JELLYFIN" "$RECORD_NAME_JELLYFIN"
update_record "$RECORD_ID_VAULT"    "$RECORD_NAME_VAULT"
update_record "$RECORD_ID_IMMICH"   "$RECORD_NAME_IMMICH"

echo "$IP" > "$LAST_IP_FILE"
