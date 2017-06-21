#!/usr/bin/env bash

# Fail on errors
set -e
[ "${DEBUG:-false}" == 'true' ] && set -x

# Tests
[ -z "$MONITOR_HOST" ] && echo "Error: MONITOR_HOST not set" && exit 128 || true
[ -z "$MONITOR_USERNAME" ] && echo "Error: MONITOR_USERNAME not set" && exit 128 || true
[ -z "$MONITOR_PASSWORD" ] && echo "Error: MONITOR_PASSWORD not set" && exit 128 || true

# write out config for monitor-run
(
echo "MONITOR_HOST=\"${MONITOR_HOST}\""
echo "MONITOR_USERNAME=\"${MONITOR_USERNAME}\""
echo "MONITOR_PASSWORD=\"${MONITOR_PASSWORD}\""
) > /etc/monitor-run.conf

# Start runner.sh
exec "$@"
