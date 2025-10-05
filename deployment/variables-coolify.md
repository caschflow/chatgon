# Variables de Entorno para Coolify - ChatGon

## Variables Obligatorias

### Seguridad
SECRET_KEY_BASE=[openssl rand -hex 64]

### Base de Datos
POSTGRES_USERNAME=chatgon_user
POSTGRES_PASSWORD=[password seguro]
POSTGRES_DATABASE=chatgon_production

### Redis
REDIS_PASSWORD=[password seguro]

### Aplicación
FRONTEND_URL=https://chat.monexgon.app
DEFAULT_LOCALE=es

### Email (Hostinger)
MAILER_SENDER_EMAIL=ChatGon <admin@monexgon.app>
SMTP_DOMAIN=monexgon.app
SMTP_ADDRESS=smtp.hostinger.com
SMTP_PORT=587
SMTP_USERNAME=admin@monexgon.app
SMTP_PASSWORD=[password del buzón]
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true

## Variables de Branding (Obligatorias para ChatGon)
INSTALLATION_NAME=ChatGon
BRAND_NAME=ChatGon
BRAND_URL=https://chat.monexgon.app
WIDGET_BRAND_URL=https://chat.monexgon.app
BRAND_COLOR=#2781F6
LOGO=/brand-assets/logo-cg.svg
LOGO_DARK=/brand-assets/logo-dark.svg
LOGO_THUMBNAIL=/brand-assets/logo-thumbnail.svg

## Variables de Independencia (Obligatorias)
DISABLE_TELEMETRY=true
CHATGON_HUB_URL=https://chat.monexgon.app

## Variables de Seguridad y Privacidad (IMPORTANTE)
# Sistema privado - Registro solo vía Platform API
ENABLE_ACCOUNT_SIGNUP=false
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false

## Variables Opcionales (con valores por defecto)
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=10
ACTIVE_STORAGE_SERVICE=local
FORCE_SSL=false