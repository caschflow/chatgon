class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    # Check for duplicate QR events (Evolution API fix)
    if duplicate_qr_event?
      Rails.logger.info("Rejected duplicate QR event for #{params[:phone_number]}")
      head :ok  # Return 200 to avoid Evolution API retries
      return
    end

    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def duplicate_qr_event?
    # Extract messages from payload (supports both 360Dialog and WhatsApp Cloud formats)
    messages = extract_messages_from_payload
    return false if messages.blank?

    message = messages.first
    return false unless message.is_a?(Hash)
    return false unless message[:type] == 'image' || message['type'] == 'image'

    # Check caption for QR keywords (Evolution API sends QR as image with caption)
    caption = extract_caption_from_message(message)
    return false unless qr_related_caption?(caption)

    # Check Redis for recent QR from this number
    phone = params[:phone_number]
    message_id = message[:id] || message['id']
    qr_key = "whatsapp:qr_event:#{phone}:#{message_id}"

    # If already processed, it's a duplicate
    if Redis::Alfred.get(qr_key)
      Rails.logger.info("Duplicate QR detected - Key: #{qr_key}")
      return true
    end

    # Mark as processed for 10 minutes
    Redis::Alfred.setex(qr_key, true, 10.minutes)
    Rails.logger.info("First QR event - Caching key: #{qr_key}")
    false
  rescue StandardError => e
    Rails.logger.error("Error in duplicate_qr_event?: #{e.message}")
    false # On error, don't block the message
  end

  def extract_messages_from_payload
    # Try WhatsApp Cloud API format
    messages = params.dig(:entry, 0, :changes, 0, :value, :messages)
    return messages if messages.present?

    # Try direct messages format (Evolution API)
    messages = params[:messages]
    return messages if messages.present?

    # Try alternative format
    params.dig(:data, :messages)
  end

  def extract_caption_from_message(message)
    # Try different caption paths
    caption = message.dig(:image, :caption) ||
              message.dig('image', 'caption') ||
              message[:caption] ||
              message['caption']

    caption.to_s.downcase
  end

  def qr_related_caption?(caption)
    return false if caption.blank?

    # Check for QR-related keywords in multiple languages
    qr_keywords = ['qr', 'código', 'codigo', 'escanear', 'scan', 'whatsapp', 'vincular', 'conectar']
    qr_keywords.any? { |keyword| caption.include?(keyword) }
  end

  def valid_token?(token)
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end

  def inactive_whatsapp_number?
    phone_number = params[:phone_number]
    return false if phone_number.blank?

    inactive_numbers = GlobalConfig.get_value('INACTIVE_WHATSAPP_NUMBERS').to_s
    return false if inactive_numbers.blank?

    inactive_numbers_array = inactive_numbers.split(',').map(&:strip)
    inactive_numbers_array.include?(phone_number)
  end
end
