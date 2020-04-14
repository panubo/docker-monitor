# Monitor

Docker image containing the Sensu client with some standard checks and tools.

## Features

- Provides `/register-result` executable for external check result submission.
- "Full" and "Lite" modes. Full mode runs the Sensu Client. In lite mode this container will run the monitoring-plugins.org ("check_*") commands, custom plugins or Sensu plugins and provide the results to the Sensu API. It does not depend on Rabbitmq transport. Rather it uses the [Sensu `/results` API](https://sensuapp.org/docs/1.0/api/results-api.html#the-results-api-endpoint)\*.

\* Lite mode requires the Sensu server to be configured with basic authentication on the `/results` API endpoint. This can be achieved by using an HTTP proxy.

## Sensu Plugins

* sensu-plugins-aws
* sensu-plugins-cpu-checks
* sensu-plugins-disk-checks
* sensu-plugins-elasticsearch
* sensu-plugins-http
* sensu-plugins-kafka2
* sensu-plugins-kubernetes
* sensu-plugins-load-checks
* sensu-plugins-memory-checks
* sensu-plugins-postgres
* sensu-plugins-redis
* sensu-plugins-ssl

### From the checks folder

* check-btrfs.rb (Checks a BTRFS filesystem device usage)
* check-kafka-consumers.rb (Connects to Burrow and checks Kafka consumer status)
* check-lvmthin.rb (Checks LVM thin volumes data and meta data usage)
* check-redis-slaves.sh (Wrapper around the sensu-plugins-redis)

## Options

* `HOSTNAME` (required, but always set by Docker)
* `IPADDRESS` (optional, HOSTNAME is used if not set)
* `SENSU_CLIENT_SIGNATURE` (optional, see [Sensu Client Signature](https://sensuapp.org/docs/latest/reference/clients.html#client-signature))
* `SENSU_CLIENT_SUBSCRIPTIONS` (required, defaults to "test", comma separated list)
* `SENSU_PORT_5672_TCP_ADDR` (required, address of sensu server)
* `SENSU_SSL`
* `SENSU_CLIENT_CERT` (default "/etc/sensu/ssl/sensu.pem")
* `SENSU_CLIENT_KEY` (default "/etc/sensu/ssl/sensu-key.pem")
* `SENSU_RABBITMQ_CLIENT_USER` (default, "guest")
* `SENSU_RABBITMQ_CLIENT_PASS` (default, "guest")
* `SENSU_RABBITMQ_VHOST` (default, "/")

_The `SENSU_PORT_5672_TCP_ADDR` variable is named based on the legacy container links and may be changed in the future_

## Usage Example (full mode)

```bash
docker run --rm \
  --name sensu-client \
  --hostname $HOSTNAME \
  --privileged \
  --security-opt label:disable \
  -v /:/host/:ro -v /dev:/host/dev \
  -e SENSU_CLIENT_SUBSCRIPTIONS=node \
  -e SENSU_PORT_5672_TCP_ADDR=127.0.0.1 \
  docker.io/panubo/monitor full

# With SSL
docker run --rm \
  --name sensu-client \
  --hostname $HOSTNAME \
  --privileged \
  --security-opt label:disable \
  -v /:/host/:ro -v /dev:/host/dev \
  -v $(pwd)/../docker-sensu-aio/ssl:/etc/sensu/ssl \
  -e SENSU_CLIENT_SUBSCRIPTIONS=node \
  -e SENSU_PORT_5672_TCP_ADDR=127.0.0.1 \
  -e SENSU_SSL=true \
  -e SENSU_CLIENT_CERT=/etc/sensu/ssl/localhost.pem \
  -e SENSU_CLIENT_KEY=/etc/sensu/ssl/localhost-key.pem \
  docker.io/panubo/monitor full
```

## Environment config (lite mode)

- `CHECK_COMMANDS` - checks to run default `check-disk-usage check_load check_lvm`.
- `MONITOR_HOST`
- `MONITOR_USERNAME`
- `MONITOR_PASSWORD`
- ... others see `/monitor-run.sh`

## Usage Example (lite mode)

```bash
docker run --rm \
  --name sensu-client \
  --hostname $HOSTNAME \
  --privileged \
  --security-opt label:disable \
  -v /:/host/:ro -v /dev:/host/dev \
  -e MONITOR_HOST=api.sensu.example.com \
  -e MONITOR_USERNAME=myuser \
  -e MONITOR_PASSWORD=mypassword \
  docker.io/panubo/monitor lite
```

## Usage Example (register-result)

```
CHECK_NAME=acme
CHECK_OUTPUT="Acme service ran OK"
CHECK_STATUS=0
CHECK_TTL=4200 # Check will expire in 70min unless the service runs again.
docker exec monitor /register-result "${HOSTNAME}" "${CHECK_NAME}" "${CHECK_OUTPUT}" "${CHECK_STATUS}" "${CHECK_TTL}"
```

## Known issues

- `check_disk` has [spurious errors](https://github.com/monitoring-plugins/monitoring-plugins/issues/847) when run from within a container. (lite only)

## Developing

Development is performed on `master` branch and merged to the appropriate `release/x.x.x` branch.

To release an update:

1. Update the `BUILD_VERSION` in the `Dockerfile` and commit to master.
2. Merge master to the `release/x.x.x` branch.
3. Run `make git-release`
4. Run `make docker-release`
