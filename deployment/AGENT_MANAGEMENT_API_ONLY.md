# 🔐 Gestión de Agentes solo desde API

## 📋 Descripción

Guía para configurar ChatGon de modo que la creación y eliminación de agentes (usuarios) esté disponible **únicamente desde Platform API**, mientras que desde el dashboard web los administradores solo puedan:

- ✅ Ver lista de agentes
- ✅ Ver configuraciones de agentes
- ✅ Editar agentes existentes
- ❌ Crear nuevos agentes (solo API)
- ❌ Eliminar agentes (solo API)

---

## 🎯 Objetivo

Centralizar el control de agentes desde tu sistema externo, evitando que administradores creen o eliminen usuarios libremente desde la interfaz web.

**Beneficios:**
- 🔒 Control centralizado de quién puede acceder
- 📊 Auditoría completa de creación/eliminación
- 🚫 Prevención de borrados accidentales
- 🔑 Gestión de usuarios desde un único punto

---

## 🛠️ Implementación

### Paso 1: Configuración Global

**Archivo:** `config/installation_config.yml`

Agregar al final del archivo (después de línea 458):

```yaml
## ------ Control de Gestión de Agentes desde Dashboard ------ ##
- name: CREATE_NEW_AGENT_FROM_DASHBOARD
  value: false
  display_title: 'Create Agents from Dashboard'
  description: 'Allow administrators to create new agents from the dashboard UI'
  locked: false
  type: boolean

- name: DELETE_AGENT_FROM_DASHBOARD
  value: false
  display_title: 'Delete Agents from Dashboard'
  description: 'Allow administrators to delete agents from the dashboard UI'
  locked: false
  type: boolean
## ------ End of Control de Gestión de Agentes ------ ##
```

---

### Paso 2: Backend - Controlador de Agentes

**Archivo:** `app/controllers/api/v1/accounts/agents_controller.rb`

**Modificar líneas 2-4:**

```ruby
class Api::V1::Accounts::AgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_agent, except: [:create, :index, :bulk_create]
  before_action :check_dashboard_creation_enabled, only: [:create, :bulk_create]  # ← NUEVO
  before_action :check_dashboard_deletion_enabled, only: [:destroy]              # ← NUEVO
  before_action :check_authorization
  before_action :validate_limit, only: [:create]
  before_action :validate_limit_for_bulk_create, only: [:bulk_create]

  # ... resto del código sin cambios
```

**Agregar al final de la sección private (después de línea 109):**

```ruby
  private

  # ... métodos existentes ...

  def check_dashboard_creation_enabled
    return if GlobalConfig.get_value('CREATE_NEW_AGENT_FROM_DASHBOARD', 'true') == 'true'

    raise ActionController::RoutingError, 'Not Found'
  end

  def check_dashboard_deletion_enabled
    return if GlobalConfig.get_value('DELETE_AGENT_FROM_DASHBOARD', 'true') == 'true'

    raise ActionController::RoutingError, 'Not Found'
  end

  def delete_user_record(agent)
    DeleteObjectJob.perform_later(agent) if agent.reload.account_users.blank?
  end
end
```

---

### Paso 3: Backend - Dashboard Controller

**Archivo:** `app/controllers/dashboard_controller.rb`

**Modificar línea 29 (método `set_global_config`):**

```ruby
def set_global_config
  @global_config = GlobalConfig.get(
    'LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL',
    'INSTALLATION_NAME',
    'WIDGET_BRAND_URL', 'TERMS_URL',
    'BRAND_URL', 'BRAND_NAME',
    'PRIVACY_URL',
    'DISPLAY_MANIFEST',
    'CREATE_NEW_ACCOUNT_FROM_DASHBOARD',
    'CREATE_NEW_AGENT_FROM_DASHBOARD',    # ← NUEVO
    'DELETE_AGENT_FROM_DASHBOARD',        # ← NUEVO
    'CHATWOOT_INBOX_TOKEN',
    'API_CHANNEL_NAME',
    'API_CHANNEL_THUMBNAIL',
    'ANALYTICS_TOKEN',
    'DIRECT_UPLOADS_ENABLED',
    'HCAPTCHA_SITE_KEY',
    'LOGOUT_REDIRECT_LINK',
    'DISABLE_USER_PROFILE_UPDATE',
    'DEPLOYMENT_ENV',
    'INSTALLATION_PRICING_PLAN'
  ).merge(app_config)
end
```

