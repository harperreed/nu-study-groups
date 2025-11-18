# ABOUTME: Multi-stage Dockerfile for Rails app with development and production stages
# ABOUTME: Uses official Ruby image and installs Rails dependencies with optimized caching

# Base stage with common dependencies
FROM ruby:3.2.2-slim as base

# Install base dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl \
    libsqlite3-0 \
    libvips \
    && rm -rf /var/lib/apt/lists/*

# Install yarn
RUN npm install -g yarn

WORKDIR /app

# Development stage
FROM base as development

COPY Gemfile* ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

# Production stage
FROM base as production

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# Copy dependency files first for better caching
COPY Gemfile* ./

# Install production gems only
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile assets (Tailwind CSS and other assets)
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# Create a non-root user for security
RUN groupadd -r rails && useradd -r -g rails rails && \
    chown -R rails:rails /app

USER rails

EXPOSE 3000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

CMD ["rails", "server", "-b", "0.0.0.0"]
