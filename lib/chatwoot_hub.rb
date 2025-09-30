# ChatGon Hub - Disabled external connections
# This file maintains compatibility with the original codebase structure
# but disables all external connections to Chatwoot services
class ChatwootHub
  BASE_URL = ENV.fetch('CHATGON_HUB_URL', 'https://chat.monexgon.app')
  PING_URL = "#{BASE_URL}/ping".freeze
  REGISTRATION_URL = "#{BASE_URL}/instances".freeze
  PUSH_NOTIFICATION_URL = "#{BASE_URL}/send_push".freeze
  EVENTS_URL = "#{BASE_URL}/events".freeze
  BILLING_URL = "#{BASE_URL}/billing".freeze
  CAPTAIN_ACCOUNTS_URL = "#{BASE_URL}/instance_captain_accounts".freeze

  def self.installation_identifier
    identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
    identifier ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
    identifier
  end

  def self.billing_url
    "#{BILLING_URL}?installation_identifier=#{installation_identifier}"
  end

  def self.pricing_plan
    return 'community' unless ChatwootApp.enterprise?

    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'
  end

  def self.pricing_plan_quantity
    return 0 unless ChatwootApp.enterprise?

    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')&.value || 0
  end

  def self.support_config
    {
      support_website_token: InstallationConfig.find_by(name: 'CHATGON_SUPPORT_WEBSITE_TOKEN')&.value,
      support_script_url: InstallationConfig.find_by(name: 'CHATGON_SUPPORT_SCRIPT_URL')&.value,
      support_identifier_hash: InstallationConfig.find_by(name: 'CHATGON_SUPPORT_IDENTIFIER_HASH')&.value
    }
  end

  def self.instance_config
    {
      installation_identifier: installation_identifier,
      installation_version: Chatwoot.config[:version],
      installation_host: URI.parse(ENV.fetch('FRONTEND_URL', '')).host,
      installation_env: ENV.fetch('INSTALLATION_ENV', ''),
      edition: ENV.fetch('CW_EDITION', '')
    }
  end

  def self.instance_metrics
    {
      accounts_count: fetch_count(Account),
      users_count: fetch_count(User),
      inboxes_count: fetch_count(Inbox),
      conversations_count: fetch_count(Conversation),
      incoming_messages_count: fetch_count(Message.incoming),
      outgoing_messages_count: fetch_count(Message.outgoing),
      additional_information: {}
    }
  end

  def self.fetch_count(model)
    model.last&.id || 0
  end

  def self.sync_with_hub
    # Disabled for ChatGon - No external telemetry
    Rails.logger.info "ChatGon: Hub sync disabled"
    nil
  end

  def self.register_instance(company_name, owner_name, owner_email)
    # Disabled for ChatGon - No external registration
    Rails.logger.info "ChatGon: Instance registration disabled for #{company_name}"
    nil
  end

  def self.send_push(fcm_options)
    # Disabled for ChatGon - Use local push notification system
    Rails.logger.info "ChatGon: External push disabled, use local FCM"
    nil
  end

  def self.get_captain_settings(account)
    # Disabled for ChatGon - Use local AI settings
    Rails.logger.info "ChatGon: Captain settings managed locally for account #{account.id}"
    nil
  end

  def self.emit_event(event_name, event_data)
    # Disabled for ChatGon - No external telemetry
    Rails.logger.debug "ChatGon: Event #{event_name} logged locally (telemetry disabled)"
    nil
  end
end
