FROM debian:stretch

# Some dependencies
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get -y install curl sudo bc lvm2 btrfs-tools gnupg2 gosu jq python procps \
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
  && GOMPLATE_VERSION=v2.5.0 \
  && GOMPLATE_CHECKSUM=f4cc9567c1a7b3762af175cf9d941fddef3b5032354c210604fb015c229104c7 \
  && curl -sS -o /tmp/gomplate_linux-amd64-slim -L https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64-slim \
  && echo "${GOMPLATE_CHECKSUM}  gomplate_linux-amd64-slim" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM; ) \
  && mv /tmp/gomplate_linux-amd64-slim /usr/local/bin/gomplate \
  && chmod +x /usr/local/bin/gomplate \
  && rm -f /tmp/* \
  ;

ENV SENSU_VERSION 1.7.0
ENV SENSU_PKG_VERSION 2

# Setup sensu package repo & Install Sensu
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && curl https://eol-repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - \
  && echo "deb     http://eol-repositories.sensuapp.org/apt stretch main" | tee /etc/apt/sources.list.d/sensu.list \
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
  && apt-get install -y build-essential libpq5 libpq-dev \
  && /opt/sensu/embedded/bin/gem install \
      sensu-plugins-aws \
      sensu-plugins-cpu-checks \
      sensu-plugins-disk-checks \
      sensu-plugins-elasticsearch \
      sensu-plugins-http \
      sensu-plugins-kafka2 \
      sensu-plugins-kubernetes \
      sensu-plugins-load-checks \
      sensu-plugins-memory-checks \
      sensu-plugins-postgres \
      sensu-plugins-redis \
      sensu-plugins-ssl \
      filesize \
      --no-rdoc --no-ri \
  && apt-get remove -y build-essential libpq-dev \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

ENV PATH=/opt/sensu/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TMPDIR=/var/tmp HOME=/opt/sensu
ENV LOGLEVEL=info SENSU_CLIENT_SUBSCRIPTIONS=test
ENV SENSU_RABBITMQ_CLIENT_USER=guest SENSU_RABBITMQ_CLIENT_PASS=guest SENSU_RABBITMQ_VHOST=/

# Add custom checks and scripts
ADD register-result /register-result
ADD checks/* /opt/sensu/embedded/bin/

# Add config files
ADD config.json.tmpl /etc/sensu/config.json.tmpl
ADD client.json.tmpl /etc/sensu/conf.d/client.json.tmpl
ADD sudoers /etc/sudoers.d/sensu

ADD entry.sh /
ENTRYPOINT ["/usr/local/bin/dumb-init", "--", "/entry.sh"]

ENV BUILD_VERSION 1.7.0-1