---

### Paso 4: Frontend - Store Global Config

**Archivo:** `app/javascript/shared/store/globalConfig.js`

**Modificar líneas 3-25:**

```javascript
const {
  API_CHANNEL_NAME: apiChannelName,
  API_CHANNEL_THUMBNAIL: apiChannelThumbnail,
  APP_VERSION: appVersion,
  AZURE_APP_ID: azureAppId,
  BRAND_NAME: brandName,
  CHATWOOT_INBOX_TOKEN: chatwootInboxToken,
  CREATE_NEW_ACCOUNT_FROM_DASHBOARD: createNewAccountFromDashboard,
  CREATE_NEW_AGENT_FROM_DASHBOARD: createNewAgentFromDashboard,    // ← NUEVO
  DELETE_AGENT_FROM_DASHBOARD: deleteAgentFromDashboard,          // ← NUEVO
  DIRECT_UPLOADS_ENABLED: directUploadsEnabled,
  DISPLAY_MANIFEST: displayManifest,
  GIT_SHA: gitSha,
  HCAPTCHA_SITE_KEY: hCaptchaSiteKey,
  INSTALLATION_NAME: installationName,
  LOGO_THUMBNAIL: logoThumbnail,
  LOGO: logo,
  LOGO_DARK: logoDark,
  PRIVACY_URL: privacyURL,
  IS_ENTERPRISE: isEnterprise,
  TERMS_URL: termsURL,
  WIDGET_BRAND_URL: widgetBrandURL,
  DISABLE_USER_PROFILE_UPDATE: disableUserProfileUpdate,
  DEPLOYMENT_ENV: deploymentEnv,
} = window.globalConfig || {};

const state = {
  apiChannelName,
  apiChannelThumbnail,
  appVersion,
  azureAppId,
  brandName,
  chatwootInboxToken,
  deploymentEnv,
  createNewAccountFromDashboard,
  createNewAgentFromDashboard,        // ← NUEVO
  deleteAgentFromDashboard,          // ← NUEVO
  directUploadsEnabled: parseBoolean(directUploadsEnabled),
  disableUserProfileUpdate: parseBoolean(disableUserProfileUpdate),
  displayManifest,
  gitSha,
  hCaptchaSiteKey,
  installationName,
  logo,
  logoDark,
  logoThumbnail,
  privacyURL,
  termsURL,
  widgetBrandURL,
  isEnterprise: parseBoolean(isEnterprise),
};
```

---

### Paso 5: Frontend - Vista de Agentes

**Archivo:** `app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue`

**Modificar línea 10:**

```vue
<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';

import AddAgent from './AddAgent.vue';
import EditAgent from './EditAgent.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showDeletePopup = ref(false);
const showEditPopup = ref(false);
const agentAPI = ref({ message: '' });
const currentAgent = ref({});

const deleteConfirmText = computed(
  () => `${t('AGENT_MGMT.DELETE.CONFIRM.YES')} ${currentAgent.value.name}`
);
const deleteRejectText = computed(() => {
  return `${t('AGENT_MGMT.DELETE.CONFIRM.NO')} ${currentAgent.value.name}`;
});
const deleteMessage = computed(() => {
  return ` ${currentAgent.value.name}?`;
});

const agentList = computed(() => getters['agents/getAgents'].value);
const uiFlags = computed(() => getters['agents/getUIFlags'].value);
const currentUserId = computed(() => getters.getCurrentUserID.value);
const customRoles = useMapGetter('customRole/getCustomRoles');
const globalConfig = useMapGetter('globalConfig/get');  // ← NUEVO
```

**Modificar método `showDeleteAction` (línea 78-91):**

```javascript
const showDeleteAction = agent => {
  // ← NUEVO: Verificar si está habilitado desde configuración global
  if (!globalConfig.value.deleteAgentFromDashboard) {
    return false;
  }

  if (currentUserId.value === agent.id) {
    return false;
  }

  if (!agent.confirmed) {
    return true;
  }

  if (agent.role === 'administrator') {
    return verifiedAdministrators.value.length !== 1;
  }
  return true;
};
```

**Modificar template - botón Add Agent (línea 152-158):**

