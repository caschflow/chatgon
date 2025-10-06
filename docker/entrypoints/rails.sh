#!/bin/sh

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
# This is done to avoid printing the DATABASE_URL in the logs
eval $(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

# Wait for setup service to complete (in production)
if [ "$RAILS_ENV" = "production" ]; then
  echo "Waiting for ChatGon setup service to complete..."

  # Wait for setup marker file (created by setup.sh)
  while [ ! -f /tmp/chatgon-setup-complete ]; do
    echo "Setup service not completed yet, waiting..."
    sleep 2
  done

  echo "✓ Setup service completed. Starting Rails server..."
fi

# Install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Run database migrations and brand setup (only if RAILS_ENV is NOT production)
# In production, this is handled by the setup service
if [ "$RAILS_ENV" != "production" ]; then
  echo "Running database migrations..."
  bundle exec rails db:prepare
  echo "Database migrated successfully."

  echo "Running brand setup..."
  bundle exec rails runner bin/setup_brand.rb
  echo "Brand setup completed."
fi

# Execute the main process of the container
exec "$@"
