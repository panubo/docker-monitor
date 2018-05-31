#!/usr/bin/env bash

set -e
[[ "${DEBUG:-false}" == 'true' ]] && set -x

mount --rbind /host/dev /dev || true

MODE="${1-full}"

if [[ "${MODE}" == "full" ]]; then
  echo "Full mode"
  for item in /etc/sensu/config.json.tmpl /etc/sensu/conf.d/client.json.tmpl; do
    gomplate < ${item} > ${item/%\.tmpl/}
    [[ "${DEBUG:-false}" == 'true' ]] && cat ${item/%\.tmpl/}
  done
  exec gosu sensu /opt/sensu/bin/sensu-client -c /etc/sensu/config.json -d /etc/sensu/conf.d -e /etc/sensu/extensions -L ${LOGLEVEL}
elif [[ "${MODE}" == "lite" ]]; then
  echo "Lite Mode is no longer supported"
  exit 1
else
  echo "Running command ${@}"
  exec "${@}"
fi