```vue
<template #actions>
  <Button
    v-if="globalConfig.createNewAgentFromDashboard"  <!-- ← NUEVO: Solo mostrar si está habilitado -->
    icon="i-lucide-circle-plus"
    :label="$t('AGENT_MGMT.HEADER_BTN_TXT')"
    @click="openAddPopup"
  />
</template>
```

**Nota:** El botón de eliminar ya está condicionado con `v-if="showDeleteAction(agent)"`, por lo que se ocultará automáticamente cuando la función retorne `false`.

---

### Paso 6: Variables de Entorno (Producción)

**Archivo:** `.env.production` o **Variables de Coolify**

```bash
# Gestión de Agentes desde Dashboard
CREATE_NEW_AGENT_FROM_DASHBOARD=false
DELETE_AGENT_FROM_DASHBOARD=false
```

**Nota:** Si no defines estas variables, el valor por defecto de `installation_config.yml` será usado (`false`).

---

## 📡 Platform API - Gestión de Agentes

### 🔑 Autenticación

Todas las llamadas a Platform API requieren el token:

```bash
api_access_token: TU_PLATFORM_API_TOKEN
```

**Obtener el token:**
1. Ir a Super Admin → Platform Apps
2. Crear nueva Platform App
3. Copiar el `api_access_token`

---

### 📋 Endpoints Disponibles

#### 1️⃣ Listar Agentes de una Cuenta

```bash
GET /platform/api/v1/accounts/{account_id}/account_users
```

**Request:**
```bash
curl -X GET https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: your_platform_token_here"
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "account_id": 1,
    "user_id": 10,
    "role": "administrator",
    "inviter_id": null,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z",
    "active_at": "2025-01-20T14:22:00.000Z",
    "availability": "online",
    "auto_offline": true
  },
  {
    "id": 2,
    "account_id": 1,
    "user_id": 15,
    "role": "agent",
    "inviter_id": 10,
    "created_at": "2025-01-16T09:00:00.000Z",
    "updated_at": "2025-01-16T09:00:00.000Z",
    "active_at": "2025-01-20T15:10:00.000Z",
    "availability": "online",
    "auto_offline": true
  }
]
```

---

#### 2️⃣ Crear Nuevo Agente

**Importante:** Primero debes crear el usuario en la plataforma (Platform Users API), luego agregarlo a la cuenta.

##### **Paso A: Crear Usuario**

```bash
POST /platform/api/v1/users
```

**Request:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: your_platform_token_here" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "email": "juan.perez@monexgon.com",
    "password": "SecurePassword123!",
    "password_confirmation": "SecurePassword123!"
  }'
```

**Response (200 OK):**
```json
{
  "id": 25,
  "uid": "juan.perez@monexgon.com",
  "name": "Juan Pérez",
  "display_name": "Juan Pérez",
  "email": "juan.perez@monexgon.com",
  "account_id": null,
  "role": null,
  "confirmed": false,
  "custom_attributes": {},
  "accounts": [],
  "provider": "email"
}
```

##### **Paso B: Agregar Usuario a la Cuenta**

```bash
POST /platform/api/v1/accounts/{account_id}/account_users
```

**Request:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: your_platform_token_here" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 25,
    "role": "agent"
  }'
```

**Parámetros:**
- `user_id` (required): ID del usuario creado en Paso A
- `role` (required): `"administrator"` o `"agent"`

**Response (200 OK):**
```json
{
  "id": 15,
  "account_id": 1,
  "user_id": 25,
  "role": "agent",
  "inviter_id": null,
  "created_at": "2025-01-20T16:30:00.000Z",
  "updated_at": "2025-01-20T16:30:00.000Z",
  "active_at": null,
  "availability": "online",
  "auto_offline": true
}
```

---

#### 3️⃣ Actualizar Rol de Agente

```bash
POST /platform/api/v1/accounts/{account_id}/account_users
```

**Request:**
```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: your_platform_token_here" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 25,
    "role": "administrator"
  }'
```

**Nota:** Este endpoint actualiza si el `user_id` ya existe en la cuenta.

**Response (200 OK):**
```json
{
  "id": 15,
  "account_id": 1,
  "user_id": 25,
  "role": "administrator",
  "inviter_id": null,
  "created_at": "2025-01-20T16:30:00.000Z",
  "updated_at": "2025-01-20T17:00:00.000Z",
  "active_at": null,
  "availability": "online",
  "auto_offline": true
}
```

---

#### 4️⃣ Eliminar Agente de una Cuenta

