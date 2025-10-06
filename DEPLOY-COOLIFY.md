# ChatGon - Guía de Despliegue en Coolify

## Configuración del Proyecto en Coolify

### 1. Información Básica del Proyecto

- **Build Pack**: `Dockerfile`
- **Dockerfile Location**: `/docker/Dockerfile`
- **Docker Compose File**: `/docker-compose.production.yaml`
- **Repositorio**: Público en GitHub
- **Branch**: `main` o `develop` (según tu configuración)

### 2. Secuencia de Inicialización

La aplicación se despliega automáticamente siguiendo esta secuencia:

```
1. PostgreSQL (pgvector/pgvector:pg16)
   └── Healthcheck: pg_isready

2. Redis (redis:7-alpine)
   └── Healthcheck: redis-cli ping

3. Setup Service (servicio dedicado de inicialización)
   ├── Espera postgres y redis HEALTHY
   ├── db:prepare (crea/migra la base de datos)
   ├── setup_brand.rb (configura Brand ChatGon automáticamente)
   └── Termina exitosamente (crea marker file)

4. Rails App (espera setup completado)
   ├── Espera postgres, redis y setup
   ├── Verifica marker file de setup
   └── rails server (inicia la aplicación)

5. Sidekiq (background jobs)
   ├── Espera postgres, redis y setup
   └── Procesa trabajos en segundo plano
```

## Variables de Entorno Requeridas

### ⚠️ Variables Obligatorias (CRÍTICAS)

```bash
# Seguridad - Rails Secret
SECRET_KEY_BASE=<generar con: bundle exec rake secret>

# URL de la Aplicación
FRONTEND_URL=https://chat.monexgon.app

# Base de Datos PostgreSQL
POSTGRES_DATABASE=chatgon_production
POSTGRES_USERNAME=chatgon_user
POSTGRES_PASSWORD=<contraseña-segura>

# Redis
REDIS_PASSWORD=<contraseña-segura>
```

### 🎨 Brand Configuration (ChatGon)

```bash
# Branding ChatGon
INSTALLATION_NAME=ChatGon
BRAND_NAME=ChatGon
BRAND_URL=https://chat.monexgon.app
WIDGET_BRAND_URL=https://chat.monexgon.app
BRAND_COLOR=#2781F6
LOGO=/brand-assets/logo-cg.svg
LOGO_DARK=/brand-assets/logo-dark.svg
LOGO_THUMBNAIL=/brand-assets/logo-thumbnail.svg
DISPLAY_MANIFEST=false
```

### 🔒 Seguridad y Privacidad (Sistema Privado)

```bash
# Desactivar registro público
ENABLE_ACCOUNT_SIGNUP=false
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false
CREATE_NEW_AGENT_FROM_DASHBOARD=false
DELETE_AGENT_FROM_DASHBOARD=false

# Configuración Independiente (sin telemetría a Chatwoot)
DISABLE_TELEMETRY=true
DEPLOYMENT_ENV=self-hosted
INSTALLATION_PRICING_PLAN=enterprise
```

### 📧 Email Configuration (Opcional pero Recomendado)

```bash
MAILER_SENDER_EMAIL=ChatGon <admin@monexgon.app>
SMTP_DOMAIN=monexgon.app
SMTP_ADDRESS=smtp.hostinger.com
SMTP_PORT=587
SMTP_USERNAME=admin@monexgon.app
SMTP_PASSWORD=<contraseña-smtp>
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer

# Correo Entrante
MAILER_INBOUND_EMAIL_DOMAIN=chat.monexgon.app
RAILS_INBOUND_EMAIL_SERVICE=relay
RAILS_INBOUND_EMAIL_PASSWORD=<contraseña-segura-webhook>
```

### ⚙️ Configuración de Rendimiento

```bash
# Locale por defecto
DEFAULT_LOCALE=es

# Performance
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=10

# Storage
ACTIVE_STORAGE_SERVICE=local

# SSL (Coolify maneja esto automáticamente)
FORCE_SSL=false
```

### 📱 Mobile App (Opcional)

```bash
IOS_APP_ID=L7YLMN4634.com.chatgon.app
ANDROID_BUNDLE_ID=com.chatgon.app
ANDROID_SHA256_CERT_FINGERPRINT=AC:73:8E:DE:EB:56:EA:CC:10:87:02:A7:65:37:7B:38:D4:5D:D4:53:F8:3B:FB:D3:C6:28:64:1D:AA:08:1E:D8
ENABLE_PUSH_RELAY_SERVER=true
```

## Pasos de Despliegue en Coolify

### Paso 1: Crear Nuevo Proyecto

1. En Coolify, haz clic en **"+ New Resource"**
2. Selecciona **"Docker Compose"**
3. Conecta tu repositorio de GitHub
4. Selecciona el branch (main/develop)

### Paso 2: Configurar Build Settings

```yaml
Build Pack: Dockerfile
Dockerfile Location: /docker/Dockerfile
Docker Compose Path: /docker-compose.production.yaml
```

### Paso 3: Configurar Variables de Entorno

En la sección **Environment Variables** de Coolify, agrega TODAS las variables listadas arriba.

**⚠️ Generar Valores Seguros:**

