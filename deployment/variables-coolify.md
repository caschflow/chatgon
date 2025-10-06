# Variables de Entorno para Coolify - ChatGon

## Variables Obligatorias

### Seguridad
```bash
# Generar con: openssl rand -hex 64
SECRET_KEY_BASE=<64_caracteres_hex_aleatorios>
```

### Base de Datos

**Opción A: DATABASE_URL (RECOMENDADO - para passwords con caracteres especiales)**
```bash
# Si tu password contiene caracteres especiales (+, =, @, etc.),
# usa DATABASE_URL con URL encoding:
# + → %2B
# = → %3D
# @ → %40
DATABASE_URL=postgresql://usuario:password_url_encoded@postgres:5432/database_name
```

**Opción B: Variables Individuales (solo si password no tiene caracteres especiales)**
```bash
POSTGRES_USERNAME=chatgon_user
POSTGRES_PASSWORD=[password seguro sin +, =, @]
POSTGRES_DATABASE=chatgon_production
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
```

**Nota:** DATABASE_URL tiene precedencia sobre las variables individuales.

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
```bash
DISABLE_TELEMETRY=true

# Nota: CHATGON_HUB_URL se configura automáticamente con el valor de FRONTEND_URL
# No es necesario configurar esta variable manualmente
```

## Variables de Seguridad y Privacidad (IMPORTANTE)
# Sistema privado - Registro solo vía Platform API
ENABLE_ACCOUNT_SIGNUP=false
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false

# Gestión de Agentes solo desde Platform API
CREATE_NEW_AGENT_FROM_DASHBOARD=false
DELETE_AGENT_FROM_DASHBOARD=false

## Variables Opcionales (con valores por defecto)

### Performance
```bash
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=10
```

### API Configuration
```bash
API_RATE_LIMIT=1000
API_ACCESS_TOKEN_EXPIRY=24  # Horas
```

### Storage y SSL
```bash
# Estas variables ya tienen valores por defecto en docker-compose
# No es necesario configurarlas a menos que quieras cambiarlas

# ACTIVE_STORAGE_SERVICE=local (por defecto)
# FORCE_SSL=false (por defecto)
# DISPLAY_MANIFEST=false (por defecto)
# CORS_ORIGINS se configura automáticamente con FRONTEND_URL
```