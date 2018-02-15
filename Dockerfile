FROM debian:stretch

# Some dependencies
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get -y install curl sudo bc lvm2 btrfs-tools gnupg2 gosu monitoring-plugins-basic jq python \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  ;

# Install Dumb-init
RUN set -x \
  && DUMB_INIT_VERSION=1.2.1 \
  && DUMB_INIT_CHECKSUM=057ecd4ac1d3c3be31f82fc0848bf77b1326a975b4f8423fe31607205a0fe945 \
  && curl -sS -o /usr/local/bin/dumb-init -L https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 \
  && echo "${DUMB_INIT_CHECKSUM}  dumb-init" > /usr/local/bin/SHA256SUM \
  && ( cd /usr/local/bin; sha256sum -c SHA256SUM; ) \
  && chmod +x /usr/local/bin/dumb-init \
  && rm /usr/local/bin/SHA256SUM \
  ;

# Install gomplate
RUN set -x \
  && GOMPLATE_VERSION=v2.2.0 \
  && GOMPLATE_CHECKSUM=0e09e7cd6fb5e96858255a27080570624f72910e66be5152b77a2fd21d438dd7 \
  && curl -sS -o /tmp/gomplate_linux-amd64-slim -L https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64-slim \
  && echo "${GOMPLATE_CHECKSUM}  gomplate_linux-amd64-slim" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM; ) \
  && mv /tmp/gomplate_linux-amd64-slim /usr/local/bin/gomplate \
  && chmod +x /usr/local/bin/gomplate \
  && rm -f /tmp/* \
  ;

ENV SENSU_VERSION 1.2.1
ENV SENSU_PKG_VERSION 2

# Setup sensu package repo & Install Sensu
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && curl https://repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - \
  && echo "deb     http://repositories.sensuapp.org/apt stretch main" | tee /etc/apt/sources.list.d/sensu.list \
  && apt-get update \
  && apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && echo "EMBEDDED_RUBY=true" > /etc/default/sensu \
  ;

# Install some plugins/checks
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y build-essential \
  && /opt/sensu/embedded/bin/gem install \
      sensu-plugins-disk-checks \
      sensu-plugins-memory-checks \
      sensu-plugins-load-checks \
      sensu-plugins-kubernetes \
      sensu-plugins-ssl \
      sensu-plugins-aws \
      sensu-plugins-http \
      sensu-plugins-redis \
      filesize \
      --no-rdoc --no-ri \
  && apt-get remove -y build-essential \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

ENV PATH=/opt/sensu/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TMPDIR=/var/tmp HOME=/opt/sensu
ENV LOGLEVEL=info SENSU_CLIENT_SUBSCRIPTIONS=test
ENV SENSU_RABBITMQ_CLIENT_USER=guest SENSU_RABBITMQ_CLIENT_PASS=guest SENSU_RABBITMQ_VHOST=/

COPY lite /lite/

# Add custom checks and scripts
ADD register-result /register-result
ADD checks/* /opt/sensu/embedded/bin/

# Add config files
ADD config.json.tmpl /etc/sensu/config.json.tmpl
ADD client.json.tmpl /etc/sensu/conf.d/client.json.tmpl
ADD sudoers /etc/sudoers.d/sensu

ADD entry.sh /
ENTRYPOINT ["/usr/local/bin/dumb-init", "--", "/entry.sh"]

ENV BUILD_VERSION 1.2.1-2
