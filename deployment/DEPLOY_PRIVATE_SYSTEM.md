# 🔒 Deploy: Sistema Privado con Registro vía API

## 📋 Resumen de Cambios

Este deploy implementa un sistema completamente privado donde:
- ❌ **Registro público deshabilitado** - No hay signup en la UI
- ❌ **OAuth/SSO deshabilitado** - Sin Google OAuth, sin SAML
- ✅ **Solo email/password** - Autenticación básica únicamente
- ✅ **Registro vía Platform API** - Solo admins pueden crear cuentas

**Commit:** `f62ae9d3c` - feat: Implement private registration system with API-only access

---

## 🚀 Pasos para Deploy en Coolify

### 1️⃣ Actualizar Variables de Entorno

Antes de hacer el deploy, **actualiza estas variables en Coolify**:

1. En tu proyecto ChatGon, ir a **Settings** → **Environment Variables**
2. Buscar o agregar estas variables:

```bash
# IMPORTANTE: Cambiar estos valores
ENABLE_ACCOUNT_SIGNUP=false
CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false
```

3. **Guardar** los cambios

### 2️⃣ Forzar Rebuild Completo

Como cambiamos archivos JavaScript/Vue, **necesitamos forzar rebuild sin caché**:

#### Opción A: Desde el Panel de Coolify (RECOMENDADO)

1. Ir a tu aplicación ChatGon en Coolify
2. En la sección **Deployments**, hacer clic en **Deploy**
3. ✅ **IMPORTANTE:** Activar la opción **"Force Rebuild"** o **"No Cache"**
4. Confirmar el deploy
5. Esperar a que complete (puede tomar 5-10 minutos)

#### Opción B: Usando Git Force Deploy

Si tienes configurado webhook de Git:
1. En GitHub, ir al commit `f62ae9d3c`
2. Hacer un commit vacío para forzar trigger:
   ```bash
   git commit --allow-empty -m "chore: trigger rebuild for private system"
   git push origin develop
   ```
3. Coolify detectará el push
4. En Coolify, seleccionar **Force Rebuild** cuando se dispare

### 3️⃣ Monitorear el Deploy

1. **Ver logs en tiempo real:**
   - En Coolify: Sección **Logs**
   - Ver que compile los assets correctamente:
     ```
     Compiling...
     asset application.js
     asset application.css
     ```

2. **Verificar que no hay errores** durante:
   - ✅ Bundle install
   - ✅ pnpm install
   - ✅ Asset compilation
   - ✅ Database migration

### 4️⃣ Verificación Post-Deploy

Una vez completado el deploy, verificar:

#### A. Verificar Variables de Entorno

En la terminal de Coolify (o SSH):
```bash
# Conectar al contenedor Rails
docker exec -it <CONTAINER_NAME> sh

# Verificar las variables
env | grep ENABLE_ACCOUNT_SIGNUP
# Debe mostrar: ENABLE_ACCOUNT_SIGNUP=false

env | grep CREATE_NEW_ACCOUNT_FROM_DASHBOARD
# Debe mostrar: CREATE_NEW_ACCOUNT_FROM_DASHBOARD=false
```

#### B. Verificar la UI de Login

1. Ir a `https://chat.monexgon.app/app/login`
2. **NO debe aparecer:**
   - ❌ Link "Crear nueva cuenta"
   - ❌ Botón de Google OAuth
   - ❌ Botón de SAML/SSO
3. **Solo debe aparecer:**
   - ✅ Campo Email
   - ✅ Campo Password
   - ✅ Link "¿Olvidaste tu contraseña?"

#### C. Verificar Rutas API Deshabilitadas

```bash
# Verificar que no existe ruta de signup público
docker exec -it <CONTAINER_NAME> bundle exec rails routes | grep "POST.*accounts.*create"
# No debe aparecer: POST /api/v1/accounts
```

#### D. Verificar Platform API Funcional

El Platform API debe seguir funcionando:

```bash
# Test de Platform API (reemplazar TOKEN y valores)
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: YOUR_PLATFORM_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Company"
  }'
```

---

## 🔧 Troubleshooting

### Problema: Los cambios no se ven en el login

**Causa:** Docker usó caché y no recompiló los assets JavaScript

**Solución:**
```bash
# Opción 1: Redeploy con Force Rebuild
- En Coolify, hacer redeploy con "Force Rebuild" activado

# Opción 2: Limpiar caché de build manualmente
docker builder prune -a
# Luego hacer deploy normal
```

### Problema: Sale error "Route not found" al intentar crear cuenta

**Esperado:** ✅ Esto es correcto, las rutas públicas están deshabilitadas

**Solución:** Usar Platform API para crear cuentas:
```bash
POST /platform/api/v1/accounts
POST /platform/api/v1/users
```

### Problema: Variables de entorno no se actualizan

**Solución:**
```bash
# 1. Verificar en Coolify que las variables estén guardadas
# 2. Reiniciar el contenedor:
docker restart <CONTAINER_NAME>

# 3. O hacer redeploy completo
```

---

## 📝 Checklist Post-Deploy

Marca cuando completes cada paso:

- [ ] Variables `ENABLE_ACCOUNT_SIGNUP=false` configuradas
- [ ] Deploy con Force Rebuild completado sin errores
- [ ] Login UI no muestra opciones de signup/OAuth
- [ ] Platform API funcionando correctamente
- [ ] Usuarios existentes pueden hacer login normalmente
- [ ] No hay errores en logs de Rails/Sidekiq

---

## 🔐 Crear Cuentas Después del Deploy

Con el sistema privado, solo puedes crear cuentas vía Platform API:

### 1. Obtener Token de Platform API

```bash
# Acceder a Rails console
docker exec -it <CONTAINER_NAME> bundle exec rails console

# Crear Platform App y Token
platform_app = PlatformApp.create!(name: "Admin API")
token = platform_app.access_token
puts "Token: #{token.token}"
```

### 2. Crear una Cuenta

```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mi Empresa"
  }'
```

### 3. Crear un Usuario

```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@empresa.com",
    "password": "ContraseñaSegura123",
    "name": "Nombre Usuario"
  }'
```

### 4. Asociar Usuario a Cuenta

```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/ACCOUNT_ID/account_users \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": USER_ID,
    "role": "administrator"
  }'
```

---

## 📞 Soporte

Si tienes problemas con el deploy:
1. Revisar logs completos en Coolify
2. Verificar que el commit `f62ae9d3c` se desplegó
3. Confirmar que se hizo Force Rebuild

**Archivos modificados en este deploy:**
- `app/models/user.rb` - Devise config
- `config/routes.rb` - Routes disabled
- `config/initializers/omniauth.rb` - OAuth disabled
- `app/javascript/v3/views/login/Index.vue` - UI cleaned
- `app/javascript/v3/views/routes.js` - Routes removed
- `docker-compose.production.yaml` - Default values
- `.env.production.example` - Documentation
