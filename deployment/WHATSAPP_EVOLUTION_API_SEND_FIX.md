# 🔧 Solución: Error al Enviar Mensajes WhatsApp con Evolution API

## 🐛 Problema Reportado

Cuando se intenta responder un mensaje desde ChatGon a través de WhatsApp (Evolution API):
- ✅ **Recibe mensajes correctamente**
- ❌ **NO envía mensajes** (respuestas)
- ❌ Aparece el error: **"cw.message.notsent"**

---

## 🔍 Causa Raíz

### Incompatibilidad de Formato de Respuesta

ChatGon está diseñado para **WhatsApp Business API oficial** (Meta/360Dialog), que retorna:

```json
{
  "messages": [
    {
      "id": "wamid.xxx"
    }
  ]
}
```

**Evolution API retorna un formato diferente** (similar pero no idéntico):

```json
{
  "key": {
    "remoteJid": "xxx@s.whatsapp.net",
    "fromMe": true,
    "id": "xxx"
  },
  "message": { ... },
  "messageTimestamp": "xxx"
}
```

### Problema en el Código

**Archivo:** `app/services/whatsapp/providers/base_service.rb` línea 34-41

```ruby
def process_response(response, message)
  parsed_response = response.parsed_response
  if response.success? && parsed_response['error'].blank?
    parsed_response['messages'].first['id']  # ❌ ESTO FALLA con Evolution API
  else
    handle_error(response, message)
    nil
  end
end
```

Cuando Evolution API envía la respuesta:
1. `response.success?` puede ser `true`
2. PERO `parsed_response['messages']` es `nil` (no existe esa clave)
3. Intenta hacer `nil.first` → Error
4. Cae en el `else` → marca como `failed`
5. Frontend muestra "cw.message.notsent"

---

## ✅ SOLUCIONES

### Solución 1: Crear Provider Personalizado para Evolution API (RECOMENDADO)

Crear un provider específico que maneje el formato de Evolution API.

#### Paso 1: Crear el Provider

**Archivo nuevo:** `app/services/whatsapp/providers/whatsapp_evolution_service.rb`

