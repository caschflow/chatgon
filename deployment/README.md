# 📚 ChatGon - Documentación de Deployment

## 🎯 Guías Disponibles

### 🚀 Deployment y Configuración

- **[variables-coolify.md](variables-coolify.md)** - Variables de entorno requeridas para Coolify
- **[TROUBLESHOOTING_COOLIFY_DEPLOY.md](TROUBLESHOOTING_COOLIFY_DEPLOY.md)** - Solución de problemas de deploy en Coolify
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Problemas generales y soluciones

### 🔐 APIs y Gestión

- **[PLATFORM_API_REFERENCE.md](PLATFORM_API_REFERENCE.md)** - Referencia completa de Platform API
- **[AGENT_MANAGEMENT_API_ONLY.md](AGENT_MANAGEMENT_API_ONLY.md)** - Gestión de agentes solo vía API
- **[ROLES_AND_PERMISSIONS.md](ROLES_AND_PERMISSIONS.md)** - Roles y permisos del sistema

### 🐛 Fixes Específicos

- **[WHATSAPP_EVOLUTION_API_SEND_FIX.md](WHATSAPP_EVOLUTION_API_SEND_FIX.md)** - Fix para envío de mensajes WhatsApp
- **[WHATSAPP_QR_DUPLICATE_FIX.md](WHATSAPP_QR_DUPLICATE_FIX.md)** - Fix para códigos QR duplicados

---

## 🚀 Quick Start: Deployment en Coolify

### 1. Configurar Variables de Entorno

Consulta **[variables-coolify.md](variables-coolify.md)** para la lista completa.

**Variables críticas:**
```bash
# Base de datos
DATABASE_URL=postgresql://usuario:password%2Bencoded@postgres:5432/chatwoot

# Seguridad
SECRET_KEY_BASE=[openssl rand -hex 64]

# Aplicación
FRONTEND_URL=https://chat.monexgon.app
DEFAULT_LOCALE=es

# Sistema privado
ENABLE_ACCOUNT_SIGNUP=false
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false
CREATE_NEW_AGENT_FROM_DASHBOARD=false
DELETE_AGENT_FROM_DASHBOARD=false
```

### 2. Deploy

1. En Coolify → Tu App → **Deployments**
2. Click en **Deploy**
3. ✅ Activar **"Force Rebuild"** (importante para cambios de código)
4. Esperar 10-15 minutos

### 3. Verificación Post-Deploy

```bash
# Verificar servicios corriendo
docker ps | grep chatgon

# Ver logs
docker logs -f <container-name>

# Verificar aplicación
curl https://chat.monexgon.app/api/v1/health
```

---

## 🔐 Gestión de Usuarios y Agentes

ChatGon está configurado como **sistema privado**. La creación de cuentas y agentes **SOLO** está disponible vía Platform API.

### Crear una Cuenta Nueva

Ver guía completa en **[PLATFORM_API_REFERENCE.md](PLATFORM_API_REFERENCE.md#crear-cuenta)**

```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nombre de la Empresa"
  }'
```

### Crear un Agente

Ver guía completa en **[AGENT_MANAGEMENT_API_ONLY.md](AGENT_MANAGEMENT_API_ONLY.md#crear-nuevo-agente)**

```bash
# 1. Crear usuario
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "email": "juan@empresa.com",
    "password": "SecurePass123!"
  }'

# 2. Agregar a cuenta
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/{account_id}/account_users \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 25,
    "role": "agent"
  }'
```

---

## 🐛 Troubleshooting Común

### Deploy Falla con "password authentication failed"

**Solución:** Tu password tiene caracteres especiales. Usa `DATABASE_URL` con URL encoding.

Ver: **[variables-coolify.md - Base de Datos](variables-coolify.md#base-de-datos)**

### Contenedores en conflicto

**Solución:** Detén y limpia contenedores huérfanos.

Ver: **[TROUBLESHOOTING_COOLIFY_DEPLOY.md](TROUBLESHOOTING_COOLIFY_DEPLOY.md)**

### Cambios de código no se reflejan

**Solución:** Hacer deploy con **Force Rebuild** activado.

---

## 📖 Más Información

- **Platform API:** [PLATFORM_API_REFERENCE.md](PLATFORM_API_REFERENCE.md)
- **Gestión de Agentes:** [AGENT_MANAGEMENT_API_ONLY.md](AGENT_MANAGEMENT_API_ONLY.md)
- **Roles y Permisos:** [ROLES_AND_PERMISSIONS.md](ROLES_AND_PERMISSIONS.md)
- **Troubleshooting:** [TROUBLESHOOTING_COOLIFY_DEPLOY.md](TROUBLESHOOTING_COOLIFY_DEPLOY.md)

---

**Última actualización:** Octubre 2025
**Versión:** ChatGon 3.x para Coolify
