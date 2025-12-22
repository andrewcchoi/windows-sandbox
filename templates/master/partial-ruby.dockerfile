# === RUBY LANGUAGE ADDITIONS ===
USER root

# Install Ruby
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full \
    ruby-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install bundler and common gems
RUN gem update --system && \
    gem install bundler && \
    gem install rake rspec rubocop

# Configure gem installation for user
RUN mkdir -p /home/node/.gem && \
    chown -R node:node /home/node/.gem

USER node

# Set Ruby environment variables
ENV GEM_HOME=/home/node/.gem \
    PATH=/home/node/.gem/bin:$PATH

# === END RUBY LANGUAGE ADDITIONS ===