```ruby
class Whatsapp::Providers::WhatsappEvolutionService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info, message)
    # Evolution API uses simplified template format
    response = HTTParty.post(
      "#{api_base_path}/sendText/#{instance_name}",
      headers: api_headers,
      body: {
        number: phone_number,
        text: message.outgoing_content
      }.to_json
    )

    process_evolution_response(response, message)
  end

  def sync_templates
    # Evolution API doesn't support template syncing
    # Mark as updated to avoid repeated attempts
    whatsapp_channel.mark_message_templates_updated
  end

  def validate_provider_config?
    response = HTTParty.get(
      "#{api_base_path}/fetchInstances",
      headers: api_headers
    )
    response.success? && response.parsed_response.is_a?(Array)
  end

  def api_headers
    {
      'apikey' => whatsapp_channel.provider_config['api_key'],
      'Content-Type' => 'application/json'
    }
  end

  def media_url(media_id)
    # Evolution API handles media differently
    media_id
  end

  private

  def api_base_path
    whatsapp_channel.provider_config['api_base_url'] || ENV.fetch('EVOLUTION_API_URL', 'http://localhost:8080')
  end

  def instance_name
    whatsapp_channel.provider_config['instance_name'] || whatsapp_channel.phone_number.gsub(/\D/, '')
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/message/sendText/#{instance_name}",
      headers: api_headers,
      body: {
        number: phone_number,
        text: message.outgoing_content
      }.to_json
    )

    process_evolution_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = attachment.file_type

    # Evolution API endpoint based on type
    endpoint = case type
               when 'image' then 'sendMedia'
               when 'audio' then 'sendMedia'
               when 'video' then 'sendMedia'
               else 'sendMedia'
               end

    response = HTTParty.post(
      "#{api_base_path}/message/#{endpoint}/#{instance_name}",
      headers: api_headers,
      body: {
        number: phone_number,
        mediatype: type,
        media: attachment.download_url,
        caption: message.outgoing_content
      }.to_json
    )

    process_evolution_response(response, message)
  end

  def send_interactive_text_message(phone_number, message)
    # Evolution API doesn't fully support interactive messages
    # Fall back to text with options listed
    items_text = message.content_attributes['items'].map.with_index(1) do |item, index|
      "#{index}. #{item['title']}"
    end.join("\n")

    full_text = "#{message.outgoing_content}\n\n#{items_text}"

    response = HTTParty.post(
      "#{api_base_path}/message/sendText/#{instance_name}",
      headers: api_headers,
      body: {
        number: phone_number,
        text: full_text
      }.to_json
    )

    process_evolution_response(response, message)
  end

  def process_evolution_response(response, message)
    parsed_response = response.parsed_response

    Rails.logger.info "[Evolution API] Response: #{parsed_response.inspect}"

    if response.success? && evolution_success?(parsed_response)
      # Evolution API returns the message ID in different formats
      message_id = extract_message_id(parsed_response)
      Rails.logger.info "[Evolution API] Message sent successfully. ID: #{message_id}"
      message_id
    else
      handle_evolution_error(response, message)
      nil
    end
  end

  def evolution_success?(parsed_response)
    # Evolution API can return different success indicators
    return true if parsed_response['key'].present?
    return true if parsed_response['message'].present?
    return true if parsed_response['id'].present?
    false
  end

  def extract_message_id(parsed_response)
    # Try different paths where Evolution API might put the message ID
    parsed_response.dig('key', 'id') ||
      parsed_response['id'] ||
      parsed_response.dig('message', 'key', 'id') ||
      SecureRandom.uuid # Fallback
  end

  def handle_evolution_error(response, message)
    Rails.logger.error "[Evolution API] Error response: #{response.body}"
    return if message.blank?

    error_msg = response.parsed_response['message'] ||
                response.parsed_response['error'] ||
                'Evolution API error'

    message.external_error = error_msg
    message.status = :failed
    message.save!
  end

  def error_message(response)
    response.parsed_response['message'] || response.parsed_response['error'] || 'Unknown error'
  end
end
```

#### Paso 2: Registrar el Provider

**Archivo:** `app/models/channel/whatsapp.rb`

```ruby
# Cambiar línea 28:
PROVIDERS = %w[default whatsapp_cloud evolution].freeze

# Cambiar método provider_service (línea 42-48):
def provider_service
  case provider
  when 'whatsapp_cloud'
    Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
  when 'evolution'
    Whatsapp::Providers::WhatsappEvolutionService.new(whatsapp_channel: self)
  else
    Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: self)
  end
end
```

#### Paso 3: Configurar el Canal

Al crear/editar el canal de WhatsApp, usar:

```json
{
  "provider": "evolution",
  "provider_config": {
    "api_key": "TU_API_KEY_DE_EVOLUTION",
    "api_base_url": "https://tu-evolution-api.com",
    "instance_name": "nombre_instancia",
    "webhook_verify_token": "auto-generado"
  }
}
```

---

### Solución 2: Modificar BaseService para Soportar Múltiples Formatos (MÁS SIMPLE)

Modificar el `process_response` para detectar diferentes formatos.

**Archivo:** `app/services/whatsapp/providers/base_service.rb`

```ruby
def process_response(response, message)
  parsed_response = response.parsed_response

  if response.success? && parsed_response['error'].blank?
    # Try different response formats
    message_id = extract_message_id_from_response(parsed_response)

    if message_id.present?
      Rails.logger.info "[WhatsApp] Message sent. ID: #{message_id}"
      message_id
    else
      Rails.logger.warn "[WhatsApp] Success but no message ID found: #{parsed_response.inspect}"
      handle_error(response, message)
      nil
    end
  else
    handle_error(response, message)
    nil
  end
end

private

def extract_message_id_from_response(parsed_response)
  # WhatsApp Business API / 360Dialog format
  return parsed_response['messages']&.first&.dig('id') if parsed_response['messages'].present?

  # Evolution API format (key.id)
  return parsed_response.dig('key', 'id') if parsed_response['key'].present?

  # Evolution API alternative format
  return parsed_response['id'] if parsed_response['id'].present?

  # Evolution API nested format
  return parsed_response.dig('message', 'key', 'id') if parsed_response.dig('message', 'key', 'id').present?

  nil
end
```

