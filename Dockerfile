# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.0
FROM ruby:$RUBY_VERSION-slim AS base

# Install OS-level packages
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    postgresql-client \
    libvips \
    nodejs \
    npm \
    yarn \
    curl \
    libjemalloc2 \
    redis-tools \
    ca-certificates \
    gnupg \
    dirmngr && \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH="/usr/local/bundle" \
    MALLOC_ARENA_MAX=2 \
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

WORKDIR /rails

############################################################
# BUILD STAGE (Install gems + precompile assets)
############################################################
FROM base AS build

# Install correct bundler version
RUN gem install bundler -v 2.6.5

# Copy gem declarations first
COPY Gemfile Gemfile.lock ./

RUN bundle config set frozen false && \
    bundle config set without 'development test' && \
    bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy app source
COPY . .

# Precompile assets (use safe dummy key)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

############################################################
# FINAL RUNTIME STAGE
############################################################
FROM base

# Copy Ruby gems
COPY --from=build /usr/local/bundle /usr/local/bundle

# Copy app
COPY --from=build /rails /rails

# Create non-root user & fix permissions
RUN groupadd -g 1000 rails && \
    useradd -u 1000 -g 1000 -m -s /bin/bash rails && \
    mkdir -p /rails/tmp /rails/log /rails/storage && \
    chown -R rails:rails /rails

USER rails
WORKDIR /rails

# Healthcheck so Traefik knows container is ready
HEALTHCHECK --interval=10s --timeout=3s CMD curl -f http://localhost:3000 || exit 1

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000", "-e", "production"]
