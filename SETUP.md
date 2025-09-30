# ChatGon - Setup Completo

## ✅ Configuración Completada

Este documento detalla toda la configuración implementada para que **ChatGon funcione completamente independiente de Chatwoot** sin necesidad de suscripciones.

## 📋 Archivos Configurados

### 1. **Archivo .env creado**
- ✅ Contiene todas las credenciales necesarias
- ✅ Variables de branding configuradas
- ✅ `DEPLOYMENT_ENV=self-hosted`
- ✅ `INSTALLATION_PRICING_PLAN=enterprise`
- ✅ `DISABLE_TELEMETRY=true`

### 2. **docker-compose.chatgon.yaml actualizado**
- ✅ `env_file: .env` agregado a **TODOS** los servicios
- ✅ Variables de ambiente para instalación enterprise
- ✅ Servicio `chatgon-brand-setup` configurado para:
  - Aplicar branding automáticamente
  - Configurar plan enterprise
  - Habilitar todas las características
  - Limpiar warnings de Redis

### 3. **bin/update_brand_config.rb**
- ✅ Corregidos nombres de archivos de logos
- ✅ Agrega `DEPLOYMENT_ENV` y `INSTALLATION_PRICING_PLAN`
- ✅ Desbloquea configuración de `BRAND_COLOR`
- ✅ Limpia warnings de premium

### 4. **config/features.yml**
- ✅ Todas las características habilitadas (incluyendo premium)
- ✅ No requiere modificaciones (manejado por script)

## 🚀 Cómo Iniciar ChatGon

### Primera vez (Instalación limpia):

```bash
# 1. Verificar que existe el archivo .env
ls -la .env

# 2. Iniciar todos los servicios
docker-compose -f docker-compose.chatgon.yaml up -d

# 3. Ver logs del setup de branding (opcional)
docker-compose -f docker-compose.chatgon.yaml logs chatgon-brand-setup

# 4. Acceder a la aplicación
# http://localhost:3000 o tu dominio configurado
```

### Actualizar branding en instalación existente:

```bash
# 1. Modificar variables en .env
nano .env

# 2. Ejecutar el servicio de brand setup
docker-compose -f docker-compose.chatgon.yaml up chatgon-brand-setup

# 3. Reiniciar la aplicación
docker-compose -f docker-compose.chatgon.yaml restart chatgon-app
```

## 🎨 Variables de Branding

Puedes personalizar estas variables en el archivo `.env`:

```bash
INSTALLATION_NAME=ChatGon
BRAND_NAME=ChatGon
BRAND_URL=https://chat.monexgon.app
WIDGET_BRAND_URL=https://chat.monexgon.app
BRAND_COLOR=#2781F6                          # Color principal (hex)
LOGO=/brand-assets/logo-cg.svg               # Logo claro
LOGO_DARK=/brand-assets/logo-dark.svg        # Logo oscuro
LOGO_THUMBNAIL=/brand-assets/logo-thumbnail.svg  # Favicon
DISPLAY_MANIFEST=false                       # No mostrar metadata Chatwoot
```

## 🔓 Características Enterprise Habilitadas

Todas estas características están disponibles **SIN SUSCRIPCIÓN**:

### ✅ Características Premium Desbloqueadas:
- `disable_branding` - Deshabilitar marca Chatwoot
- `audit_logs` - Logs de auditoría
- `sla` - Service Level Agreements
- `help_center_embedding_search` - Búsqueda con embeddings
- `captain_integration` - Integración Captain AI
- `captain_integration_v2` - Captain V2
- `custom_roles` - Roles personalizados
- `advanced_search` - Búsqueda avanzada
- `advanced_search_indexing` - Indexación avanzada
- `saml` - Autenticación SAML

### ✅ Características Internas Habilitadas:
- `inbox_view` - Vista de inbox mejorada
- `shopify_integration` - Integración Shopify
- `search_with_gin` - Búsqueda con GIN index
- `channel_voice` - Canal de voz
- `crm_v2` - CRM versión 2
- `assignment_v2` - Asignación mejorada
- `reply_mailer_migration` - Nuevo sistema de email

