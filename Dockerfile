FROM debian:jessie

MAINTAINER Tim Robinson <tim@panubo.com>

ENV DEBIAN_FRONTEND noninteractive

ENV SENSU_VERSION 0.21.0
ENV SENSU_PKG_VERSION 2

# Some dependencies
RUN apt-get update && \
  apt-get -y install curl sudo bc python-jinja2 lvm2

# Setup sensu package repo & Install Sensu
RUN curl http://repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - && \
  echo "deb     http://repositories.sensuapp.org/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list && \
  apt-get update && \
  apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} && \
  echo "EMBEDDED_RUBY=true" > /etc/default/sensu

RUN curl -L https://github.com/voltgrid/voltgrid-pie/archive/v1.tar.gz | tar -C /usr/local/bin --strip-components 1 -zxf - voltgrid-pie-1/voltgrid.py

ENTRYPOINT ["/usr/local/bin/voltgrid.py"]
CMD ["/opt/sensu/bin/sensu-client", "-c", "/etc/sensu/config.json", "-d", "/etc/sensu/conf.d", "-e", "/etc/sensu/extensions", "-L", "warn"]

# Install some plugins/checks
RUN apt-get install -y build-essential && \
  /opt/sensu/embedded/bin/gem install \
  sensu-plugins-disk-checks \
  sensu-plugins-memory-checks \
  sensu-plugins-load-checks \
  --no-rdoc --no-ri && \
  apt-get remove -y build-essential && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

ENV PATH=/opt/sensu/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TMPDIR=/var/tmp HOME=/opt/sensu
ENV LOGLEVEL=info SENSU_CLIENT_SUBSCRIPTIONS=test

# Add custom checks and scripts
ADD register-result /register-result
ADD check-lvmthin.rb /opt/sensu/embedded/bin/check-lvmthin.rb

# Add config files
ADD voltgrid.conf /usr/local/etc/voltgrid.conf
ADD config.json /etc/sensu/config.json
ADD client.json /etc/sensu/conf.d/client.json
ADD sudoers /etc/sudoers.d/sensu
