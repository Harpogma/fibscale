FROM ruby:3.3

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

# Install build dependencies
RUN apt-get update && \
    apt-get install -y g++ make patch && \
    rm -rf /var/lib/apt/lists/*

# Create user and group
RUN groupadd --system fibscale && \
    useradd --create-home --gid fibscale --system fibscale

# Set working directory and change ownership (as root)
WORKDIR /fibscale
RUN chown fibscale:fibscale .

# Copy and install dependencies (as root, then switch user)
COPY Gemfile Gemfile.lock ./
RUN chown fibscale:fibscale Gemfile Gemfile.lock

# Switch to non-root user BEFORE bundle install
USER fibscale
RUN bundle install

# Copy application code
COPY --chown=fibscale:fibscale ./ ./

# Use JSON array format for CMD
CMD ["bundle", "exec", "ruby", "fibscale.rb"]