# ChatGon en Coolify - Guía Paso a Paso

## 📋 Pre-requisitos

Antes de comenzar, asegúrate de tener:

- ✅ VPS con Coolify instalado y funcionando
- ✅ Dominio configurado y apuntando al VPS (`chat.monexgon.app`)
- ✅ Repositorio público de GitHub con el código de ChatGon
- ✅ Acceso al panel de Coolify

---

## 🚀 Paso 1: Crear Nuevo Proyecto en Coolify

### 1.1 Acceder a Coolify
1. Abre tu panel de Coolify en el navegador
2. Inicia sesión con tus credenciales

### 1.2 Crear Recurso
1. Haz clic en **"+ New Resource"** (botón azul)
2. Selecciona **"Docker Compose"**

### 1.3 Conectar Repositorio
1. Selecciona **"Public Repository"** (repositorio público de GitHub)
2. Ingresa la URL del repositorio de ChatGon
3. Selecciona el branch: **`develop`** (o `main` según tu configuración)

### 1.4 Configuración del Build
En la configuración del proyecto, ingresa:

| Campo | Valor |
|-------|-------|
| **Build Pack** | `Dockerfile` |
| **Dockerfile Location** | `/docker/Dockerfile` |
| **Docker Compose File** | `/docker-compose.production.yaml` |

---

## ⚙️ Paso 2: Configurar Variables de Entorno

### 2.1 Ir a Environment Variables
1. En el proyecto de Coolify, ve a la pestaña **"Environment Variables"**
2. Haz clic en **"Add Variable"**

### 2.2 Generar Valores Seguros

**ANTES de agregar las variables**, genera estos valores:

```bash
# Para SECRET_KEY_BASE (si tienes Ruby/Rails localmente)
bundle exec rake secret

# O usa este comando alternativo (64 caracteres)
openssl rand -base64 64

# Para las contraseñas (32 caracteres)
openssl rand -base64 32
```

### 2.3 Variables OBLIGATORIAS (Generar Primero)

Agrega estas variables **UNA POR UNA** en Coolify:

#### 🔐 Seguridad

```bash
SECRET_KEY_BASE=<pegar-valor-generado-con-rake-secret>
```

#### 🌐 Aplicación

```bash
FRONTEND_URL=https://chat.monexgon.app
```

#### 🗄️ Base de Datos

```bash
POSTGRES_DATABASE=chatgon_production
POSTGRES_USERNAME=chatgon_user
POSTGRES_PASSWORD=<pegar-valor-generado-con-openssl-1>
```

#### 🔴 Redis

```bash
REDIS_PASSWORD=<pegar-valor-generado-con-openssl-2>
```

### 2.4 Variables de BRAND (Copiar tal cual)

