#!/bin/bash
set -e

echo "=========================================="
echo "Running ChatGon Post-Deployment Tasks"
echo "=========================================="

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 5

# Run database migrations
echo "📊 Running database migrations..."
bundle exec rails db:migrate RAILS_ENV=production

# Clear Redis premium warning
echo "🧹 Clearing premium config warnings from Redis..."
bundle exec rails runner "
  Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  puts '✓ Premium warning cleared from Redis'
" RAILS_ENV=production

# Precompile assets if needed (optional - usually done in Docker build)
# echo "🎨 Precompiling assets..."
# bundle exec rails assets:precompile RAILS_ENV=production

# Restart Sidekiq to pick up new jobs
echo "🔄 Restarting background jobs..."
# This will be handled by Coolify/Docker automatically

echo "=========================================="
echo "✅ Post-deployment tasks completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Visit: https://chat.monexgon.app/super_admin/settings"
echo "2. Verify no premium warning banner appears"
echo "3. Check all features show as enabled"
echo ""