### ✅ Todas las demás características estándar:
- Canales: Email, Facebook, Twitter, Instagram, WhatsApp, Website
- Automatizaciones
- Macros
- Respuestas predefinidas
- Etiquetas
- Atributos personalizados
- Bots de agentes
- Centro de ayuda
- Campañas
- Reportes
- CRM
- Integraciones (Linear, Notion, Slack, etc.)

## 🔍 Verificación del Sistema

### Verificar que el branding se aplicó:

```bash
# Ver logs del setup
docker-compose -f docker-compose.chatgon.yaml logs chatgon-brand-setup
```

Deberías ver:
```
✓ Updated INSTALLATION_NAME to ChatGon
✓ Updated BRAND_NAME to ChatGon
✓ Updated BRAND_COLOR to #2781F6
✓ Updated DEPLOYMENT_ENV to self-hosted
✓ Updated INSTALLATION_PRICING_PLAN to enterprise
✓ Enabled XX features
✓ Cleared premium config warnings from Redis
✓ Brand configuration completed successfully
✓ ChatGon configured as independent installation
✓ All enterprise features enabled
```

### Verificar servicios corriendo:

```bash
docker-compose -f docker-compose.chatgon.yaml ps
```

Deberías ver:
- `chatgon-app` - running
- `chatgon-sidekiq` - running
- `chatgon-db` - running (healthy)
- `chatgon-redis` - running (healthy)

### Verificar configuración en la base de datos:

```bash
# Conectar a Rails console
docker exec -it chatgon-app bundle exec rails console

# Verificar plan
InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN').value
# => "enterprise"

# Verificar branding
InstallationConfig.find_by(name: 'BRAND_COLOR').value
# => "#2781F6"

# Verificar deployment
InstallationConfig.find_by(name: 'DEPLOYMENT_ENV').value
# => "self-hosted"
```

## 🛠️ Scripts Disponibles

### 1. Actualizar configuración de branding:
```bash
docker exec -it chatgon-app bundle exec rails runner bin/update_brand_config.rb
```

### 2. Habilitar todas las características:
```bash
docker exec -it chatgon-app bundle exec rails runner bin/enable_all_features.rb
```

## 🔒 Seguridad

El archivo `.env` contiene credenciales sensibles:
- ✅ **NO** lo subas a Git (ya está en `.gitignore`)
- ✅ Usa contraseñas seguras para producción
- ✅ Los valores actuales son solo para desarrollo/testing

## 📊 Estado del Sistema

| Componente | Estado | Descripción |
|------------|--------|-------------|
| `.env` | ✅ Creado | Contiene todas las variables necesarias |
| `docker-compose.chatgon.yaml` | ✅ Configurado | Carga `.env` y ejecuta setup |
| `bin/update_brand_config.rb` | ✅ Actualizado | Script de configuración mejorado |
| `bin/enable_all_features.rb` | ✅ Creado | Habilita todas las características |
| Brand assets | ✅ Presentes | Logos en `public/brand-assets/` |
| Layouts | ✅ Actualizados | Inyectan `--brand-color` CSS |
| Theme config | ✅ Configurado | Usa `var(--brand-color)` |
| Features | ✅ Habilitadas | Todas las premium/internal desbloqueadas |

## 🎯 Resumen

ChatGon ahora está **100% independiente** de Chatwoot:

✅ Sin telemetría a servidores Chatwoot
✅ Sin warnings de suscripción premium
✅ Todas las características enterprise habilitadas
✅ Branding completamente personalizado
✅ Sin dependencias de Chatwoot Hub
✅ Sin límites de licencia

## 📞 Soporte

Para más información, consulta:
- `BRANDING.md` - Detalles sobre personalización de marca
- `CLAUDE.md` - Guías de desarrollo
- `docker-compose.chatgon.yaml` - Configuración de servicios