```bash
DELETE /platform/api/v1/accounts/{account_id}/account_users
```

**Request:**
```bash
curl -X DELETE https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: your_platform_token_here" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 25
  }'
```

**Parámetros:**
- `user_id` (required): ID del usuario a remover de la cuenta

**Response (200 OK):**
```
(Sin contenido - HTTP 200)
```

**Nota Importante:** Esto solo elimina la relación del usuario con la cuenta. Si el usuario no pertenece a ninguna otra cuenta, será eliminado automáticamente del sistema.

---

### ⚠️ Limitaciones y Validaciones

#### Backend NO valida:
- ❌ No verifica si es el último administrador
- ❌ No verifica límites de licencias
- ❌ No envía emails de confirmación

**Recomendación:** Implementa estas validaciones en tu sistema antes de llamar la API.

#### Ejemplo de Validación Recomendada:

```javascript
// Antes de eliminar un agente
async function safeDeleteAgent(accountId, userId) {
  // 1. Obtener lista de agentes
  const agents = await fetch(`/platform/api/v1/accounts/${accountId}/account_users`, {
    headers: { 'api_access_token': TOKEN }
  }).then(r => r.json());

  // 2. Contar administradores
  const admins = agents.filter(a => a.role === 'administrator');
  const targetAgent = agents.find(a => a.user_id === userId);

  // 3. Validar no es último admin
  if (targetAgent.role === 'administrator' && admins.length === 1) {
    throw new Error('Cannot delete the last administrator');
  }

  // 4. Eliminar
  return await fetch(`/platform/api/v1/accounts/${accountId}/account_users`, {
    method: 'DELETE',
    headers: {
      'api_access_token': TOKEN,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ user_id: userId })
  });
}
```

---

## 🧪 Testing

### 1. Verificar Configuración

**Desde Rails Console:**
```ruby
docker exec -it chatgon-rails bundle exec rails console

# Verificar valores
GlobalConfig.get_value('CREATE_NEW_AGENT_FROM_DASHBOARD')
# => "false"

GlobalConfig.get_value('DELETE_AGENT_FROM_DASHBOARD')
# => "false"
```

### 2. Probar desde Dashboard

**Como Administrador:**

1. **Ir a:** Settings → Agents
2. **Verificar:**
   - ❌ NO debe aparecer botón "+ Add Agent"
   - ❌ NO deben aparecer botones de eliminar (icono basura)
   - ✅ SÍ debe aparecer lista de agentes
   - ✅ SÍ deben aparecer botones de editar (icono lápiz)

### 3. Probar API de Creación

```bash
# Crear usuario
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Agent",
    "email": "test@monexgon.com",
    "password": "Test123456!",
    "password_confirmation": "Test123456!"
  }'

# Copiar el "id" del response (ejemplo: 30)

# Agregar a cuenta
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 30,
    "role": "agent"
  }'

# Verificar en dashboard que aparece el nuevo agente
```

### 4. Probar API de Eliminación

```bash
# Eliminar agente de prueba
curl -X DELETE https://chat.monexgon.app/platform/api/v1/accounts/1/account_users \
  -H "api_access_token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 30
  }'

# Verificar en dashboard que ya no aparece
```

---

## 📊 Casos de Uso

### Caso 1: Control Total desde Sistema Externo

**Configuración:**
```yaml
CREATE_NEW_AGENT_FROM_DASHBOARD: false
DELETE_AGENT_FROM_DASHBOARD: false
```

**Flujo:**
1. Usuario solicita acceso en tu sistema
2. Tu sistema valida y crea usuario vía Platform API
3. Administradores de ChatGon solo pueden ver/editar agentes
4. Usuario solicita baja → Tu sistema elimina vía Platform API

**Beneficio:** Control centralizado, auditoría completa.

---

### Caso 2: Creación API, Eliminación Manual

**Configuración:**
```yaml
CREATE_NEW_AGENT_FROM_DASHBOARD: false
DELETE_AGENT_FROM_DASHBOARD: true
```

**Flujo:**
1. Tu sistema controla quién puede acceder (creación)
2. Administradores pueden eliminar desde dashboard si es necesario
3. Útil para limpieza rápida de cuentas de prueba

**Beneficio:** Balance entre control y flexibilidad.

---

### Caso 3: Protección contra Eliminación Accidental

**Configuración:**
```yaml
CREATE_NEW_AGENT_FROM_DASHBOARD: true
DELETE_AGENT_FROM_DASHBOARD: false
```

