#!/usr/bin/env ruby
# Script to enable all features for ChatGon (bypass premium/internal restrictions)

puts '=========================================='
puts 'ChatGon Feature Enablement Script'
puts '=========================================='

# Load features from features.yml
features_config = YAML.load_file(Rails.root.join('config', 'features.yml'))

enabled_count = 0
already_enabled = 0

features_config.each do |feature_config|
  feature_name = feature_config['name']

  # Skip deprecated features
  if feature_config['deprecated']
    puts "⊘ Skipping deprecated feature: #{feature_name}"
    next
  end

  # Enable the feature
  feature = Feature.find_or_initialize_by(name: feature_name)

  if feature.new_record?
    feature.enabled = true
    feature.save!
    puts "✓ Enabled new feature: #{feature_name}"
    enabled_count += 1
  elsif !feature.enabled
    feature.enabled = true
    feature.save!
    puts "✓ Enabled feature: #{feature_name}"
    enabled_count += 1
  else
    already_enabled += 1
  end
end

puts '=========================================='
puts "✅ Feature enablement completed"
puts "   - #{enabled_count} features enabled"
puts "   - #{already_enabled} features already enabled"
puts '=========================================='
