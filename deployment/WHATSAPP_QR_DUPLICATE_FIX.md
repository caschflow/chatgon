# 🔧 Solución: QR de WhatsApp Duplicado (Evolution API)

## 🐛 Problema Reportado

Evolution API está enviando **múltiples veces** la imagen del QR code a ChatGon cuando se intenta vincular WhatsApp, cuando debería enviarse **solo una vez**.

---

## 🔍 Análisis del Problema

### Causas Identificadas

ChatGon/Chatwoot **NO** tiene soporte nativo para Evolution API. El sistema está diseñado para:
- **360Dialog** (proveedor oficial WhatsApp Business)
- **WhatsApp Cloud API** (Meta/Facebook oficial)

Evolution API es un **wrapper no oficial** que envía webhooks simulando la API oficial.

### Por qué se duplica el QR:

1. **Evolution API envía múltiples webhooks del mismo evento**
   - El evento de "QR generado" se dispara varias veces
   - No respeta el formato estándar de WhatsApp Business API

2. **Sin `source_id` único o con el mismo `source_id`**
   - ChatGon deduplica mensajes usando `source_id` (línea 29 de `incoming_message_base_service.rb`)
   - Si Evolution API no envía `source_id` o envía el mismo, no se deduplica

3. **QR enviado como mensaje de imagen normal**
   - Evolution API envía el QR como un mensaje de tipo "image"
   - ChatGon lo procesa como cualquier mensaje normal
   - No hay detección especial de "es un QR, no duplicar"

---

## 🛠️ Soluciones Disponibles

### Solución 1: Configurar Evolution API (RECOMENDADO)

Evita que Evolution API envíe múltiples webhooks del mismo evento.

#### Pasos:

1. **Acceder a la configuración de Evolution API**

2. **Configurar el webhook correctamente:**
   ```json
   {
     "webhook": {
       "url": "https://chat.monexgon.app/webhooks/whatsapp/PHONE_NUMBER",
       "events": {
         "QRCODE_UPDATED": false,  // ❌ Deshabilitar duplicados
         "CONNECTION_UPDATE": true,
         "MESSAGES_UPSERT": true,
         "MESSAGES_UPDATE": true,
         "SEND_MESSAGE": true
       },
       "webhook_by_events": false,  // IMPORTANTE
       "webhook_base64": false
     }
   }
   ```

3. **Opciones específicas:**
   - `QRCODE_UPDATED: false` - Deshabilita envío automático de QR
   - `webhook_by_events: false` - Evita múltiples webhooks por evento
   - `webhook_base64: false` - Envía URL de imagen en lugar de base64

4. **Obtener QR manualmente (si es necesario):**
   ```bash
   # API de Evolution para obtener QR
   curl -X GET https://tu-evolution-api.com/instance/INSTANCE_NAME/qr \
     -H "apikey: TU_API_KEY"
   ```

---

### Solución 2: Agregar Deduplicación en ChatGon

Modificar el código de ChatGon para detectar y deduplic QR codes duplicados.

#### Implementación:

**Archivo:** `app/services/whatsapp/incoming_message_base_service.rb`

```ruby
# Agregar después de la línea 28
def process_messages
  # We don't support reactions & ephemeral message now
  return if unprocessable_message_type?(message_type)

  # Existing deduplication
  return if find_message_by_source_id(@processed_params[:messages].first[:id]) || message_under_process?

  # NEW: Deduplicate QR codes (Evolution API fix)
  return if qr_code_duplicate?

  cache_message_source_id_in_redis
  set_contact
  # ... rest of the method
end

private

# NEW METHOD: Detect QR code duplicates
def qr_code_duplicate?
  message = @processed_params[:messages].first

  # Check if it's an image message (QR codes are sent as images)
  return false unless message[:type] == 'image'

  # Check if caption contains QR-related keywords
  caption = message.dig(:image, :caption).to_s.downcase
  is_qr = caption.include?('qr') ||
          caption.include?('código') ||
          caption.include?('escanear') ||
          caption.include?('scan')

  return false unless is_qr

  # Check Redis for recent QR message from same contact
  qr_key = format('whatsapp:qr:%s', message[:from])

  if Redis::Alfred.get(qr_key)
    Rails.logger.info "Skipping duplicate QR code from #{message[:from]}"
    return true
  end

  # Cache QR for 5 minutes to prevent duplicates
  Redis::Alfred.setex(qr_key, true, 5.minutes)
  false
end
```

**Explicación:**
1. Detecta mensajes de tipo "image"
2. Verifica si el caption contiene palabras relacionadas a QR
3. Usa Redis para cachear QR recientes (5 minutos)
4. Bloquea duplicados del mismo remitente en ese período

---

### Solución 3: Filtrar a Nivel de Webhook

Agregar lógica en el controlador de webhook para rechazar duplicados antes de procesarlos.

#### Implementación:

**Archivo:** `app/controllers/webhooks/whatsapp_controller.rb`

