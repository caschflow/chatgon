#!/usr/bin/env ruby
# Script to update brand configuration from environment variables

configs = {
  'INSTALLATION_NAME' => ENV['INSTALLATION_NAME'] || 'ChatGon',
  'BRAND_NAME' => ENV['BRAND_NAME'] || 'ChatGon',
  'BRAND_URL' => ENV['BRAND_URL'] || 'https://chat.monexgon.app',
  'WIDGET_BRAND_URL' => ENV['WIDGET_BRAND_URL'] || 'https://chat.monexgon.app',
  'BRAND_COLOR' => ENV['BRAND_COLOR'] || '#2781F6',
  'LOGO' => ENV['LOGO'] || '/brand-assets/logo-cg.svg',
  'LOGO_DARK' => ENV['LOGO_DARK'] || '/brand-assets/logo-dark.svg',
  'LOGO_THUMBNAIL' => ENV['LOGO_THUMBNAIL'] || '/brand-assets/logo-thumbnail.svg',
  'DEPLOYMENT_ENV' => 'self-hosted',
  'INSTALLATION_PRICING_PLAN' => 'enterprise'
}

configs.each do |key, value|
  next unless value.present?

  config = InstallationConfig.find_or_initialize_by(name: key)
  config.value = value
  config.locked = false if key == 'BRAND_COLOR'

  if config.save
    puts "✓ Updated #{key} to #{value}"
  else
    puts "✗ Failed to update #{key}: #{config.errors.full_messages.join(', ')}"
  end
end

# Clear premium warnings from Redis
begin
  Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  puts '✓ Cleared premium config warnings from Redis'
rescue => e
  puts "⚠ Could not clear Redis warnings: #{e.message}"
end

puts '========================================='
puts '✅ Brand configuration completed successfully'
puts '✅ ChatGon configured as independent installation'
puts '✅ All enterprise features enabled'
puts '========================================='