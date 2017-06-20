#!/usr/bin/env bash

set -e
[ "${DEBUG:-false}" == 'true' ] && set -x

# Defaults
: ${MONITOR_MODE:='full'}

mount --rbind /host/dev /dev || true

if [ "$MONITOR_MODE" == "full" ]; then
  echo "Full mode"
  echo "Running command $@"
  exec "$@"
else
  echo "Lite Mode"
  # Replace register-result with lite version
  rm -f /register-result
  mv /lite/register-result.sh /register-result
  # Run lite entry.sh
  exec /lite/entry.sh /lite/runner.sh
fi
