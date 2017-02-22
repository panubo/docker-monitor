# Monitor

[![Docker Repository on Quay.io](https://quay.io/repository/panubo/monitor/status "Docker Repository on Quay.io")](https://quay.io/repository/panubo/monitor)

## Status

Work in Progress

## Usage

```
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
