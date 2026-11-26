# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

# This Dockerfile requires BuildKit (default since Docker Engine 23).
#
# Stages:
#   base         - Ubuntu with the apt cache kept for BuildKit cache mounts
#   ruby         - Ruby compiled from source into /opt/ruby
#   node         - Node.js and Yarn v1 unpacked into /opt/node
#   build-dep    - gems and node modules for /opt/mastodon (name kept for CI)
#   precompiler  - application source, version patch and precompiled assets
#   (final)      - runtime image

ARG UBUNTU_VERSION="26.04"

# Ruby version to compile, change with [--build-arg RUBY_VERSION="3.4.x" --build-arg RUBY_SHA256="..."]
ARG RUBY_VERSION="3.4.13"
ARG RUBY_SHA256="d0d3bf3dd8c224a3c3b7ecd816a0f1b2cbcf4f87b5afcbdbe91d3fef177f351a"

# Node.js version, change with [--build-arg NODE_VERSION="26.x.y"] and the matching
# SHA-256 of node-v<version>-linux-{x64,arm64}.tar.xz from SHASUMS256.txt
ARG NODE_VERSION="26.13.1"
ARG NODE_SHA256_AMD64="5c063e46bab0fbc1c17cc445d7ff129cbdcd0471be6ed83b6ab864f8143bc864"
ARG NODE_SHA256_ARM64="89e1853138db51e8b82d3e98ba9c0d3f2956a28e5e55ea1b7e12d25aae92d5dd"
ARG YARN_VERSION="1.22.22"

FROM ubuntu:${UBUNTU_VERSION} AS base

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

ENV DEBIAN_FRONTEND="noninteractive"

RUN \
  # Keep downloaded packages so that they can be reused through BuildKit cache mounts
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache; \
  echo "Etc/UTC" > /etc/localtime

########################################################################################################################
FROM base AS ruby

ARG RUBY_VERSION
ARG RUBY_SHA256
ARG TARGETPLATFORM

# hadolint ignore=DL3008
RUN \
  --mount=type=cache,id=apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    libffi-dev \
    libgdbm-dev \
    libjemalloc-dev \
    libncurses-dev \
    libreadline-dev \
    libssl-dev \
    libyaml-dev \
    wget \
    zlib1g-dev \
  ;

RUN \
  cd /tmp; \
  wget -q "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz"; \
  echo "${RUBY_SHA256}  ruby-${RUBY_VERSION}.tar.gz" | sha256sum -c -; \
  tar xf "ruby-${RUBY_VERSION}.tar.gz"; \
  cd "ruby-${RUBY_VERSION}"; \
  ./configure --prefix=/opt/ruby \
    --with-jemalloc \
    --disable-install-doc; \
  make -j"$(nproc)" > /dev/null; \
  make install; \
  cd /; \
  rm -rf /tmp/ruby-*

########################################################################################################################
FROM base AS node

ARG NODE_VERSION
ARG NODE_SHA256_AMD64
ARG NODE_SHA256_ARM64
ARG YARN_VERSION
ARG TARGETARCH
ARG TARGETPLATFORM

# hadolint ignore=DL3008
RUN \
  --mount=type=cache,id=apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    libatomic1 \
    wget \
    xz-utils \
  ;

RUN \
  case "${TARGETARCH}" in \
    amd64) ARCH='x64'; NODE_SHA256="${NODE_SHA256_AMD64}";; \
    arm64) ARCH='arm64'; NODE_SHA256="${NODE_SHA256_ARM64}";; \
    *) echo "unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
  esac; \
  cd /tmp; \
  wget -q "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz"; \
  echo "${NODE_SHA256}  node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" | sha256sum -c -; \
  mkdir -p /opt/node; \
  tar xf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" -C /opt/node --strip-components=1; \
  rm -f /tmp/node-*; \
  # Corepack is no longer bundled with Node.js, so install Yarn v1 with npm
  PATH="/opt/node/bin:${PATH}" npm install -g "yarn@${YARN_VERSION}"; \
  PATH="/opt/node/bin:${PATH}" npm cache clean --force

