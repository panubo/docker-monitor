FROM debian:jessie

MAINTAINER Tim Robinson <tim@panubo.com>

ENV SENSU_VERSION 0.26.5
ENV SENSU_PKG_VERSION 2
ENV VOLTGRID_PIE=1.0.6 VOLTGRID_PIE_SHA1=11572a8ea15fb31cddeaa7e1438db61420556587

# Some dependencies
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get -y install curl sudo bc python-jinja2 lvm2 btrfs-tools && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Setup sensu package repo & Install Sensu
RUN export DEBIAN_FRONTEND=noninteractive && \
  curl https://repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - && \
  echo "deb     http://repositories.sensuapp.org/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list && \
  apt-get update && \
  apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  echo "EMBEDDED_RUBY=true" > /etc/default/sensu

# Install Voltgrid.py
RUN DIR=$(mktemp -d) && cd ${DIR} && \
  curl -s -L https://github.com/voltgrid/voltgrid-pie/archive/v${VOLTGRID_PIE}.tar.gz -o voltgrid-pie.tar.gz && \
  sha1sum voltgrid-pie.tar.gz && \
  echo "${VOLTGRID_PIE_SHA1} voltgrid-pie.tar.gz" | sha1sum -c - && \
  tar -C /usr/local/bin --strip-components 1 -zxf voltgrid-pie.tar.gz voltgrid-pie-${VOLTGRID_PIE}/voltgrid.py && \
  rm -rf ${DIR}

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

ENV BUILD_VERSION 0.26.5-7
