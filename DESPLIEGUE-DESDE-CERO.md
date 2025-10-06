# ChatGon - Despliegue Desde Cero

## 🎯 Resumen Ejecutivo

ChatGon está configurado para desplegarse **completamente desde cero** manteniendo el Brand personalizado y configuración totalmente privada.

### ✅ Características Garantizadas en Despliegue Automático

- ✅ **Brand ChatGon** aplicado automáticamente (logos, colores, nombres)
- ✅ **Sistema 100% privado** (sin registro público, sin telemetría)
- ✅ **Todas las features enterprise** habilitadas
- ✅ **Base de datos** creada y migrada automáticamente
- ✅ **Configuración idempotente** (re-ejecutable sin problemas)

---

## 📋 Secuencia de Despliegue Automático

La aplicación se despliega en el siguiente orden garantizado:

```
┌─────────────────────────────────────────────────────────┐
│ 1. POSTGRESQL                                            │
│    - Inicia servicio                                     │
│    - Healthcheck: pg_isready                            │
│    - Estado: READY ✓                                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 2. REDIS                                                 │
│    - Inicia servicio                                     │
│    - Healthcheck: redis-cli ping                        │
│    - Estado: READY ✓                                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 3. SETUP SERVICE (Migraciones y Brand)                  │
│    - Espera postgres HEALTHY (depends_on)               │
│    - Espera redis HEALTHY (depends_on)                  │
│    - Ejecuta: bundle exec rails db:prepare              │
│      → Crea base de datos si no existe                  │
│      → Ejecuta todas las migraciones                    │
│      → Carga schema                                     │
│    - Ejecuta: bundle exec rails runner bin/setup_brand.rb│
│      → Configura INSTALLATION_NAME = ChatGon            │
│      → Configura BRAND_NAME = ChatGon                   │
│      → Configura logos personalizados                   │
│      → Configura colores de marca                       │
│      → Establece DEPLOYMENT_ENV = self-hosted           │
│      → Establece INSTALLATION_PRICING_PLAN = enterprise │
│      → Habilita TODAS las features                      │
│      → Aplica configuración de seguridad                │
│      → Limpia warnings de premium de Redis              │
│    - Crea archivo marker: /tmp/chatgon-setup-complete   │
│    - Estado: COMPLETED ✓ (servicio termina)             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 4. RAILS APP                                             │
│    - Espera postgres HEALTHY (depends_on)               │
│    - Espera redis HEALTHY (depends_on)                  │
│    - Espera setup COMPLETED (depends_on)                │
│    - Verifica archivo marker existe                     │
│    - Inicia servidor Rails en puerto 3000               │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 5. SIDEKIQ                                               │
│    - Espera postgres HEALTHY (depends_on)               │
│    - Espera redis HEALTHY (depends_on)                  │
│    - Espera setup COMPLETED (depends_on)                │
│    - Inicia procesamiento de trabajos en background     │
│    - Healthcheck: pgrep -f sidekiq                      │
└─────────────────────────────────────────────────────────┘
```

### 🎯 Ventajas de esta Secuencia

1. **Servicio Setup Dedicado**: Las migraciones y configuración del Brand se ejecutan en un servicio separado que termina al completarse
2. **Orden Garantizado**: Rails y Sidekiq NO inician hasta que el setup se complete exitosamente
3. **Idempotente**: El servicio setup puede re-ejecutarse sin problemas (on-failure restart)
4. **Visible en Logs**: El progreso del setup es claramente visible en Coolify
5. **Sin Condiciones de Carrera**: Rails y Sidekiq siempre encontrarán la DB y Brand configurados

---

## 🔧 Configuración Técnica

### Health Checks Configurados

#### PostgreSQL
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U chatgon_user"]
  interval: 10s
  timeout: 5s
  retries: 5
```

#### Redis
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 5s
  retries: 5
```

#### Sidekiq
```yaml
healthcheck:
  test: ["CMD", "pgrep", "-f", "sidekiq"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Dependencias Garantizadas

```yaml
rails:
  depends_on:
    postgres:
      condition: service_healthy  # ← Espera a que postgres esté HEALTHY
    redis:
      condition: service_healthy  # ← Espera a que redis esté HEALTHY

sidekiq:
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

Esto **garantiza** que Rails y Sidekiq NO iniciarán hasta que postgres y redis estén completamente operativos.

---

## 🎨 Script de Inicialización del Brand

### Ubicación
`bin/setup_brand.rb`

### ¿Cuándo se ejecuta?
Automáticamente en cada despliegue de producción a través del **servicio setup dedicado** (ver `docker/entrypoints/setup.sh`)

### ¿Qué hace?

