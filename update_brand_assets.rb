#!/usr/bin/env ruby
# Script to update ChatGon brand assets in database
# Run with: rails runner update_brand_assets.rb

puts "=========================================="
puts "Updating ChatGon Brand Assets"
puts "=========================================="

# Brand configuration
brand_configs = {
  'INSTALLATION_NAME' => 'ChatGon',
  'BRAND_NAME' => 'ChatGon',
  'BRAND_URL' => ENV.fetch('FRONTEND_URL', 'https://chat.monexgon.app'),
  'WIDGET_BRAND_URL' => ENV.fetch('FRONTEND_URL', 'https://chat.monexgon.app'),
  'BRAND_COLOR' => '#2781F6',
  'LOGO' => '/brand-assets/logo-cg.svg',
  'LOGO_DARK' => '/brand-assets/logo-dark.svg',
  'LOGO_THUMBNAIL' => '/brand-assets/logo-thumbnail.svg'
}

# Update each configuration
brand_configs.each do |key, value|
  config = InstallationConfig.find_or_initialize_by(name: key)
  old_value = config.value
  config.value = value

  if config.save
    if old_value != value
      puts "✓ Updated #{key}: '#{old_value}' → '#{value}'"
    else
      puts "✓ Confirmed #{key}: '#{value}'"
    end
  else
    puts "✗ Failed to update #{key}: #{config.errors.full_messages.join(', ')}"
  end
end

# Clear Redis premium warning (bonus cleanup)
begin
  Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  puts "✓ Cleared premium warnings from Redis"
rescue => e
  puts "⚠ Redis cleanup skipped: #{e.message}"
end

puts "=========================================="
puts "✓ Brand assets updated successfully!"
puts "=========================================="
puts ""
puts "Next steps:"
puts "1. Restart the application: docker restart chatgon-app chatgon-sidekiq"
puts "2. Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)"
puts "3. Verify logos at: #{ENV.fetch('FRONTEND_URL', 'https://chat.monexgon.app')}"
puts ""