FROM docker.io/debian:jessie

MAINTAINER Tim Robinson <tim@panubo.com>

ENV SENSU_VERSION 1.0.0
ENV SENSU_PKG_VERSION 1

# Some dependencies
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get -y install curl sudo bc python-jinja2 lvm2 btrfs-tools apt-transport-https && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Setup sensu package repo & Install Sensu
RUN export DEBIAN_FRONTEND=noninteractive && \
  curl https://sensu.global.ssl.fastly.net/apt/pubkey.gpg | apt-key add - && \
  echo "deb     https://sensu.global.ssl.fastly.net/apt jessie main" | tee /etc/apt/sources.list.d/sensu.list && \
  apt-get update && \
  apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  echo "EMBEDDED_RUBY=true" > /etc/default/sensu

RUN export VOLTGRID_PIE_VERSION=1.0.6; curl -L https://github.com/voltgrid/voltgrid-pie/archive/v${VOLTGRID_PIE_VERSION}.tar.gz \
  | tar -C /usr/local/bin --strip-components 1 -zxf - voltgrid-pie-${VOLTGRID_PIE_VERSION}/voltgrid.py

# Install lite requirements
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y curl monitoring-plugins-basic jq python && \
    apt-get -y autoremove && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY lite /lite/

# Install some plugins/checks
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y build-essential && \
  /opt/sensu/embedded/bin/gem install \
  sensu-plugins-disk-checks \
  sensu-plugins-memory-checks \
  sensu-plugins-load-checks \
  sensu-plugins-kubernetes \
  sensu-plugins-ssl \
  sensu-plugins-aws \
  sensu-plugins-http \
  filesize \
  --no-rdoc --no-ri && \
  apt-get remove -y build-essential && apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH=/opt/sensu/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TMPDIR=/var/tmp HOME=/opt/sensu
ENV LOGLEVEL=info SENSU_CLIENT_SUBSCRIPTIONS=test

# Add custom checks and scripts
ADD register-result /register-result
ADD check-lvmthin.rb /opt/sensu/embedded/bin/check-lvmthin.rb
ADD check-btrfs.rb /opt/sensu/embedded/bin/check-btrfs.rb

# Add config files
ADD voltgrid.conf /usr/local/etc/voltgrid.conf
ADD config.json /etc/sensu/config.json
ADD client.json /etc/sensu/conf.d/client.json
ADD sudoers /etc/sudoers.d/sensu

ADD entry.sh /
ENTRYPOINT ["/entry.sh"]
CMD ["full"]

ENV BUILD_VERSION 1.0.0-1