########################################################################################################################
FROM base AS build-dep

ARG TARGETPLATFORM

COPY --link --from=ruby /opt/ruby /opt/ruby
COPY --link --from=node /opt/node /opt/node

ENV PATH="${PATH}:/opt/ruby/bin:/opt/node/bin"

# hadolint ignore=DL3008
RUN \
  --mount=type=cache,id=apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    libatomic1 \
    libffi-dev \
    libicu-dev \
    libidn-dev \
    # Ruby is built with jemalloc, so native extensions need its headers
    libjemalloc-dev \
    libpq-dev \
    libssl-dev \
    libyaml-dev \
    pkg-config \
    python3 \
    shared-mime-info \
    zlib1g-dev \
  ;

WORKDIR /opt/mastodon

COPY --link Gemfile* package.json yarn.lock /opt/mastodon/

# Bundler's global gem cache is deliberately not used: it restores compiled
# extensions from the cache, which loses libraries that some gems (e.g.
# llhttp-ffi) build inside their own directory. This layer is rebuilt only
# when Gemfile or Gemfile.lock change.
RUN \
  bundle config set --local deployment 'true'; \
  bundle config set --local without 'development test'; \
  bundle config set silence_root_warning true; \
  bundle install -j"$(nproc)"

RUN \
  # Keep downloaded packages across builds
  --mount=type=cache,id=yarn-cache-${TARGETPLATFORM},target=/usr/local/share/.cache/yarn,sharing=locked \
  yarn install --frozen-lockfile --network-timeout 600000

########################################################################################################################
FROM build-dep AS precompiler

COPY --link . /opt/mastodon/

RUN \
  # Append the commit hash to the version, then drop the repository metadata
  node bin/version-hash.js "$(git -C /opt/mastodon rev-parse --short HEAD)"; \
  rm -rf .git

RUN \
  RAILS_ENV=production \
  NODE_ENV=production \
  OTP_SECRET=precompile_placeholder \
  SECRET_KEY_BASE=precompile_placeholder \
  bin/rails assets:precompile; \
  rm -rf tmp/cache

########################################################################################################################
FROM base

ARG UID="991"
ARG GID="991"
ARG TARGETPLATFORM

COPY --link --from=ruby /opt/ruby /opt/ruby
COPY --link --from=node /opt/node /opt/node

# Add more PATHs to the PATH
ENV PATH="${PATH}:/opt/ruby/bin:/opt/node/bin:/opt/mastodon/bin"

# Install Mastodon runtime dependencies
# hadolint ignore=DL3008
RUN \
  --mount=type=cache,id=apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
  apt-get update; \
  apt-get dist-upgrade -yq; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    ffmpeg \
    file \
    git \
    imagemagick \
    libatomic1 \
    libffi8 \
    libgdbm6t64 \
    libicu78 \
    libidn12 \
    libjemalloc2 \
    libncursesw6 \
    libpq5 \
    libreadline8t64 \
    libssl3t64 \
    libyaml-0-2 \
    procps \
    tini \
    tzdata \
    wget \
    whois \
    zlib1g \
  ;

# Create the mastodon user
RUN \
  groupadd -g "${GID}" mastodon; \
  useradd -l -m -u "${UID}" -g "${GID}" -d /opt/mastodon mastodon; \
  echo "mastodon:$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 | mkpasswd -s -m sha-256)" | chpasswd; \
  ln -s /opt/mastodon /mastodon

# Copy over mastodon source, dependencies and precompiled assets, and set permissions
COPY --link --chown=${UID}:${GID} --from=precompiler /opt/mastodon /opt/mastodon

# Run mastodon services in prod mode
ENV RAILS_ENV="production"
ENV NODE_ENV="production"

# Tell rails to serve static files
ENV RAILS_SERVE_STATIC_FILES="true"
ENV BIND="0.0.0.0"

# Set the run user
USER mastodon

# Set the work dir and the container entry point
WORKDIR /opt/mastodon
ENTRYPOINT ["/usr/bin/tini", "--"]
EXPOSE 3000 4000
