#!/usr/bin/env ruby
# Script to clear premium config reset warning from Redis
# Run this script with: rails runner clear_premium_warning.rb

puts "Clearing premium config reset warning from Redis..."
Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
puts "✓ Warning cleared successfully!"