```bash
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

### 2.5 Variables de SEGURIDAD (Sistema Privado)

```bash
ENABLE_ACCOUNT_SIGNUP=false
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false
CREATE_NEW_AGENT_FROM_DASHBOARD=false
DELETE_AGENT_FROM_DASHBOARD=false
DISABLE_TELEMETRY=true
DEPLOYMENT_ENV=self-hosted
INSTALLATION_PRICING_PLAN=enterprise
```

### 2.6 Variables de CONFIGURACIÓN GENERAL

```bash
DEFAULT_LOCALE=es
FORCE_SSL=false
ACTIVE_STORAGE_SERVICE=local
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=10
```

### 2.7 Variables de EMAIL (Opcional pero Recomendado)

Si quieres que ChatGon envíe emails:

```bash
MAILER_SENDER_EMAIL=ChatGon <admin@monexgon.app>
SMTP_DOMAIN=monexgon.app
SMTP_ADDRESS=smtp.hostinger.com
SMTP_PORT=587
SMTP_USERNAME=admin@monexgon.app
SMTP_PASSWORD=<tu-contraseña-smtp>
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
MAILER_INBOUND_EMAIL_DOMAIN=chat.monexgon.app
RAILS_INBOUND_EMAIL_SERVICE=relay
RAILS_INBOUND_EMAIL_PASSWORD=<pegar-valor-generado-con-openssl-3>
```

### 2.8 Variables de MOBILE APP (Opcional)

Si tienes apps móviles:

```bash
IOS_APP_ID=L7YLMN4634.com.chatgon.app
ANDROID_BUNDLE_ID=com.chatgon.app
ANDROID_SHA256_CERT_FINGERPRINT=AC:73:8E:DE:EB:56:EA:CC:10:87:02:A7:65:37:7B:38:D4:5D:D4:53:F8:3B:FB:D3:C6:28:64:1D:AA:08:1E:D8
ENABLE_PUSH_RELAY_SERVER=true
```

---

## 🌍 Paso 3: Configurar Dominio

### 3.1 Agregar Dominio
1. Ve a la pestaña **"Domains"** en tu proyecto de Coolify
2. Haz clic en **"Add Domain"**
3. Ingresa: `chat.monexgon.app`
4. Haz clic en **"Save"**

### 3.2 SSL Automático
- Coolify configurará automáticamente SSL con Let's Encrypt
- Espera unos minutos para que se genere el certificado

---

## 🎯 Paso 4: Desplegar

### 4.1 Iniciar Despliegue
1. Verifica que todas las variables estén configuradas
2. Haz clic en **"Deploy"** (botón azul grande)

### 4.2 Proceso Automático
Coolify ejecutará automáticamente:

```
1. Clone del repositorio
2. Build de la imagen Docker
3. Inicio de servicios en orden:
   → PostgreSQL (espera healthcheck)
   → Redis (espera healthcheck)
   → Setup (ejecuta migraciones y Brand)
   → Rails (espera que setup termine)
   → Sidekiq (espera que setup termine)
```

### 4.3 Tiempo Estimado
- **Primera vez**: 15-20 minutos (build + migraciones)
- **Re-despliegues**: 5-10 minutos

---

## 📊 Paso 5: Monitorear el Despliegue

### 5.1 Ver Logs en Coolify

Coolify mostrará 5 contenedores:

| Contenedor | Estado Esperado | Qué hace |
|------------|----------------|----------|
| **chatgon-postgres-1** | Running | Base de datos |
| **chatgon-redis-1** | Running | Caché |
| **chatgon-setup-1** | Exited (0) | Migraciones + Brand (termina al completar) |
| **chatgon-rails-1** | Running | Servidor web |
| **chatgon-sidekiq-1** | Running | Trabajos en background |

### 5.2 Logs del Servicio Setup

Haz clic en el contenedor **"chatgon-setup-1"** y verifica estos logs:

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
✓ Updated LOGO_DARK to /brand-assets/logo-dark.svg
✓ Updated LOGO_THUMBNAIL to /brand-assets/logo-thumbnail.svg
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

**✅ Si ves este mensaje, el setup fue exitoso.**

### 5.3 Logs del Servicio Rails

Haz clic en **"chatgon-rails-1"** y verifica:

```
Waiting for ChatGon setup service to complete...
✓ Setup service completed. Starting Rails server...
Puma starting in cluster mode...
* Listening on http://0.0.0.0:3000
✓ Rails server started on port 3000
```

**✅ Si ves "Listening on http://0.0.0.0:3000", Rails está corriendo.**

### 5.4 Logs del Servicio Sidekiq

Haz clic en **"chatgon-sidekiq-1"** y verifica:

```
Starting processing...
✓ Sidekiq is running
```

**✅ Si ves esto, Sidekiq está procesando trabajos.**

---

## ✅ Paso 6: Verificar que Todo Funciona

### 6.1 Acceder a la Aplicación
1. Abre tu navegador
2. Ve a: `https://chat.monexgon.app`
3. Deberías ver la pantalla de login de ChatGon

### 6.2 Verificar Brand

