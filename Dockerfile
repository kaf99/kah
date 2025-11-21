# syntax = docker/dockerfile:1

# Base image with Ruby
ARG RUBY_VERSION=3.3.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        curl \
        libjemalloc2 \
        postgresql-client \
        libpq-dev \
        libvips \
        redis-tools \
        ca-certificates \
        gnupg \
        dirmngr && \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"

# ------------------------------------------------------------
# Build stage (for compiling assets)
# ------------------------------------------------------------
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        build-essential \
        git \
        pkg-config \
        nodejs \
        npm \
        yarn && \
    rm -rf /var/lib/apt/lists/*

# Install correct bundler version
RUN gem install bundler -v 2.6.5

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set frozen false && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile assets (using dummy secret key)
RUN SECRET_KEY_BASE=1 ./bin/rails assets:precompile

# ------------------------------------------------------------
# Final stage (slim image for running app)
# ------------------------------------------------------------
FROM base

# Copy gems and application code from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