```ruby
class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    # NEW: Check for duplicate QR events
    if duplicate_qr_event?
      Rails.logger.info("Rejected duplicate QR event for #{params[:phone_number]}")
      head :ok  # Return 200 to avoid Evolution API retries
      return
    end

    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  # NEW METHOD
  def duplicate_qr_event?
    # Check if payload contains QR image
    messages = params.dig(:entry, 0, :changes, 0, :value, :messages)
    return false if messages.blank?

    message = messages.first
    return false unless message[:type] == 'image'

    # Check caption for QR keywords
    caption = message.dig(:image, :caption).to_s.downcase
    is_qr = caption.include?('qr') || caption.include?('código')
    return false unless is_qr

    # Check Redis for recent QR from this number
    phone = params[:phone_number]
    message_id = message[:id]
    qr_key = "whatsapp:qr_event:#{phone}:#{message_id}"

    # If already processed, it's a duplicate
    return true if Redis::Alfred.get(qr_key)

    # Mark as processed for 10 minutes
    Redis::Alfred.setex(qr_key, true, 10.minutes)
    false
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
```

---

## 🔍 Diagnóstico

### Cómo verificar si es el problema de Evolution API:

1. **Revisar logs de Rails:**
   ```bash
   docker logs <CONTAINER_NAME> | grep "whatsapp" | grep "qr" -i
   ```

2. **Ver webhooks recibidos:**
   ```bash
   # En Rails console
   docker exec -it <CONTAINER_NAME> bundle exec rails console

   # Revisar mensajes recientes del inbox WhatsApp
   inbox = Inbox.find_by(channel_type: 'Channel::Whatsapp')
   inbox.messages.where(message_type: :incoming).last(10).each do |m|
     puts "ID: #{m.id} | Source: #{m.source_id} | Content: #{m.content}"
   end
   ```

3. **Verificar payload de Evolution API:**
   - Activar logs de webhooks en Evolution API
   - Verificar cuántos POST se envían por el mismo QR
   - Revisar si tienen el mismo `message_id`

---

## ✅ Implementación Recomendada

### Paso 1: Configurar Evolution API (hacer primero)

1. Deshabilitar `QRCODE_UPDATED` en webhooks
2. Configurar `webhook_by_events: false`
3. Obtener QR manualmente si es necesario

### Paso 2: Si el problema persiste, aplicar Solución 3

La Solución 3 (filtro a nivel webhook) es la más efectiva porque:
- ✅ No procesa el evento duplicado en absoluto
- ✅ Retorna 200 para evitar reintentos de Evolution API
- ✅ Usa Redis para deduplicación rápida
- ✅ No requiere cambios profundos en el código

### Paso 3: Monitorear

```bash
# Ver logs en tiempo real
docker logs -f <CONTAINER_NAME> | grep "QR\|qr"

# Verificar Redis
docker exec -it <REDIS_CONTAINER> redis-cli -a $REDIS_PASSWORD
KEYS whatsapp:qr*
```

---

## 📊 Comparación de Soluciones

| Solución | Efectividad | Complejidad | Requiere Cambio de Código |
|----------|-------------|-------------|---------------------------|
| 1. Configurar Evolution API | ⭐⭐⭐⭐⭐ | Baja | ❌ No |
| 2. Deduplicar en Service | ⭐⭐⭐ | Media | ✅ Sí |
| 3. Filtrar en Webhook | ⭐⭐⭐⭐ | Media | ✅ Sí |

**Recomendación:** Intentar Solución 1 primero, aplicar Solución 3 si persiste.

---

## 🚨 Consideraciones Importantes

### ⚠️ Evolution API NO es Oficial

Evolution API es un wrapper no oficial de WhatsApp que:
- ❌ **NO** está aprobado por Meta/WhatsApp
- ❌ Puede violar términos de servicio de WhatsApp
- ❌ Puede resultar en **ban de cuenta**
- ❌ No tiene soporte garantizado
- ❌ El formato de webhooks puede cambiar sin aviso

### ✅ Alternativas Oficiales

Considera migrar a proveedores oficiales:

1. **WhatsApp Business API (Meta)**
   - Oficial y soportado
   - Estable y confiable
   - Costo por conversación

2. **360Dialog**
   - Partner oficial de WhatsApp
   - Integración nativa en ChatGon
   - Soporte profesional

---

## 📞 Soporte

Si el problema persiste después de aplicar estas soluciones:

1. Verificar logs de Evolution API
2. Revisar configuración de webhooks
3. Contactar soporte de Evolution API
4. Considerar migración a proveedor oficial

---

## 🧪 Testing

Después de aplicar la solución:

1. **Limpiar sesión de WhatsApp:**
   - Desconectar en Evolution API
   - Limpiar caché de Redis: `KEYS whatsapp:qr* | xargs DEL`

2. **Iniciar nueva vinculación:**
   - Generar nuevo QR
   - Verificar que solo se recibe **UNA** imagen en ChatGon

3. **Verificar logs:**
   ```bash
   # Debe aparecer solo UNA vez:
   "Processing WhatsApp message"
   "Creating message with type: image"
   ```

---

**Última actualización:** Octubre 2025
**Versión:** ChatGon 3.x