**Logo y Nombre**:
- Verifica que el logo de ChatGon aparezca en la esquina superior izquierda
- El título debe decir "ChatGon" (no "Chatwoot")

**Colores**:
- Los colores deben ser los de ChatGon (#2781F6)

### 6.3 Crear Usuario Admin

**IMPORTANTE**: Como el registro público está deshabilitado, debes crear el primer usuario desde la consola:

1. En Coolify, ve al contenedor **"chatgon-rails-1"**
2. Haz clic en **"Terminal"** o **"Console"**
3. Ejecuta este comando:

```ruby
bundle exec rails runner "
  user = User.new(
    name: 'Admin ChatGon',
    email: 'admin@monexgon.app',
    password: 'TuPasswordSeguro123!',
    type: 'SuperAdmin'
  )
  user.skip_confirmation!
  user.save!
  puts 'Usuario admin creado exitosamente'
"
```

4. Ahora puedes iniciar sesión con:
   - **Email**: `admin@monexgon.app`
   - **Password**: `TuPasswordSeguro123!`

### 6.4 Verificar Configuración del Brand en la Base de Datos

Desde la consola de Rails en Coolify:

```ruby
bundle exec rails runner "
  InstallationConfig.where(
    name: ['INSTALLATION_NAME', 'BRAND_NAME', 'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL']
  ).each { |c| puts \"#{c.name}: #{c.value}\" }
"
```

**Salida esperada**:
```
INSTALLATION_NAME: ChatGon
BRAND_NAME: ChatGon
LOGO: /brand-assets/logo-cg.svg
LOGO_DARK: /brand-assets/logo-dark.svg
LOGO_THUMBNAIL: /brand-assets/logo-thumbnail.svg
```

### 6.5 Verificar Features Habilitadas

```ruby
bundle exec rails runner "
  puts \"Features habilitadas: #{Feature.where(enabled: true).count}\"
"
```

**Salida esperada**: Más de 50 features habilitadas

---

## 🔧 Paso 7: Configuración Post-Despliegue

### 7.1 Cambiar Contraseña del Admin
1. Inicia sesión con el usuario admin
2. Ve a tu perfil
3. Cambia la contraseña a una segura

### 7.2 Crear tu Primera Cuenta (Inbox)
1. En ChatGon, ve a **Settings > Accounts**
2. Crea tu primera cuenta/organización
3. Configura tu primer inbox (canal de comunicación)

### 7.3 Configurar Usuarios
1. Ve a **Settings > Agents**
2. Invita a otros usuarios (si los necesitas)
3. Asigna roles y permisos

---

## 🔄 Actualizar ChatGon

### Cuando hagas cambios en el código:

1. **Push al repositorio**:
   ```bash
   git push origin develop
   ```

2. **En Coolify**:
   - Ve a tu proyecto ChatGon
   - Haz clic en **"Redeploy"**

3. **Coolify automáticamente**:
   - Descarga los cambios del repositorio
   - Reconstruye la imagen Docker
   - Ejecuta el servicio setup (migraciones + Brand)
   - Reinicia Rails y Sidekiq

---

## 🆘 Troubleshooting

### ❌ Error: "Secret key base required"

**Causa**: No definiste `SECRET_KEY_BASE`

**Solución**:
1. Genera uno: `openssl rand -base64 64`
2. Agrégalo a las variables de entorno en Coolify
3. Redeploy

---

### ❌ Error: "Database password required"

**Causa**: No definiste `POSTGRES_PASSWORD`

**Solución**:
1. Genera uno: `openssl rand -base64 32`
2. Agrégalo a las variables de entorno en Coolify
3. Redeploy

---

### ❌ El servicio "setup" está en "Restarting"

**Causa**: Las migraciones o Brand setup fallaron

**Solución**:
1. Ve a los logs del contenedor **"chatgon-setup-1"**
2. Busca el error específico
3. Comúnmente:
   - Postgres no está listo → Espera unos segundos más
   - Error en migraciones → Verifica la conexión a la base de datos

---

### ❌ El Brand no se aplicó (sigo viendo "Chatwoot")

**Causa**: El servicio setup no se ejecutó completamente

**Solución**:
1. Verifica los logs de **"chatgon-setup-1"**
2. Debe mostrar "✓ Brand configuration completed successfully"
3. Si no, re-ejecuta manualmente:

```bash
# En la terminal del contenedor chatgon-rails-1
bundle exec rails runner bin/setup_brand.rb
```

4. Refresca el navegador (Ctrl+Shift+R)

---

### ❌ No puedo acceder a https://chat.monexgon.app

**Causa**: Dominio no configurado o DNS no propagado

**Solución**:
1. Verifica que el dominio apunte a la IP del VPS
2. Verifica en Coolify > Domains que esté configurado
3. Espera propagación de DNS (puede tardar hasta 24 horas)
4. Prueba accediendo por IP:puerto mientras tanto

---

### ❌ Rails no inicia (stuck en "Waiting for setup...")

**Causa**: El servicio setup no terminó exitosamente

**Solución**:
1. Revisa logs de **"chatgon-setup-1"**
2. Debe haber terminado con "Exited (0)"
3. Si está en error, corrige el problema y redeploy

---

## 📚 Comandos Útiles en Coolify

### Ver logs de un servicio
1. En Coolify, ve a tu proyecto
2. Haz clic en el contenedor que quieras ver
3. Selecciona **"Logs"**

### Acceder a la consola de Rails
1. Haz clic en el contenedor **"chatgon-rails-1"**
2. Selecciona **"Terminal"**
3. Ejecuta comandos:

```bash
# Consola de Rails
bundle exec rails console

# Verificar Brand
bundle exec rails runner "puts InstallationConfig.find_by(name: 'BRAND_NAME').value"

# Re-aplicar Brand manualmente
bundle exec rails runner bin/setup_brand.rb
```

### Reiniciar un servicio
1. Haz clic en el contenedor
2. Haz clic en **"Restart"**

### Re-ejecutar migraciones manualmente
1. Ve al contenedor **"chatgon-setup-1"**
2. Si terminó con error, Coolify lo reiniciará automáticamente
3. O redeploy el proyecto completo

---

## ✅ Checklist Final

Antes de dar por terminado el despliegue, verifica:

- [ ] ✅ PostgreSQL corriendo (Running)
- [ ] ✅ Redis corriendo (Running)
- [ ] ✅ Setup completado (Exited 0)
- [ ] ✅ Rails corriendo (Running)
- [ ] ✅ Sidekiq corriendo (Running)
- [ ] ✅ Acceso a https://chat.monexgon.app funcional
- [ ] ✅ Brand ChatGon visible (logo, colores, nombre)
- [ ] ✅ Usuario admin creado y funcional
- [ ] ✅ Login funcional
- [ ] ✅ No hay warnings de premium features
- [ ] ✅ Registro público deshabilitado (no aparece botón Sign Up)

---

## 🎉 ¡Listo!

Tu instalación de ChatGon está completa y funcionando.

**Características confirmadas**:
- ✅ Sistema 100% privado (sin telemetría a Chatwoot)
- ✅ Brand ChatGon aplicado automáticamente
- ✅ Todas las features enterprise habilitadas
- ✅ Registro público deshabilitado
- ✅ Base de datos migrada y configurada
- ✅ SSL configurado automáticamente por Coolify

---

**Documentación adicional**:
- `SECUENCIA-SERVICIOS.md` - Arquitectura detallada
- `DESPLIEGUE-DESDE-CERO.md` - Explicación técnica completa
- `DEPLOY-COOLIFY.md` - Guía de referencia completa
- `.env.coolify.example` - Todas las variables disponibles

---

**Versión**: 1.0
**Fecha**: 2025-10-06
**ChatGon** - Sistema privado e independiente
