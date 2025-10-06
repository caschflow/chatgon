#!/bin/sh

set -x

echo "=========================================="
echo "ChatGon Setup: Migrations & Brand Config"
echo "=========================================="

# Let DATABASE_URL env take presedence over individual connection params.
eval $(docker/entrypoints/helpers/pg_database_url.rb)

echo "Waiting for PostgreSQL to be ready..."
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  echo "PostgreSQL not ready, waiting..."
  sleep 2;
done

echo "✓ PostgreSQL is ready"

echo "Waiting for Redis to be ready..."
# Using nc (netcat) instead of redis-cli since redis-cli is not installed in Rails image
until nc -z redis 6379 > /dev/null 2>&1
do
  echo "Redis not ready, waiting..."
  sleep 2;
done

echo "✓ Redis is ready"

# Install missing gems for production
echo "Installing gems..."
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

echo "✓ Gems installed"

# Run database migrations
echo "=========================================="
echo "Running database migrations..."
echo "=========================================="
bundle exec rails db:prepare

if [ $? -eq 0 ]; then
  echo "✓ Database migrations completed successfully"
else
  echo "✗ Database migrations failed!"
  exit 1
fi

# Run brand setup
echo "=========================================="
echo "Configuring ChatGon Brand..."
echo "=========================================="
bundle exec rails runner bin/setup_brand.rb

if [ $? -eq 0 ]; then
  echo "✓ Brand configuration completed successfully"
else
  echo "✗ Brand configuration failed!"
  exit 1
fi

echo "=========================================="
echo "✓ ChatGon Setup Completed Successfully"
echo "=========================================="
echo "  - Database migrated"
echo "  - Brand configured (ChatGon)"
echo "  - All features enabled"
echo "  - Security settings applied"
echo "=========================================="

echo "Setup service completed. Rails and Sidekiq will start automatically."