**Flujo:**
1. Administradores pueden invitar agentes libremente
2. Solo tu sistema puede eliminar agentes
3. Previene borrados accidentales

**Beneficio:** Seguridad contra errores humanos.

---

## 🔄 Despliegue en Coolify

### 1. Configurar Variables

**En Coolify → Tu App → Environment Variables:**

```bash
CREATE_NEW_AGENT_FROM_DASHBOARD=false
DELETE_AGENT_FROM_DASHBOARD=false
```

### 2. Deploy

```bash
# Desde panel de Coolify
1. Click en "Deploy"
2. ✅ Activar "Force Rebuild"
3. Esperar 10-15 minutos
```

### 3. Verificar

```bash
# SSH al servidor
ssh usuario@tu-servidor.com

# Ver logs del contenedor
docker logs -f chatgon-rails | grep "AGENT"

# Entrar a Rails console
docker exec -it chatgon-rails bundle exec rails console

# Verificar configuración
GlobalConfig.get_value('CREATE_NEW_AGENT_FROM_DASHBOARD')
GlobalConfig.get_value('DELETE_AGENT_FROM_DASHBOARD')
```

---

## 🔓 Revertir Cambios

Si necesitas volver a habilitar la creación/eliminación desde dashboard:

### Opción 1: Variables de Entorno (Rápido)

**En Coolify:**
```bash
CREATE_NEW_AGENT_FROM_DASHBOARD=true
DELETE_AGENT_FROM_DASHBOARD=true
```

**Deploy normal** (sin Force Rebuild)

### Opción 2: Super Admin Panel (Permanente)

1. Ir a: `/super_admin`
2. Installation Configs
3. Buscar: `CREATE_NEW_AGENT_FROM_DASHBOARD`
4. Cambiar a: `true`
5. Buscar: `DELETE_AGENT_FROM_DASHBOARD`
6. Cambiar a: `true`
7. Save

**No requiere deploy**, cambio inmediato.

---

## 🛡️ Seguridad

### Protecciones Implementadas

✅ **Frontend:** Botones ocultos si está deshabilitado
✅ **Backend:** Endpoints bloqueados con 404 si está deshabilitado
✅ **Platform API:** Siempre disponible (requiere token)
✅ **Última Admin:** Protección se mantiene en frontend

### Protecciones NO Implementadas en Platform API

❌ **No valida último administrador** - Puedes eliminar el último admin
❌ **No valida límites de licencias** - Puedes exceder el límite
❌ **No envía emails de confirmación** - Usuarios creados directamente

**Recomendación:** Implementa estas validaciones en tu sistema antes de llamar Platform API.

---

## 📞 Troubleshooting

### Problema 1: Botones siguen apareciendo

**Causa:** Variables no cargadas o cache del navegador

**Solución:**
```bash
# 1. Verificar variables en Rails console
docker exec -it chatgon-rails bundle exec rails console
GlobalConfig.get_value('CREATE_NEW_AGENT_FROM_DASHBOARD')

# 2. Limpiar cache del navegador
# Hard refresh: Ctrl+Shift+R (Windows) o Cmd+Shift+R (Mac)

# 3. Verificar que no haya override en Super Admin
# Ir a /super_admin → Installation Configs
```

### Problema 2: API retorna 404

**Causa:** Token incorrecto o app de plataforma deshabilitada

**Solución:**
```bash
# 1. Verificar token
curl -X GET https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: YOUR_TOKEN"

# 2. Verificar app en Super Admin
# /super_admin → Platform Apps → Verificar estado "Active"
```

### Problema 3: No se puede crear usuario

**Causa:** Email ya existe o validación falla

**Solución:**
```bash
# Ver logs detallados
docker logs -f chatgon-rails

# Verificar si email existe
docker exec -it chatgon-rails bundle exec rails console
User.find_by(email: 'test@monexgon.com')
```

---

## 📚 Referencias

- **Platform API Reference:** `deployment/PLATFORM_API_REFERENCE.md`
- **Roles & Permissions:** `deployment/ROLES_AND_PERMISSIONS.md`
- **Private System Setup:** `deployment/DEPLOY_PRIVATE_SYSTEM.md`

---

**Última actualización:** Enero 2025
**Versión:** ChatGon 3.x
**Estado:** Pendiente de implementación
