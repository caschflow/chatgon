# 🔌 ChatGon Platform API - Referencia Completa

## 📌 Información General

La **Platform API** es la única forma de crear cuentas y usuarios en ChatGon después de habilitar el sistema privado.

### Base URL
```
https://chat.monexgon.app/platform/api/v1
```

### Autenticación
Todas las peticiones requieren el header:
```
api_access_token: YOUR_PLATFORM_TOKEN
```

### Content-Type
```
Content-Type: application/json
```

---

## 🔑 Obtener Token de Platform API

Para obtener el token, necesitas acceder a Rails console una vez:

```bash
# Acceder al contenedor de Rails
docker exec -it <CONTAINER_NAME> bundle exec rails console

# Crear Platform App y obtener token
platform_app = PlatformApp.create!(name: "Admin API")
token = platform_app.access_token.token
puts "Token: #{token}"
exit
```

**⚠️ Guarda este token de forma segura, lo necesitarás para todas las peticiones.**

---

## 📚 Endpoints Disponibles

### 1. 👥 USERS - Gestión de Usuarios

#### **Crear Usuario**
```bash
POST /platform/api/v1/users
```

**Parámetros:**
- `email` (string, requerido) - Email del usuario
- `password` (string, requerido) - Contraseña
- `name` (string, requerido) - Nombre completo
- `display_name` (string, opcional) - Nombre a mostrar
- `custom_attributes` (object, opcional) - Atributos personalizados

**Ejemplo:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@empresa.com",
    "password": "ContraseñaSegura123",
    "name": "Juan Pérez",
    "display_name": "Juan",
    "custom_attributes": {
      "departamento": "Ventas",
      "telefono": "+521234567890"
    }
  }'
```

**Respuesta:**
```json
{
  "id": 123,
  "email": "usuario@empresa.com",
  "name": "Juan Pérez",
  "display_name": "Juan",
  "custom_attributes": {
    "departamento": "Ventas",
    "telefono": "+521234567890"
  },
  "confirmed": true
}
```

**Notas:**
- El usuario se crea **sin necesidad de confirmación de email**
- Si el email ya existe, se actualiza el usuario existente
- El token asocia automáticamente el usuario a tu Platform App

---

#### **Obtener Usuario**
```bash
GET /platform/api/v1/users/:id
```

**Ejemplo:**
```bash
curl -X GET https://chat.monexgon.app/platform/api/v1/users/123 \
  -H "api_access_token: TU_TOKEN_AQUI"
```

---

#### **Actualizar Usuario**
```bash
PUT /platform/api/v1/users/:id
PATCH /platform/api/v1/users/:id
```

**Parámetros:**
- `email` (string, opcional)
- `password` (string, opcional)
- `name` (string, opcional)
- `display_name` (string, opcional)
- `custom_attributes` (object, opcional)

**Ejemplo:**
```bash
curl -X PATCH https://chat.monexgon.app/platform/api/v1/users/123 \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez García",
    "custom_attributes": {
      "telefono": "+521234567891"
    }
  }'
```

**Notas:**
- Si cambias el email, NO requiere confirmación
- Los `custom_attributes` se fusionan (no se sobrescriben)

---

#### **Eliminar Usuario**
```bash
DELETE /platform/api/v1/users/:id
```

**Ejemplo:**
```bash
curl -X DELETE https://chat.monexgon.app/platform/api/v1/users/123 \
  -H "api_access_token: TU_TOKEN_AQUI"
```

**Respuesta:**
```
200 OK (sin contenido)
```

**Nota:** La eliminación se ejecuta en background (job asíncrono)

---

#### **Generar SSO Login**
```bash
GET /platform/api/v1/users/:id/login
```

Genera una URL de login automático (SSO) para el usuario.

**Ejemplo:**
```bash
curl -X GET https://chat.monexgon.app/platform/api/v1/users/123/login \
  -H "api_access_token: TU_TOKEN_AQUI"
```

**Respuesta:**
```json
{
  "url": "https://chat.monexgon.app/app/login?email=usuario@empresa.com&sso_auth_token=abc123..."
}
```

**Uso:** Envía al usuario a esta URL para que se autentique automáticamente sin contraseña.

---

#### **Generar Token de Acceso**
```bash
POST /platform/api/v1/users/:id/token
```

Genera un token de acceso para el usuario (para uso en APIs internas).

**Ejemplo:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/users/123/token \
  -H "api_access_token: TU_TOKEN_AQUI"
```

---

### 2. 🏢 ACCOUNTS - Gestión de Cuentas

#### **Listar Cuentas**
```bash
GET /platform/api/v1/accounts
```

