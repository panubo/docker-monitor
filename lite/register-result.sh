#!/usr/bin/env bash

set -e

function usage() {
    echo "Error: Usage <register-result> <client> <name> <output> <status> <ttl>"
    exit 2
}

# Source config
source /etc/monitor-run.conf

# Checks
[ -z "$4" ] && usage

# Defaults
: ${CHECK_SOURCE:="${1}"}
: ${CHECK_NAME:="${2}"}
: ${CHECK_OUTPUT:="${3}"}
: ${CHECK_STATUS:="${4}"}
: ${CHECK_TTL:="${5:-'90000'}"}

# Construct JSON result
JSON=$(
  jq -n -c -M \
    --arg source "$CHECK_SOURCE" \
    --arg name "$CHECK_NAME" \
    --arg output "$CHECK_OUTPUT" \
    --arg status "$CHECK_STATUS" \
    --arg ttl "$CHECK_TTL" \
    '{"source": $source, "name": $name, "output": $output, "status": $status|tonumber, "ttl": $ttl|tonumber}'
  )
# Post result to API
curl -s -X POST \
 -H 'Content-Type: application/json' \
 -d "${JSON}" \
 https://${MONITOR_USERNAME}:${MONITOR_PASSWORD}@${MONITOR_HOST}/results > /dev/null
