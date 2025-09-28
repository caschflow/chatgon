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

### Email (Hostinger)
MAILER_SENDER_EMAIL=ChatGon <admin@monexgon.app>
SMTP_DOMAIN=monexgon.app
SMTP_ADDRESS=smtp.hostinger.com
SMTP_PORT=587
SMTP_USERNAME=admin@monexgon.app
SMTP_PASSWORD=[password del buzón]
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true

## Variables Opcionales (con valores por defecto)
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=10
ACTIVE_STORAGE_SERVICE=local