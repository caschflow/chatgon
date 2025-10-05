# 🔐 Roles y Permisos en ChatGon

## 📌 Resumen Ejecutivo

**SÍ, un administrador tiene acceso COMPLETO a TODA la información de la cuenta (empresa).**

Esto incluye:
- ✅ Todas las conversaciones (incluso las no asignadas a él)
- ✅ Todos los reportes y analíticas
- ✅ Información de todos los usuarios/agentes
- ✅ Configuraciones completas de la cuenta
- ✅ Datos de todos los contactos
- ✅ Puede crear otros administradores con el mismo nivel de acceso

---

## 🏢 Modelo de Cuentas (Accounts)

ChatGon utiliza un modelo **multi-tenant** donde:

```
┌─────────────────────────────────────────────┐
│  CHATGON (Instalación)                       │
│                                              │
│  ┌─────────────────┐    ┌─────────────────┐ │
│  │  CUENTA A       │    │  CUENTA B       │ │
│  │  "Empresa ABC"  │    │  "Empresa XYZ"  │ │
│  │                 │    │                 │ │
│  │  - 5 Usuarios   │    │  - 3 Usuarios   │ │
│  │  - 10 Inboxes   │    │  - 5 Inboxes    │ │
│  │  - Contactos    │    │  - Contactos    │ │
│  │  - Chats        │    │  - Chats        │ │
│  └─────────────────┘    └─────────────────┘ │
└─────────────────────────────────────────────┘
```

**Cada Cuenta es completamente independiente:**
- Los datos de Cuenta A **NO** son visibles para usuarios de Cuenta B
- Un usuario puede pertenecer a **múltiples cuentas** con roles diferentes
- El acceso se controla **por cuenta**, no globalmente

---

## 👥 Roles Disponibles

ChatGon tiene **2 roles básicos** a nivel de cuenta:

### 1. **Administrator (Administrador)** 🔑

**Acceso COMPLETO** a toda la cuenta:

#### ✅ Puede Ver:
- **TODAS las conversaciones** de la cuenta (incluso las no asignadas)
- **TODOS los reportes** (agentes, equipos, inboxes, tráfico)
- **Información de TODOS los usuarios** (nombres, emails, roles)
- **Todas las configuraciones** de la cuenta
- **Todos los contactos** y su información
- **Analíticas completas** de la operación

#### ✅ Puede Hacer:
- **Crear/editar/eliminar usuarios** (agentes y administradores)
- **Crear/editar/eliminar inboxes**
- **Modificar configuraciones** de la cuenta
- **Gestionar equipos** (teams)
- **Crear/editar reglas de automatización**
- **Crear/editar macros**
- **Crear/editar respuestas enlatadas**
- **Gestionar integraciones**
- **Eliminar conversaciones**
- **Exportar datos**
- **Ver auditorías** (logs de actividad)

#### ❌ NO Puede:
- Acceder a datos de **otras cuentas** (a menos que sea miembro)
- Modificar configuraciones **globales del sistema** (solo Super Admin)
- Crear/eliminar cuentas (solo vía Platform API o Super Admin)

---

### 2. **Agent (Agente)** 👤

**Acceso LIMITADO** solo a lo necesario para trabajar:

#### ✅ Puede Ver:
- **Solo conversaciones asignadas** a él o a sus inboxes
- **Solo sus propias estadísticas**
- Información básica de la cuenta
- Contactos relacionados a sus conversaciones

#### ✅ Puede Hacer:
- **Responder conversaciones** asignadas
- **Crear/editar contactos**
- **Usar respuestas enlatadas**
- **Usar macros**
- **Etiquetar conversaciones**
- **Agregar notas internas**

#### ❌ NO Puede:
- Ver **reportes completos**
- Ver **conversaciones de otros agentes** (a menos que estén en el mismo inbox)
- **Crear/editar/eliminar usuarios**
- **Modificar configuraciones** de inboxes
- **Gestionar equipos**
- **Crear/editar automatizaciones**
- **Eliminar conversaciones**
- **Ver auditorías**

---

## ⚠️ IMPORTANTE: Implicaciones de Seguridad

### Escenario: Admin crea otro Admin

```
┌─────────────────────────────────────────────┐
│  CUENTA: "Empresa ABC"                       │
│                                              │
│  Admin 1 (Creador Original)                 │
│     ↓                                        │
│  Crea → Admin 2 (Nuevo Administrador)       │
│                                              │
│  Ambos tienen ACCESO IDÉNTICO:              │
│  ✓ Todas las conversaciones                 │
│  ✓ Todos los reportes                       │
│  ✓ Toda la información de usuarios          │
│  ✓ Todas las configuraciones                │
│  ✓ Pueden crear más admins                  │
└─────────────────────────────────────────────┘
```

### ⚠️ Riesgos Potenciales

1. **Acceso Total a Información Sensible:**
   - Un admin puede ver **TODAS** las conversaciones, incluyendo información confidencial de clientes
   - Puede ver **credenciales** de integraciones
   - Puede acceder a **reportes financieros/comerciales**

2. **Capacidad de Crear Más Admins:**
   - Un admin puede crear **ilimitados administradores**
   - No hay jerarquía: todos los admins tienen el mismo poder
   - No se puede revocar la capacidad de crear admins

3. **Sin Auditoría de Quién Ve Qué:**
   - No hay logs automáticos de "quién vio qué conversación"
   - No se puede restringir acceso a reportes específicos
   - No hay permisos granulares

4. **Eliminación de Datos:**
   - Un admin puede **eliminar conversaciones**
   - Puede **eliminar otros usuarios** (incluyendo admins)
   - Puede modificar/eliminar **configuraciones críticas**

---

## 🛡️ Recomendaciones de Seguridad

### ✅ Buenas Prácticas