```bash
# SECRET_KEY_BASE (ejecutar localmente)
bundle exec rake secret

# Contraseñas seguras
openssl rand -base64 32
```

### Paso 4: Configurar Dominio y SSL

1. En Coolify, ve a **Domains**
2. Agrega: `chat.monexgon.app`
3. Coolify configurará automáticamente SSL con Let's Encrypt

### Paso 5: Deploy

1. Haz clic en **"Deploy"**
2. Coolify ejecutará:
   - Build del Dockerfile
   - Inicio de servicios (postgres, redis)
   - Migraciones de base de datos
   - Configuración automática del Brand
   - Inicio de Rails y Sidekiq

### Paso 6: Verificar el Despliegue

```bash
# En Coolify, ve a Logs y verifica:
✓ PostgreSQL está corriendo y healthy
✓ Redis está corriendo y healthy
✓ Database migrated successfully
✓ Brand setup completed
✓ Rails server iniciado en puerto 3000
✓ Sidekiq procesando jobs
```

## Despliegue Desde Cero

### Primera vez (Base de datos nueva):

El **servicio setup** se ejecuta automáticamente antes de Rails/Sidekiq y configura:

1. ✅ **Migraciones de base de datos** (crea tablas, índices, etc.)
2. ✅ **Brand ChatGon** con logos y colores personalizados
3. ✅ **Todas las features enterprise** habilitadas
4. ✅ **Configuración de seguridad** (signup deshabilitado)
5. ✅ **Sistema totalmente privado** (sin telemetría)

El servicio setup **termina** después de completarse exitosamente, permitiendo que Rails y Sidekiq inicien.

### Re-despliegue (Base de datos existente):

- El script es **idempotente** (puede ejecutarse múltiples veces)
- Solo actualiza valores si han cambiado
- No afecta datos existentes (cuentas, conversaciones, etc.)

## Volúmenes Persistentes en Coolify

Coolify maneja automáticamente los siguientes volúmenes:

```yaml
postgres_data    # Base de datos PostgreSQL
redis_data       # Caché Redis
storage_data     # Archivos subidos (avatares, adjuntos)
public_data      # Assets públicos
```

**⚠️ IMPORTANTE**: No elimines estos volúmenes o perderás todos los datos.

## Troubleshooting

### Error: "Secret key base required"
**Solución**: Asegúrate de definir `SECRET_KEY_BASE` en las variables de entorno.

### Error: "Database password required"
**Solución**: Define `POSTGRES_PASSWORD` en las variables de entorno.

### Brand no se aplica correctamente
**Solución**:
```bash
# Ejecutar manualmente en Coolify shell:
docker exec -it <rails-container> bundle exec rails runner bin/setup_brand.rb
```

### Logs muestran warnings de premium features
**Solución**: El script `setup_brand.rb` los limpia automáticamente. Si persisten, reinicia la aplicación.

### Base de datos no se conecta
**Solución**: Verifica los health checks en los logs de Coolify. Asegúrate de que postgres esté healthy antes de rails.

## Comandos Útiles en Coolify

```bash
# Ver logs del servicio Setup (migraciones y Brand)
docker logs <setup-container>

# Ver logs de Rails
docker logs -f <rails-container>

# Ver logs de Sidekiq
docker logs -f <sidekiq-container>

# Ejecutar comandos en Rails
docker exec -it <rails-container> bundle exec rails console

# Re-aplicar Brand manualmente (si es necesario)
docker exec -it <rails-container> bundle exec rails runner bin/setup_brand.rb

# Verificar configuración del Brand
docker exec -it <rails-container> bundle exec rails runner "InstallationConfig.where(name: ['INSTALLATION_NAME', 'BRAND_NAME', 'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL']).each { |c| puts \"#{c.name}: #{c.value}\" }"

# Re-ejecutar el servicio setup manualmente (si necesitas re-migrar)
docker-compose run --rm setup
```

## Actualizar la Aplicación

1. Hacer push al repositorio de GitHub
2. En Coolify, ir al proyecto
3. Hacer clic en **"Redeploy"**
4. Coolify automáticamente:
   - Descarga los cambios
   - Reconstruye la imagen
   - Ejecuta migraciones
   - Re-aplica Brand (si es necesario)
   - Reinicia servicios

## Backup y Restauración

### Backup de PostgreSQL

```bash
# En Coolify, ejecutar:
docker exec <postgres-container> pg_dump -U chatgon_user chatgon_production > backup.sql
```

### Restaurar PostgreSQL

```bash
docker exec -i <postgres-container> psql -U chatgon_user chatgon_production < backup.sql
```

## Seguridad Post-Despliegue

1. ✅ Cambiar contraseñas por defecto
2. ✅ Verificar que `ENABLE_ACCOUNT_SIGNUP=false`
3. ✅ Configurar firewall en VPS (solo puertos 80, 443, 22)
4. ✅ Habilitar backups automáticos en Coolify
5. ✅ Monitorear logs regularmente

## Soporte

- **Logs**: Revisar en Coolify > Tu Proyecto > Logs
- **Status**: Verificar health checks de servicios
- **Brand**: Ejecutar `bin/setup_brand.rb` si es necesario

---

**Versión del documento**: 1.0
**Última actualización**: 2025-10-06
**ChatGon** - Sistema privado e independiente
