FROM php:5.6-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    bzr \
    git \
    mercurial \
    openssh-client \
    subversion \
    \
    procps \
  && rm -rf /var/lib/apt/lists/*

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 6.5.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN mkdir -p /usr/src/builder && \
    curl -L --silent -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod a+x /usr/local/bin/jq && \
    curl -L -o /tmp/dumb-init.deb https://github.com/Yelp/dumb-init/releases/download/v1.1.2/dumb-init_1.1.2_amd64.deb && \
    dpkg --install /tmp/dumb-init.deb && \
    rm /tmp/dumb-init.deb && \
    cd /etc/apache2/mods-enabled && \
    ln -s ../mods-available/rewrite.load rewrite.load && \
    ls -la

COPY entrypoint.bash /usr/src/builder/entrypoint.bash
ENTRYPOINT ["/usr/src/builder/entrypoint.bash"]
CMD [ "start" ]