Lista todas las cuentas asociadas a tu Platform App.

**Ejemplo:**
```bash
curl -X GET https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: TU_TOKEN_AQUI"
```

**Respuesta:**
```json
[
  {
    "id": 1,
    "name": "Empresa ABC",
    "locale": "es",
    "domain": "abc.com",
    "support_email": "soporte@abc.com",
    "status": "active"
  },
  {
    "id": 2,
    "name": "Empresa XYZ",
    "locale": "es"
  }
]
```

---

#### **Crear Cuenta**
```bash
POST /platform/api/v1/accounts
```

**Parámetros:**
- `name` (string, requerido) - Nombre de la cuenta/empresa
- `locale` (string, opcional) - Idioma (default: "es")
- `domain` (string, opcional) - Dominio de la empresa
- `support_email` (string, opcional) - Email de soporte
- `status` (string, opcional) - Estado: "active" o "suspended"
- `features` (object, opcional) - Features a habilitar
- `limits` (object, opcional) - Límites de la cuenta
- `custom_attributes` (object, opcional) - Atributos personalizados

**Ejemplo:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Empresa ABC",
    "locale": "es",
    "domain": "abc.com",
    "support_email": "soporte@abc.com",
    "status": "active",
    "features": {
      "inbox_management": true,
      "channel_email": true,
      "agent_bots": true
    },
    "limits": {
      "agents": 50,
      "inboxes": 10
    },
    "custom_attributes": {
      "plan": "enterprise",
      "industry": "retail"
    }
  }'
```

**Respuesta:**
```json
{
  "id": 1,
  "name": "Empresa ABC",
  "locale": "es",
  "domain": "abc.com",
  "support_email": "soporte@abc.com",
  "status": "active"
}
```

---

#### **Obtener Cuenta**
```bash
GET /platform/api/v1/accounts/:id
```

**Ejemplo:**
```bash
curl -X GET https://chat.monexgon.app/platform/api/v1/accounts/1 \
  -H "api_access_token: TU_TOKEN_AQUI"
```

---

#### **Actualizar Cuenta**
```bash
PUT /platform/api/v1/accounts/:id
PATCH /platform/api/v1/accounts/:id
```

**Parámetros:** Mismos que crear

**Ejemplo:**
```bash
curl -X PATCH https://chat.monexgon.app/platform/api/v1/accounts/1 \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Empresa ABC S.A.",
    "features": {
      "agent_management": true
    }
  }'
```

---

#### **Eliminar Cuenta**
```bash
DELETE /platform/api/v1/accounts/:id
```

**Ejemplo:**
```bash
curl -X DELETE https://chat.monexgon.app/platform/api/v1/accounts/1 \
  -H "api_access_token: TU_TOKEN_AQUI"
```

**Respuesta:** `200 OK`

**Nota:** Se ejecuta en background (job asíncrono)

---

### 3. 👤 ACCOUNT USERS - Asociar Usuarios a Cuentas

#### **Listar Usuarios de una Cuenta**
```bash
GET /platform/api/v1/accounts/:account_id/account_users
```

**Ejemplo:**
```bash
curl -X GET https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: TU_TOKEN_AQUI"
```

**Respuesta:**
```json
[
  {
    "id": 1,
    "account_id": 1,
    "user_id": 123,
    "role": "administrator"
  },
  {
    "id": 2,
    "account_id": 1,
    "user_id": 124,
    "role": "agent"
  }
]
```

---

#### **Agregar Usuario a Cuenta**
```bash
POST /platform/api/v1/accounts/:account_id/account_users
```

**Parámetros:**
- `user_id` (integer, requerido) - ID del usuario
- `role` (string, requerido) - Rol: "administrator" o "agent"

**Ejemplo:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 123,
    "role": "administrator"
  }'
```

**Respuesta:**
```json
{
  "id": 1,
  "account_id": 1,
  "user_id": 123,
  "role": "administrator"
}
```

**Notas:**
- Si el usuario ya está en la cuenta, se actualiza su rol
- Roles disponibles: `administrator`, `agent`

---

#### **Eliminar Usuario de Cuenta**
```bash
DELETE /platform/api/v1/accounts/:account_id/account_users
```

**Parámetros:**
- `user_id` (integer, requerido) - ID del usuario a eliminar

**Ejemplo:**
```bash
curl -X DELETE https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 123
  }'
```

**Respuesta:** `200 OK`

---

### 4. 🤖 AGENT BOTS - Gestión de Bots

#### **Listar Bots**
```bash
GET /platform/api/v1/agent_bots
```

