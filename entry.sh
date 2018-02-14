#!/usr/bin/env bash

set -e
[[ "${DEBUG:-false}" == 'true' ]] && set -x

mount --rbind /host/dev /dev || true

if [[ "${1}" == "full" ]]; then
  echo "Full mode"
  # exec /usr/local/bin/voltgrid.py /opt/sensu/bin/sensu-client -c /etc/sensu/config.json -d /etc/sensu/conf.d -e /etc/sensu/extensions -L warn
  for item in /etc/sensu/config.json.tmpl /etc/sensu/conf.d/client.json.tmpl; do
    gomplate < ${item} > ${item/%\.tmpl/}
    [[ "${DEBUG:-false}" == 'true' ]] && cat ${item/%\.tmpl/}
  done
  exec gosu sensu /opt/sensu/bin/sensu-client -c /etc/sensu/config.json -d /etc/sensu/conf.d -e /etc/sensu/extensions -L ${LOGLEVEL}
elif [[ "${1}" == "lite" ]]; then
  echo "Lite Mode"
  # Replace register-result with lite version
  rm -f /register-result
  mv /lite/register-result.sh /register-result
  # Run lite entry.sh
  exec /lite/entry.sh /lite/runner.sh
else
  echo "Running command ${@}"
  exec "${@}"
fi
