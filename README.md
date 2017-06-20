# Monitor

[![Docker Repository on Quay.io](https://quay.io/repository/panubo/monitor/status "Docker Repository on Quay.io")](https://quay.io/repository/panubo/monitor)

## Features

- Provides `/register-result` executable for external check result submission.
- "Full" and "Lite" modes. Full mode runs the Sensu Client. In lite mode this container will run the monitoring-plugins.org ("check_*") commands, custom plugins or Sensu plugins and provide the results to the Sensu API. It does not depend on Rabbitmq transport. Rather it uses the Sensu `/results` API.

Lite mode requires the Sensu server to be configured with basic authentication on the `/results` API endpoint. This can be achieved by using an HTTP proxy.

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
  quay.io/panubo/monitor:latest
```

## Environment config (lite mode)

- `CHECK_COMMANDS` - checks to run default `check_disk check_load`.
- `MONITOR_MODE` - enable `lite` mode.
- `MONITOR_HOST`
- `MONITOR_USERNAME`
- `MONITOR_PASSWORD`
- ... others see `/monitor-run.sh`

## Usage Example (lite mode)

```bash
docker run --rm -t -i \
  -e MONITOR_MODE=lite \
  -e MONITOR_HOST=api.sensu.example.com \
  -e MONITOR_USERNAME=myuser \
  -e MONITOR_PASSWORD=mypassword \
  docker.io/panubo/monitor
```

## Known issues

- `check_disk` has [spurious errors](https://github.com/monitoring-plugins/monitoring-plugins/issues/847) when run from within a container.

## Status

Work in Progress.