**Ejemplo:**
```bash
curl -X GET https://chat.monexgon.app/platform/api/v1/agent_bots \
  -H "api_access_token: TU_TOKEN_AQUI"
```

---

#### **Crear Bot**
```bash
POST /platform/api/v1/agent_bots
```

**Parámetros:**
- `name` (string, requerido) - Nombre del bot
- `description` (string, opcional) - Descripción
- `account_id` (integer, opcional) - ID de cuenta a asociar
- `outgoing_url` (string, opcional) - Webhook URL
- `avatar_url` (string, opcional) - URL del avatar

**Ejemplo:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/agent_bots \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bot de Soporte",
    "description": "Bot automático para preguntas frecuentes",
    "account_id": 1,
    "outgoing_url": "https://webhook.site/abc123",
    "avatar_url": "https://example.com/bot-avatar.png"
  }'
```

---

#### **Obtener Bot**
```bash
GET /platform/api/v1/agent_bots/:id
```

---

#### **Actualizar Bot**
```bash
PUT /platform/api/v1/agent_bots/:id
PATCH /platform/api/v1/agent_bots/:id
```

**Ejemplo:**
```bash
curl -X PATCH https://chat.monexgon.app/platform/api/v1/agent_bots/1 \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bot de Soporte Actualizado",
    "description": "Descripción mejorada"
  }'
```

---

#### **Eliminar Bot**
```bash
DELETE /platform/api/v1/agent_bots/:id
```

**Ejemplo:**
```bash
curl -X DELETE https://chat.monexgon.app/platform/api/v1/agent_bots/1 \
  -H "api_access_token: TU_TOKEN_AQUI"
```

---

#### **Eliminar Avatar del Bot**
```bash
DELETE /platform/api/v1/agent_bots/:id/avatar
```

**Ejemplo:**
```bash
curl -X DELETE https://chat.monexgon.app/platform/api/v1/agent_bots/1/avatar \
  -H "api_access_token: TU_TOKEN_AQUI"
```

---

## 🔄 Flujo Completo: Crear Empresa con Usuarios

### Paso 1: Crear la Cuenta
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mi Empresa S.A.",
    "locale": "es",
    "support_email": "soporte@miempresa.com"
  }'
```
**Respuesta:** Obtén el `account_id` (ej: 1)

### Paso 2: Crear Usuario Administrador
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@miempresa.com",
    "password": "ContraseñaSegura123",
    "name": "Administrador Principal"
  }'
```
**Respuesta:** Obtén el `user_id` (ej: 123)

### Paso 3: Asociar Usuario a Cuenta como Admin
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 123,
    "role": "administrator"
  }'
```

### Paso 4: Crear Agente
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agente@miempresa.com",
    "password": "OtraContraseña456",
    "name": "Agente de Soporte"
  }'
```
**Respuesta:** `user_id` 124

### Paso 5: Asociar Agente a Cuenta
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: TU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 124,
    "role": "agent"
  }'
```

**✅ Listo!** Ahora ambos usuarios pueden hacer login en `https://chat.monexgon.app/app/login`

---

## 🔒 Seguridad y Buenas Prácticas

### ✅ Recomendaciones

1. **Protege el Token:**
   - Nunca expongas el token en frontend
   - Guárdalo en variables de entorno
   - Rótalo periódicamente

2. **Valida Inputs:**
   - Valida emails antes de crear usuarios
   - Usa contraseñas fuertes (mín. 8 caracteres)
   - Sanitiza custom_attributes

3. **Manejo de Errores:**
   - Siempre verifica respuestas HTTP
   - Maneja códigos 400, 401, 404, 500

4. **Rate Limiting:**
   - La API tiene límite de requests (default: 1000/hora)
   - Implementa retry con backoff exponencial

### ❌ No Hacer

- ❌ No uses el token en JavaScript del navegador
- ❌ No compartas el token en repositorios públicos
- ❌ No crees usuarios sin validar emails
- ❌ No expongas la Platform API públicamente

---

## 🐛 Códigos de Error Comunes

| Código | Descripción | Solución |
|--------|-------------|----------|
| 401 | Invalid access_token | Verifica el token en header |
| 404 | Resource not found | Verifica que el ID existe |
| 422 | Validation failed | Revisa parámetros requeridos |
| 500 | Internal server error | Contacta soporte |

---

## 📞 Soporte

Si encuentras problemas con la Platform API:
1. Verifica que el token sea válido
2. Revisa logs de Rails: `docker logs <CONTAINER_NAME>`
3. Consulta la documentación de Chatwoot original para más detalles

---

**Última actualización:** Octubre 2025
**Versión:** ChatGon 3.x (basado en Chatwoot)