---

## 📊 Comparación de Soluciones

| Aspecto | Solución 1 (Provider) | Solución 2 (Modificar Base) |
|---------|----------------------|----------------------------|
| Complejidad | Alta | Baja |
| Mantenibilidad | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Compatibilidad | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Riesgo | Bajo | Medio |
| Tiempo impl. | 30-45 min | 10 min |

**Recomendación:**
- **Corto plazo:** Usar Solución 2 (rápida)
- **Largo plazo:** Implementar Solución 1 (limpia y escalable)

---

## 🧪 Testing

### Verificar que se Solucionó:

1. **Enviar mensaje de prueba desde WhatsApp a ChatGon**
   - ✅ Debe recibirse correctamente

2. **Responder desde ChatGon**
   - ✅ No debe aparecer "cw.message.notsent"
   - ✅ Mensaje debe enviarse al WhatsApp

3. **Ver logs:**
   ```bash
   docker logs -f <CONTAINER_NAME> | grep "WhatsApp\|Evolution"

   # Debe aparecer:
   "[WhatsApp] Message sent. ID: xxx"
   # O:
   "[Evolution API] Message sent successfully. ID: xxx"
   ```

---

## 🔍 Diagnóstico

### Cómo ver el error exacto:

```bash
# En Rails console
docker exec -it <CONTAINER_NAME> bundle exec rails console

# Ver últimos mensajes fallidos
Message.where(status: :failed, message_type: :outgoing).last(5).each do |m|
  puts "ID: #{m.id}"
  puts "Error: #{m.external_error}"
  puts "Content: #{m.content}"
  puts "---"
end
```

### Verificar respuesta de Evolution API:

```bash
# Probar directamente la API
curl -X POST https://tu-evolution-api.com/message/sendText/INSTANCE_NAME \
  -H "apikey: TU_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "5215512345678",
    "text": "Test"
  }'

# Verificar formato de respuesta
```

---

## ⚙️ Configuración Completa de Evolution API

### Variables de Entorno Recomendadas:

```bash
# En .env o Coolify
EVOLUTION_API_URL=https://tu-evolution-api.com
EVOLUTION_API_KEY=tu_api_key_aqui
```

### Estructura del Inbox:

Al crear el inbox de WhatsApp con Evolution API:

```json
{
  "phone_number": "+5215512345678",
  "provider": "evolution",  // Después de implementar Solución 1
  "provider_config": {
    "api_key": "B6D711FCDE4D4FD5936544120E713976",
    "api_base_url": "https://evolution-api.monexgon.app",
    "instance_name": "chatgon_instance",
    "webhook_verify_token": "auto-generated"
  }
}
```

---

## ⚠️ IMPORTANTE: Evolution API NO es Oficial

Evolution API:
- ❌ **NO** está aprobado por Meta/WhatsApp
- ❌ Viola términos de servicio de WhatsApp
- ❌ Puede resultar en **ban permanente** de la cuenta
- ❌ No tiene soporte oficial
- ❌ APIs pueden cambiar sin aviso

### ✅ Recomendación para Producción

**Migrar a WhatsApp Business API Oficial:**

1. **WhatsApp Cloud API** (Meta):
   - Oficial y soportado
   - Gratis (solo cobran por conversaciones)
   - Requiere Meta Business Account

2. **360Dialog**:
   - Partner oficial de WhatsApp
   - Integración nativa en ChatGon
   - Soporte profesional

---

## 📞 Pasos Post-Implementación

1. **Aplicar la solución elegida**
2. **Deploy en Coolify con Force Rebuild**
3. **Probar envío de mensajes**
4. **Monitorear logs durante 1 día**
5. **Planear migración a API oficial**

---

**Última actualización:** Octubre 2025
**Versión:** ChatGon 3.x