#### 1. Configura el Brand desde Variables de Entorno
```ruby
configs = {
  'INSTALLATION_NAME' => ENV['INSTALLATION_NAME'],        # ChatGon
  'BRAND_NAME' => ENV['BRAND_NAME'],                      # ChatGon
  'BRAND_URL' => ENV['BRAND_URL'],                        # https://chat.monexgon.app
  'WIDGET_BRAND_URL' => ENV['WIDGET_BRAND_URL'],          # https://chat.monexgon.app
  'BRAND_COLOR' => ENV['BRAND_COLOR'],                    # #2781F6
  'LOGO' => ENV['LOGO'],                                   # /brand-assets/logo-cg.svg
  'LOGO_DARK' => ENV['LOGO_DARK'],                        # /brand-assets/logo-dark.svg
  'LOGO_THUMBNAIL' => ENV['LOGO_THUMBNAIL'],              # /brand-assets/logo-thumbnail.svg
  'DEPLOYMENT_ENV' => 'self-hosted',
  'INSTALLATION_PRICING_PLAN' => 'enterprise',
  'INSTALLATION_PRICING_PLAN_QUANTITY' => '999999'
}
```

#### 2. Aplica Configuración de Seguridad (Sistema Privado)
```ruby
security_configs = {
  'ENABLE_ACCOUNT_SIGNUP' => 'false',                      # ← Sin registro público
  'CREATE_NEW_ACCOUNT_FROM_DASHBOARD' => 'false',         # ← Sin creación de cuentas
  'CREATE_NEW_AGENT_FROM_DASHBOARD' => 'false',           # ← Sin creación de agentes
  'DELETE_AGENT_FROM_DASHBOARD' => 'false'                # ← Sin eliminación de agentes
}
```

#### 3. Habilita TODAS las Features Enterprise
```ruby
# Lee config/features.yml y habilita cada feature no deprecada
features_config.each do |feature_config|
  next if feature_config['deprecated']

  feature = Feature.find_or_initialize_by(name: feature_config['name'])
  feature.enabled = true
  feature.save!
end
```

#### 4. Limpia Warnings de Premium
```ruby
Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
```

### ¿Es seguro re-ejecutarlo?
**SÍ**, el script es **idempotente**:
- Solo actualiza valores si han cambiado
- No elimina datos existentes
- Puede ejecutarse múltiples veces sin problemas
- No afecta cuentas, usuarios, conversaciones existentes

---

## 🚀 Despliegue en Coolify - Paso a Paso

### Pre-requisitos
1. ✅ VPS con Coolify instalado
2. ✅ Repositorio público en GitHub con el código
3. ✅ Dominio configurado (chat.monexgon.app)

### Paso 1: Configurar Proyecto en Coolify

1. **Nuevo Proyecto**: Haz clic en "+ New Resource"
2. **Tipo**: Docker Compose
3. **Repositorio**: Conecta tu repositorio de GitHub
4. **Branch**: `main` o `develop`

### Paso 2: Configuración Build

```
Build Pack: Dockerfile
Dockerfile Location: /docker/Dockerfile
Docker Compose File: /docker-compose.production.yaml
```

### Paso 3: Variables de Entorno

**IMPORTANTE**: Copia TODAS las variables de `.env.coolify.example` a Coolify.

**Variables OBLIGATORIAS que debes generar:**

```bash
# Generar SECRET_KEY_BASE (localmente con Ruby)
bundle exec rake secret

# Generar contraseñas seguras
openssl rand -base64 32
```

Configura en Coolify:
- `SECRET_KEY_BASE=<valor-generado>`
- `POSTGRES_PASSWORD=<contraseña-segura>`
- `REDIS_PASSWORD=<contraseña-segura>`
- `SMTP_PASSWORD=<tu-smtp-password>` (si usas email)
- `RAILS_INBOUND_EMAIL_PASSWORD=<contraseña-segura>`

**Variables de Brand** (ya configuradas):
- `INSTALLATION_NAME=ChatGon`
- `BRAND_NAME=ChatGon`
- `LOGO=/brand-assets/logo-cg.svg`
- etc. (ver `.env.coolify.example`)

### Paso 4: Configurar Dominio

1. En Coolify > Domains
2. Agregar: `chat.monexgon.app`
3. Coolify configura SSL automáticamente con Let's Encrypt

### Paso 5: Deploy

Haz clic en **"Deploy"**

### Paso 6: Verificar en Logs de Coolify

Busca los logs del servicio **"setup"** primero:

```
========================================
ChatGon Setup: Migrations & Brand Config
========================================
✓ PostgreSQL is ready
✓ Redis is ready
✓ Gems installed
========================================
Running database migrations...
========================================
✓ Database migrations completed successfully
========================================
Configuring ChatGon Brand...
========================================
✓ Updated INSTALLATION_NAME to ChatGon
✓ Updated BRAND_NAME to ChatGon
✓ Updated LOGO to /brand-assets/logo-cg.svg
✓ Enabled 50+ features
✓ Security: ENABLE_ACCOUNT_SIGNUP = false
✓ Brand configuration completed successfully
========================================
✓ ChatGon Setup Completed Successfully
========================================
  - Database migrated
  - Brand configured (ChatGon)
  - All features enabled
  - Security settings applied
========================================
Setup service completed. Ready for Rails and Sidekiq to start.
```

