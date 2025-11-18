# ABOUTME: Multi-stage Dockerfile for Rails app with development and production stages
# ABOUTME: Uses official Ruby image and installs Rails dependencies
FROM ruby:3.2.2-slim as base

# Install dependencies
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

COPY Gemfile* ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

COPY . .

RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
