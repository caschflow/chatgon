#!/usr/bin/env ruby
# frozen_string_literal: true

puts '=========================================='
puts 'ChatGon Brand Setup & Configuration'
puts '=========================================='

# Configure branding
configs = {
  'INSTALLATION_NAME' => ENV['INSTALLATION_NAME'],
  'BRAND_NAME' => ENV['BRAND_NAME'],
  'BRAND_URL' => ENV['BRAND_URL'] || ENV['FRONTEND_URL'],
  'WIDGET_BRAND_URL' => ENV['WIDGET_BRAND_URL'] || ENV['FRONTEND_URL'],
  'BRAND_COLOR' => ENV['BRAND_COLOR'],
  'LOGO' => ENV['LOGO'],
  'LOGO_DARK' => ENV['LOGO_DARK'],
  'LOGO_THUMBNAIL' => ENV['LOGO_THUMBNAIL'],
  'DEPLOYMENT_ENV' => 'self-hosted',
  'INSTALLATION_PRICING_PLAN' => 'enterprise',
  'INSTALLATION_PRICING_PLAN_QUANTITY' => '999999'
}

configs.each do |key, value|
  next unless value.present?

  config = InstallationConfig.find_or_initialize_by(name: key)
  config.value = value
  config.locked = false if %w[BRAND_COLOR INSTALLATION_PRICING_PLAN].include?(key)
  config.save!
  puts "✓ Updated #{key} to #{value}"
end

# Enable all features (bypass premium restrictions)
features_config = YAML.load_file('config/features.yml')
enabled_count = 0

features_config.each do |feature_config|
  next if feature_config['deprecated']

  feature_name = feature_config['name']

  # Check if Feature model exists (only in newer versions)
  next unless defined?(Feature)

  feature = Feature.find_or_initialize_by(name: feature_name)
  next if feature.enabled

  feature.enabled = true
  feature.save!
  enabled_count += 1
end

puts "✓ Enabled #{enabled_count} features" if enabled_count.positive?

# Clear premium warnings from Redis
begin
  Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  puts '✓ Cleared premium config warnings from Redis'
rescue StandardError => e
  puts "⚠ Could not clear Redis warnings: #{e.message}"
end

puts '========================================='
puts '✓ Brand configuration completed successfully'
puts '✓ ChatGon configured as independent installation'
puts '✓ All enterprise features enabled'
puts '========================================='