Luego verifica los logs de **"rails"**:

```
Waiting for ChatGon setup service to complete...
✓ Setup service completed. Starting Rails server...
✓ Rails server started on port 3000
```

Y finalmente **"sidekiq"**:

```
✓ Sidekiq started
✓ Processing background jobs
```

---

## 🔍 Verificación Post-Despliegue

### Verificar Brand en Base de Datos

```bash
# Ejecutar en Coolify Shell
docker exec -it <rails-container> bundle exec rails runner "
  InstallationConfig.where(
    name: ['INSTALLATION_NAME', 'BRAND_NAME', 'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL']
  ).each { |c| puts \"#{c.name}: #{c.value}\" }
"
```

**Salida esperada:**
```
INSTALLATION_NAME: ChatGon
BRAND_NAME: ChatGon
LOGO: /brand-assets/logo-cg.svg
LOGO_DARK: /brand-assets/logo-dark.svg
LOGO_THUMBNAIL: /brand-assets/logo-thumbnail.svg
```

### Verificar Features Habilitadas

```bash
docker exec -it <rails-container> bundle exec rails runner "
  puts \"Features habilitadas: #{Feature.where(enabled: true).count}\"
"
```

### Verificar Configuración de Seguridad

```bash
docker exec -it <rails-container> bundle exec rails runner "
  config = InstallationConfig.find_by(name: 'ENABLE_ACCOUNT_SIGNUP')
  puts \"Registro público: #{config.value}\"  # Debe ser false
"
```

---

## 🔄 Re-despliegue y Actualizaciones

### Actualizar Código

1. Push al repositorio de GitHub
2. En Coolify, clic en "Redeploy"
3. Coolify automáticamente:
   - Descarga cambios
   - Reconstruye imagen Docker
   - Ejecuta migraciones nuevas
   - Re-aplica Brand (sin afectar datos)
   - Reinicia servicios

### Re-aplicar Brand Manualmente (si es necesario)

```bash
docker exec -it <rails-container> bundle exec rails runner bin/setup_brand.rb
```

---

## 🛡️ Seguridad y Privacidad

### ✅ Configuración Garantizada

| Configuración | Valor | Descripción |
|--------------|-------|-------------|
| `ENABLE_ACCOUNT_SIGNUP` | `false` | Sin registro público |
| `DISABLE_TELEMETRY` | `true` | Sin datos a servidores Chatwoot |
| `DEPLOYMENT_ENV` | `self-hosted` | Instalación independiente |
| `INSTALLATION_PRICING_PLAN` | `enterprise` | Todas las features |
| `CREATE_NEW_ACCOUNT_FROM_DASHBOARD` | `false` | Control total de cuentas |

### Volúmenes Persistentes

Coolify maneja automáticamente:
- `postgres_data` - Base de datos (NO eliminar)
- `redis_data` - Caché
- `storage_data` - Archivos subidos
- `public_data` - Assets públicos

---

## 📚 Documentación Adicional

- **Guía Completa de Coolify**: `DEPLOY-COOLIFY.md`
- **Variables de Entorno**: `.env.coolify.example`
- **Script de Brand**: `bin/setup_brand.rb`
- **Entrypoint**: `docker/entrypoints/rails.sh`

---

## 🆘 Troubleshooting

### ❌ Brand no se aplica

**Causa**: Script no se ejecutó o falló

**Solución**:
```bash
# Re-ejecutar manualmente
docker exec -it <rails-container> bundle exec rails runner bin/setup_brand.rb
```

### ❌ Base de datos no se conecta

**Causa**: Postgres no está healthy antes de Rails

**Solución**: Los health checks garantizan el orden correcto. Verificar logs:
```bash
docker logs <postgres-container>
```

### ❌ Features no habilitadas

**Causa**: Tabla `features` no existe (versión antigua)

**Solución**: Ejecutar migraciones:
```bash
docker exec -it <rails-container> bundle exec rails db:migrate
```

### ❌ Warnings de premium features

**Causa**: Redis cache con warnings antiguos

**Solución**: El script limpia automáticamente. Si persiste, reiniciar:
```bash
docker restart <rails-container>
```

---

## ✅ Checklist de Despliegue Exitoso

- [ ] Postgres iniciado y healthy
- [ ] Redis iniciado y healthy
- [ ] Migraciones ejecutadas sin errores
- [ ] Brand setup completado (ver logs)
- [ ] Rails server corriendo en puerto 3000
- [ ] Sidekiq procesando jobs
- [ ] Dominio accesible con SSL
- [ ] Login funcional
- [ ] Brand visible (logos, colores, nombre)
- [ ] Sin warnings de premium features
- [ ] Registro público deshabilitado

---

**ChatGon** - Sistema totalmente privado e independiente
**Versión**: 1.0
**Fecha**: 2025-10-06
