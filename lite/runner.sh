#!/usr/bin/env bash

# Run the plugins

[ "${DEBUG:-false}" == 'true' ] && set -x

# Defaults
: ${CHECK_COMMANDS:='check-disk-usage check_load check_lvm'}
: ${CHECK_TTL:='900'}
: ${CHECK_MIN_INTERVAL:='300'}

# exit cleanly
trap "{ exit; }" INT

while true; do
    echo "Running Plugins:"
    for P in ${CHECK_COMMANDS}; do
        [ -f "/lite/conf/${P}.cfg" ] && source /lite/conf/${P}.cfg || true
        /lite/run-plugin.sh ${P} ${ARGS}
        unset ARGS
    done

    sleep $CHECK_MIN_INTERVAL
done
