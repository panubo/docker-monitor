#!/usr/bin/env bash

# Wrapper to locate the check plugin

PLUGIN=$1
shift

if [ "${PLUGIN}" == "" ]; then
    echo "Usage: run_check <plugin>"
    exit 128
fi

if [ -x "/lite/plugins/${PLUGIN}" ]; then
    # Our custom plugins
    exec /lite/monitor-run.sh /lite/plugins/${PLUGIN} "$@"
elif [ -x "/usr/lib/nagios/plugins/${PLUGIN}" ]; then
    # monitoring-plugins-basic
    exec /lite/monitor-run.sh /usr/lib/nagios/plugins/${PLUGIN} "$@"
elif [ -x "/opt/sensu/embedded/bin/${PLUGIN}.rb" ]; then
    # Sensu plugins
    CHECK_NAME=${PLUGIN} exec /lite/monitor-run.sh /opt/sensu/embedded/bin/${PLUGIN}.rb "$@"
else
    echo "Plugin ${PLUGIN} not found."
    exit 3  # unknown
fi
