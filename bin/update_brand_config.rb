#!/usr/bin/env ruby
# Script to update brand configuration from environment variables

configs = {
  'INSTALLATION_NAME' => ENV['INSTALLATION_NAME'] || 'ChatGon',
  'BRAND_NAME' => ENV['BRAND_NAME'] || 'ChatGon',
  'BRAND_URL' => ENV['BRAND_URL'] || 'https://chat.monexgon.app',
  'WIDGET_BRAND_URL' => ENV['WIDGET_BRAND_URL'] || 'https://chat.monexgon.app',
  'BRAND_COLOR' => ENV['BRAND_COLOR'] || '#2781F6',
  'LOGO' => ENV['LOGO'] || '/brand-assets/logo.svg',
  'LOGO_DARK' => ENV['LOGO_DARK'] || '/brand-assets/logo_dark.svg',
  'LOGO_THUMBNAIL' => ENV['LOGO_THUMBNAIL'] || '/brand-assets/logo_thumbnail.svg'
}

configs.each do |key, value|
  config = InstallationConfig.find_by(name: key)
  if config && value.present?
    config.update(value: value)
    puts "✓ Updated #{key} to #{value}"
  else
    puts "✗ Config #{key} not found in database"
  end
end

puts '✅ Brand configuration completed successfully'