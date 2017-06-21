#!/usr/bin/env bash

# LICENSE: MIT License, Copyright (c) 2017 Volt Grid Pty Ltd
# Capture output and error level of run command and pass that to the monitor service

[ "${DEBUG:-false}" == 'true' ] && set -x

# Checks
[ -z "$1" ] && echo "Error:  Usage monitor-run.sh <command> <args>" && exit 128

# Defaults
: ${OUTPUT_LINES:=10}
: ${CHECK_SOURCE:=$(hostname)}
: ${CHECK_TTL:='90000'}
: ${CHECK_NAME:=$(basename $1)}
: ${CHECK_OUTPUT:='no output'}

set -o pipefail

exec 5>&1
CHECK_OUTPUT=$(( # Capture output
"$@"
) 2>&1 | tee >(cat - >&5))
CHECK_STATUS=$?
exec 5>&-

# Limit CHECK_STATUS
[ "$CHECK_STATUS" -gt "2" ] && CHECK_STATUS=2 || true

# workaround for /opt/bin/monitor-run.sh: line 25: /usr/bin/docker: Argument list too long
# TODO: pass in the result from stdin using - as the CHECK_OUTPUT value
if [ $(echo "${CHECK_OUTPUT}" | wc -l) -gt ${OUTPUT_LINES} ]; then
    LINES=$(expr $OUTPUT_LINES / 2)
    HEAD=$(echo "${CHECK_OUTPUT}" | head -n ${LINES})
    TAIL=$(echo "${CHECK_OUTPUT}" | tail -n ${LINES})
    CHECK_OUTPUT=$(echo -e "${HEAD} \n ----- output truncated ----- \n ${TAIL}")
fi

source /etc/monitor-run.conf

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
