#!/usr/bin/env bash

set -e

# Check redis slaves are attached to a master. If node is a slave then return ok

# Defaults
REDIS_PORT=${REDIS_PORT:='6380'}
REDIS_HOST=${REDIS_HOST:='docker.local'}

# Check Commands
SLAVES=$(check-redis-info.rb -h ${REDIS_HOST} -K connected_slaves -p ${REDIS_PORT} | sed 's/[^0-9]*//g')
CHECK_SLAVE=$(check-redis-slave-status.rb -p ${REDIS_PORT} -h ${REDIS_HOST})

function critical() {
    echo "CRITICAL: $@"
    exit 2
}
function ok() {
    echo "OK: $@"
    exit 0
}

# Master Node
if [ "${CHECK_SLAVE}" == "RedisSlaveCheck OK: This redis server is master" ]; then
    [ "${SLAVES}" -lt 1 ] && critical "No slaves connected to master!" || ok "${SLAVES} slaves connected to this master."
fi

# Slave Node
if [ "${CHECK_SLAVE}" == "RedisSlaveCheck OK: The redis master links status is up!" ]; then
    ok "Slave node."
fi

# Should never exit here
critical "Monitor script failure."
