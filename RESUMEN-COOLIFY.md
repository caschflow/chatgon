# ChatGon - Resumen Ejecutivo para Coolify

## 🎯 Configuración Rápida (5 minutos)

### 1️⃣ Crear Proyecto
- **New Resource** → **Docker Compose**
- **Repository**: Tu repo público de GitHub
- **Branch**: `develop`

### 2️⃣ Configuración del Build
```
Build Pack: Dockerfile
Dockerfile Location: /docker/Dockerfile
Docker Compose File: /docker-compose.production.yaml
```

### 3️⃣ Variables Mínimas (Generar AHORA)

**Genera estos valores primero**:
```bash
# SECRET_KEY_BASE
openssl rand -base64 64

# Contraseñas (genera 3 veces)
openssl rand -base64 32
```

**Agrega en Coolify**:
```bash
SECRET_KEY_BASE=<valor-generado-1>
FRONTEND_URL=https://chat.monexgon.app
POSTGRES_DATABASE=chatgon_production
POSTGRES_USERNAME=chatgon_user
POSTGRES_PASSWORD=<valor-generado-2>
REDIS_PASSWORD=<valor-generado-3>
```

### 4️⃣ Variables de Brand (Copiar/Pegar)
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

### 5️⃣ Variables de Seguridad (Copiar/Pegar)
```bash
ENABLE_ACCOUNT_SIGNUP=false
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false
CREATE_NEW_AGENT_FROM_DASHBOARD=false
DELETE_AGENT_FROM_DASHBOARD=false
DISABLE_TELEMETRY=true
DEPLOYMENT_ENV=self-hosted
INSTALLATION_PRICING_PLAN=enterprise
DEFAULT_LOCALE=es
FORCE_SSL=false
ACTIVE_STORAGE_SERVICE=local
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=10
```

### 6️⃣ Dominio
- **Add Domain**: `chat.monexgon.app`

### 7️⃣ Deploy
- Clic en **Deploy**
- Espera 15-20 minutos (primera vez)

---

## 📊 Servicios que se Desplegarán

| # | Servicio | Estado Final | Función |
|---|----------|--------------|---------|
| 1 | **postgres** | Running | Base de datos |
| 2 | **redis** | Running | Caché |
| 3 | **setup** | Exited (0) | Migraciones + Brand (se ejecuta y termina) |
| 4 | **rails** | Running | Servidor web (puerto 3000) |
| 5 | **sidekiq** | Running | Trabajos en background |

---

## ✅ Verificación Rápida

### Logs del Setup (debe mostrar):
```
✓ Database migrations completed successfully
✓ Brand configuration completed successfully
✓ ChatGon Setup Completed Successfully
```

### Logs de Rails (debe mostrar):
```
✓ Setup service completed. Starting Rails server...
* Listening on http://0.0.0.0:3000
```

### Acceso Web:
1. Abre: `https://chat.monexgon.app`
2. Debe mostrar login de ChatGon (NO Chatwoot)

---

## 👤 Crear Usuario Admin

En la terminal de **chatgon-rails-1** (Coolify → Container → Terminal):

```ruby
bundle exec rails runner "
  user = User.new(
    name: 'Admin ChatGon',
    email: 'admin@monexgon.app',
    password: 'PasswordSeguro123!',
    type: 'SuperAdmin'
  )
  user.skip_confirmation!
  user.save!
  puts 'Usuario creado'
"
```

**Login**:
- Email: `admin@monexgon.app`
- Password: `PasswordSeguro123!`

---

## 🔧 Email (Opcional)

Si quieres enviar emails, agrega también:

```bash
MAILER_SENDER_EMAIL=ChatGon <admin@monexgon.app>
SMTP_DOMAIN=monexgon.app
SMTP_ADDRESS=smtp.hostinger.com
SMTP_PORT=587
SMTP_USERNAME=admin@monexgon.app
SMTP_PASSWORD=<tu-password-smtp>
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
MAILER_INBOUND_EMAIL_DOMAIN=chat.monexgon.app
RAILS_INBOUND_EMAIL_SERVICE=relay
RAILS_INBOUND_EMAIL_PASSWORD=<valor-generado-4>
```

---

## 🆘 Problemas Comunes

| Error | Solución |
|-------|----------|
| "Secret key base required" | Falta `SECRET_KEY_BASE`, agrégalo |
| "Database password required" | Falta `POSTGRES_PASSWORD`, agrégalo |
| Setup en "Restarting" | Ver logs de setup, revisar error |
| Brand no aparece | Ejecutar `bundle exec rails runner bin/setup_brand.rb` |
| No puedo acceder al dominio | Verificar DNS, esperar propagación |

---

## 📚 Documentación Completa

- **`GUIA-COOLIFY-PASO-A-PASO.md`** ← **EMPIEZA AQUÍ** (guía detallada)
- **`SECUENCIA-SERVICIOS.md`** - Arquitectura de servicios
- **`DESPLIEGUE-DESDE-CERO.md`** - Explicación técnica
- **`.env.coolify.example`** - Todas las variables disponibles

---

## 🎉 Checklist de Éxito

- [ ] PostgreSQL Running
- [ ] Redis Running
- [ ] Setup Exited (0)
- [ ] Rails Running
- [ ] Sidekiq Running
- [ ] Acceso web funcional
- [ ] Brand ChatGon visible
- [ ] Usuario admin creado
- [ ] No hay botón "Sign Up" (registro deshabilitado)

---

**¡Ya estás listo para usar ChatGon!**

Sistema 100% privado, con Brand personalizado y todas las features enterprise habilitadas.
