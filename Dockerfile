FROM ruby:3.4.6-slim-bookworm AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
  && apt-get install --no-install-recommends -y curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN (curl -sL https://deb.nodesource.com/setup_20.x | bash -)

# Install main dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential  \
    netcat-openbsd \
    libmariadb-dev \
    libpq-dev \
    libcap2-bin \
    nano \
    libyaml-dev \
    nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/ruby

# Configure 'postal' to work everywhere (when the binary exists
# later in this process)
ENV PATH="/opt/postal/app/bin:${PATH}"

# Setup an application
RUN useradd -r -d /opt/postal -m -s /bin/bash -u 999 postal
USER postal
RUN mkdir -p /opt/postal/app /opt/postal/config
WORKDIR /opt/postal/app

# Install bundler
RUN gem install bundler -v 2.7.2 --no-doc

# Install the latest and active gem dependencies and re-run
# the appropriate commands to handle installs.
COPY --chown=postal Gemfile Gemfile.lock ./
RUN bundle install

# Copy the application (and set permissions)
COPY ./docker/wait-for.sh /docker-entrypoint.sh
COPY --chown=postal . .

# Export the version
ARG VERSION
ARG BRANCH
RUN if [ "$VERSION" != "" ]; then echo $VERSION > VERSION; fi \
  && if [ "$BRANCH" != "" ]; then echo $BRANCH > BRANCH; fi

# Set paths for when running in a container
ENV POSTAL_CONFIG_FILE_PATH=/config/postal.yml

# Set the CMD
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["postal"]

# ci target - use --target=ci to skip asset compilation
FROM base AS ci

# optional target - adds the optional dependency groups on top of ci. These are
# not part of the default build: the duckdb gem needs the DuckDB C library, and
# redis-client is only needed when the Valkey live-stats store is used.
FROM ci AS optional

USER root
RUN apt-get update \
  && apt-get install --no-install-recommends -y curl unzip \
  && curl -sSL -o /tmp/libduckdb.zip \
       https://github.com/duckdb/duckdb/releases/download/v1.5.5/libduckdb-linux-amd64.zip \
  && unzip -q /tmp/libduckdb.zip -d /tmp/libduckdb \
  && install -m 0644 /tmp/libduckdb/duckdb.h /tmp/libduckdb/duckdb.hpp /usr/local/include/ \
  && install -m 0755 /tmp/libduckdb/libduckdb.so /usr/local/lib/libduckdb.so \
  && rm -rf /tmp/libduckdb /tmp/libduckdb.zip \
  && ldconfig \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER postal

RUN bundle config set --local with 'analytics valkey aerospike sqlite s3' && bundle install

# full target - default if no --target option is given
FROM base AS full

RUN RAILS_GROUPS=assets bundle exec rake assets:precompile
RUN touch /opt/postal/app/public/assets/.prebuilt