1. **Minimiza el número de Administradores:**
   ```
   ❌ MAL:  10 administradores para 20 agentes
   ✅ BIEN: 1-2 administradores para 20 agentes
   ```

2. **Usa Agentes para operación diaria:**
   - Los agentes solo necesitan acceso a sus conversaciones
   - No necesitan ver reportes ni configuraciones

3. **Documenta quién es Admin:**
   - Mantén registro externo de admins actuales
   - Revisa periódicamente la lista

4. **Política de Creación de Admins:**
   ```
   Solo el CEO/CTO/Gerente de TI puede ser Admin
   Nuevos admins requieren aprobación documentada
   ```

5. **Usa Platform API para crear cuentas:**
   - Control centralizado desde fuera de la UI
   - Logs de creación de cuentas/usuarios

### ❌ Cosas a EVITAR

1. **NO** hacer admin a empleados temporales
2. **NO** crear admins "por si acaso"
3. **NO** compartir credenciales de admin
4. **NO** dejar admins inactivos sin revisar

---

## 🔍 Verificar Quién es Admin en tu Cuenta

### Opción 1: Desde la UI (Admin actual)

1. Login como administrador
2. Ir a **Settings** → **Agents**
3. Ver columna **"Role"**
   - `Administrator` = Admin completo
   - `Agent` = Agente limitado

### Opción 2: Desde Rails Console

```ruby
# Conectar a Rails console
docker exec -it <CONTAINER_NAME> bundle exec rails console

# Ver todos los admins de una cuenta
account = Account.find(1) # Cambiar ID
admins = account.account_users.where(role: :administrator)

admins.each do |au|
  puts "Admin: #{au.user.name} (#{au.user.email})"
end
```

### Opción 3: Desde Base de Datos

```sql
-- Ver admins de cuenta específica
SELECT
  u.name,
  u.email,
  au.role
FROM account_users au
JOIN users u ON au.user_id = u.id
WHERE au.account_id = 1 -- Cambiar ID
  AND au.role = 1; -- 1 = administrator
```

---

## 🔐 Modelo Avanzado: Custom Roles (Enterprise)

ChatGon Enterprise incluye **Custom Roles** que permiten permisos granulares:

```
Custom Role: "Supervisor"
  ✓ Ver reportes
  ✓ Ver todas las conversaciones
  ✗ Crear usuarios
  ✗ Modificar configuraciones
  ✗ Eliminar conversaciones
```

**Nota:** Esto requiere la versión Enterprise y configuración adicional.

---

## 🤔 Preguntas Frecuentes

### P: ¿Un admin puede ver conversaciones privadas de otros agentes?
**R:** **SÍ**, un admin puede ver **TODAS** las conversaciones, sin excepción.

### P: ¿Puedo limitar que un admin solo vea ciertos reportes?
**R:** **NO** en la versión base. Todos los admins ven todos los reportes. Necesitas Custom Roles (Enterprise).

### P: ¿Se puede hacer que un admin no pueda crear otros admins?
**R:** **NO** en la versión base. Cualquier admin puede crear otros admins.

### P: ¿Un admin puede eliminar al admin que lo creó?
**R:** **SÍ**, no hay jerarquía. Todos los admins tienen el mismo poder.

### P: ¿Hay logs de qué admin vio qué conversación?
**R:** **NO** por defecto. Solo hay audit logs de acciones (crear/editar/eliminar), no de vistas.

### P: ¿Un usuario puede ser admin en Cuenta A y agente en Cuenta B?
**R:** **SÍ**, los roles son **por cuenta**. El mismo usuario puede tener roles diferentes en cuentas diferentes.

### P: ¿Cómo protejo información sensible de admins no confiables?
**R:** **NO** uses el rol de admin. Usa agentes y asígnales solo los inboxes necesarios.

---

## 📊 Tabla Comparativa de Permisos

| Permiso | Agent | Administrator |
|---------|-------|---------------|
| Ver sus conversaciones | ✅ | ✅ |
| Ver TODAS las conversaciones | ❌ | ✅ |
| Ver reportes completos | ❌ | ✅ |
| Crear/editar/eliminar usuarios | ❌ | ✅ |
| Crear/editar inboxes | ❌ | ✅ |
| Modificar configuraciones cuenta | ❌ | ✅ |
| Gestionar equipos | ❌ | ✅ |
| Crear automatizaciones | ❌ | ✅ |
| Eliminar conversaciones | ❌ | ✅ |
| Ver audit logs | ❌ | ✅ |
| Exportar datos | ❌ | ✅ |
| Gestionar integraciones | ❌ | ✅ |
| Responder conversaciones | ✅ | ✅ |
| Crear contactos | ✅ | ✅ |
| Usar respuestas enlatadas | ✅ | ✅ |

---

## 🚨 Conclusión: ¿Es Seguro dar Rol de Admin?

### ⚠️ Solo da rol de **Administrator** a:

- ✅ Personas de **TOTAL CONFIANZA**
- ✅ Empleados **PERMANENTES** clave
- ✅ Quienes **NECESITAN** acceso completo (no "por si acaso")
- ✅ Personal con responsabilidad sobre **toda la operación**

### ❌ NO des rol de **Administrator** a:

- ❌ Agentes de soporte operativos
- ❌ Empleados temporales o externos
- ❌ "Por si necesitan algo después"
- ❌ Cualquiera que no necesite ver TODOS los datos

### 💡 Regla de Oro:

> **"Si tienes duda de si alguien debe ser admin, entonces NO debe serlo."**
>
> Usa **Agent** por defecto. Solo promueve a **Administrator** cuando sea absolutamente necesario.

---

**Última actualización:** Octubre 2025
**Versión:** ChatGon 3.x (basado en Chatwoot)
