#######################################
# To create a whatsapp provider
# - Inherit this as the base class.
# - Implement `send_message` method in your child class.
# - Implement `send_template_message` method in your child class.
# - Implement `sync_templates` method in your child class.
# - Implement `validate_provider_config` method in your child class.
# - Use Childclass.new(whatsapp_channel: channel).perform.
######################################

class Whatsapp::Providers::BaseService
  pattr_initialize [:whatsapp_channel!]

  def send_message(_phone_number, _message)
    raise 'Overwrite this method in child class'
  end

  def send_template(_phone_number, _template_info, _message)
    raise 'Overwrite this method in child class'
  end

  def sync_template
    raise 'Overwrite this method in child class'
  end

  def validate_provider_config
    raise 'Overwrite this method in child class'
  end

  def error_message
    raise 'Overwrite this method in child class'
  end

  def process_response(response, message)
    parsed_response = response.parsed_response

    if response.success? && parsed_response['error'].blank?
      # Try different response formats from various WhatsApp providers
      message_id = extract_message_id_from_response(parsed_response)

      if message_id.present?
        Rails.logger.info "[WhatsApp] Message sent successfully. ID: #{message_id}"
        message_id
      else
        Rails.logger.warn "[WhatsApp] Success response but no message ID found: #{parsed_response.inspect}"
        handle_error(response, message)
        nil
      end
    else
      handle_error(response, message)
      nil
    end
  end

  def extract_message_id_from_response(parsed_response)
    # WhatsApp Business API / 360Dialog format: { "messages": [{ "id": "wamid.xxx" }] }
    return parsed_response['messages']&.first&.dig('id') if parsed_response['messages'].present?

    # Evolution API format: { "key": { "id": "xxx" } }
    return parsed_response.dig('key', 'id') if parsed_response.dig('key', 'id').present?

    # Evolution API alternative: { "id": "xxx" }
    return parsed_response['id'] if parsed_response['id'].is_a?(String) && parsed_response['id'].present?

    # Evolution API nested: { "message": { "key": { "id": "xxx" } } }
    return parsed_response.dig('message', 'key', 'id') if parsed_response.dig('message', 'key', 'id').present?

    # Baileys/Evolution v2: { "data": { "key": { "id": "xxx" } } }
    return parsed_response.dig('data', 'key', 'id') if parsed_response.dig('data', 'key', 'id').present?

    Rails.logger.debug "[WhatsApp] Could not extract message ID from: #{parsed_response.inspect}"
    nil
  end

  def handle_error(response, message)
    Rails.logger.error response.body
    return if message.blank?

    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    error_message = error_message(response)
    return if error_message.blank?

    message.external_error = error_message
    message.status = :failed
    message.save!
  end

  def create_buttons(items)
    buttons = []
    items.each do |item|
      button = { :type => 'reply', 'reply' => { 'id' => item['value'], 'title' => item['title'] } }
      buttons << button
    end
    buttons
  end

  def create_rows(items)
    rows = []
    items.each do |item|
      row = { 'id' => item['value'], 'title' => item['title'] }
      rows << row
    end
    rows
  end

  def create_payload(type, message_content, action)
    {
      'type': type,
      'body': {
        'text': message_content
      },
      'action': action
    }
  end

  def create_payload_based_on_items(message)
    if message.content_attributes['items'].length <= 3
      create_button_payload(message)
    else
      create_list_payload(message)
    end
  end

  def create_button_payload(message)
    buttons = create_buttons(message.content_attributes['items'])
    json_hash = { 'buttons' => buttons }
    create_payload('button', message.outgoing_content, JSON.generate(json_hash))
  end

  def create_list_payload(message)
    rows = create_rows(message.content_attributes['items'])
    section1 = { 'rows' => rows }
    sections = [section1]
    json_hash = { :button => I18n.t('conversations.messages.whatsapp.list_button_label'), 'sections' => sections }
    create_payload('list', message.outgoing_content, JSON.generate(json_hash))
  end
end
