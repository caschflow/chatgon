# 🔄 Recrear Contenedor de PostgreSQL

## ⚠️ ADVERTENCIA

**ESTE PROCESO ELIMINARÁ TODOS LOS DATOS DE LA BASE DE DATOS**

Solo ejecuta estos pasos si:
- Tienes un backup de tus datos, O
- Estás dispuesto a perder todos los datos, O
- Es una instalación nueva sin datos importantes

---

## 📋 Pre-requisitos

Antes de comenzar, asegúrate de tener:

1. ✅ **Acceso SSH** al servidor donde corre Coolify
2. ✅ **Nuevo password** de PostgreSQL sin caracteres especiales, O
3. ✅ **DATABASE_URL configurada** con password URL-encoded

---

## 🛑 Paso 1: Detener la Aplicación

### En Coolify:

1. Ve a tu aplicación **chatgon-app**
2. Click en **Stop** o **Force Stop**
3. Espera a que todos los contenedores se detengan

### O vía SSH:

```bash
# Conectar al servidor
ssh usuario@tu-servidor.com

# Detener todos los servicios de ChatGon
docker stop $(docker ps -q --filter "name=chatgon")
docker stop $(docker ps -q --filter "name=ow8swggo0kko48c80o4ckg04")
```

---

## 🗑️ Paso 2: Eliminar Contenedor y Volumen de PostgreSQL

```bash
# 1. Encontrar el contenedor de PostgreSQL
docker ps -a | grep postgres

# 2. Detener y eliminar el contenedor
docker stop postgres-ow8swggo0kko48c80o4ckg04-<ID>
docker rm postgres-ow8swggo0kko48c80o4ckg04-<ID>

# 3. Encontrar el volumen de datos
docker volume ls | grep postgres

# 4. ELIMINAR EL VOLUMEN (⚠️ ESTO BORRA LOS DATOS)
docker volume rm ow8swggo0kko48c80o4ckg04_postgres_data

# O si usas docker-compose.production.yaml localmente:
docker volume rm postgres_data
```

### Alternativa: Eliminar todo y empezar de cero

```bash
# Detener y eliminar TODOS los contenedores de la app
docker-compose -f docker-compose.production.yaml down -v

# Esto eliminará:
# - Todos los contenedores
# - Todos los volúmenes (postgres_data, redis_data, storage_data)
```

---

## 🔧 Paso 3: Actualizar Variables en Coolify

### Opción A: Usar DATABASE_URL (RECOMENDADO)

En Coolify → chatgon-app → Environment Variables:

**Agregar o actualizar:**
```bash
# Con nuevo password sin caracteres especiales
DATABASE_URL=postgresql://postgres:NuevoPassword123@postgres:5432/chatwoot
```

**Eliminar (opcional):**
- `POSTGRES_PASSWORD` (ya no es necesaria si usas DATABASE_URL)

---

### Opción B: Usar Variables Individuales

En Coolify → chatgon-app → Environment Variables:

**Actualizar:**
```bash
# IMPORTANTE: Cambiar el password a uno SIN +, =, @ u otros caracteres especiales
POSTGRES_PASSWORD=NuevoPassword123Simple
POSTGRES_USERNAME=postgres
POSTGRES_DATABASE=chatwoot
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
```

**Eliminar (opcional):**
- `DATABASE_URL` (si existía)

---

## 🚀 Paso 4: Hacer Deploy

### En Coolify:

1. Ve a **Deployments**
2. Click en **Deploy**
3. ✅ **IMPORTANTE:** Activar **"Force Rebuild"**
4. Esperar 10-15 minutos

---

## ✅ Paso 5: Verificar

### 1. Ver logs del contenedor migrate:

```bash
# Buscar el contenedor de migraciones
docker ps -a | grep migrate

# Ver logs
docker logs migrate-ow8swggo0kko48c80o4ckg04-<ID>
```

**Buscar:**
```
✓ Database ready to accept connections
✓ Running migrations...
✓ Database migrated successfully
```

### 2. Verificar que PostgreSQL está corriendo:

```bash
# Ver contenedores activos
docker ps | grep postgres

# Debería mostrar:
# postgres-ow8swggo0kko48c80o4ckg04-...  Up X minutes  (healthy)
```

### 3. Conectar a PostgreSQL para verificar:

```bash
# Conectar al contenedor de PostgreSQL
docker exec -it postgres-ow8swggo0kko48c80o4ckg04-<ID> psql -U postgres -d chatwoot

# Dentro de psql:
\dt  # Listar tablas (deberían aparecer las de ChatGon)
\q   # Salir
```

---

## 📊 Paso 6: Configurar Datos Iniciales

Después de recrear PostgreSQL, necesitas:

### 1. Crear Usuarios Vía Platform API

Ver guía completa en: `deployment/PLATFORM_API_REFERENCE.md`

```bash
# Primero, obtener token de Platform API
docker exec -it rails-ow8swggo0kko48c80o4ckg04-<ID> bundle exec rails console

# Dentro de Rails console:
platform_app = PlatformApp.create!(name: "Admin API")
token = platform_app.access_token.token
puts "Token: #{token}"
exit
```

### 2. Crear Primera Cuenta

```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mi Empresa"
  }'
```

### 3. Crear Primer Usuario

```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/users \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin",
    "email": "admin@monexgon.com",
    "password": "AdminPass123!"
  }'
```

### 4. Asociar Usuario a Cuenta

```bash
curl -X POST https://chat.monexgon.app/platform/api/v1/accounts/{account_id}/account_users \
  -H "api_access_token: TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": {user_id},
    "role": "administrator"
  }'
```

---

## 🐛 Troubleshooting

### Error: "password authentication failed"

**Causa:** El nuevo password todavía tiene caracteres especiales.

**Solución:**
1. Usar un password solo con letras y números: `Abc123def456`
2. O usar DATABASE_URL con URL encoding: `%2B` para `+`, `%3D` para `=`

---

### Error: "volume is in use"

**Causa:** Contenedores aún están usando el volumen.

**Solución:**
```bash
# Detener TODOS los contenedores de la app
docker stop $(docker ps -q --filter "name=ow8swggo0kko48c80o4ckg04")

# Luego intentar eliminar el volumen nuevamente
docker volume rm ow8swggo0kko48c80o4ckg04_postgres_data
```

---

### Las migraciones fallan

**Solución:**
```bash
# Ver logs completos del migrate
docker logs migrate-ow8swggo0kko48c80o4ckg04-<ID>

# Verificar que PostgreSQL está healthy
docker ps | grep postgres

# Verificar conectividad
docker exec -it migrate-ow8swggo0kko48c80o4ckg04-<ID> pg_isready -h postgres -p 5432 -U postgres
```

---

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs completos de todos los contenedores
2. Verificar que las variables de entorno estén correctas en Coolify
3. Confirmar que el nuevo password NO tiene caracteres especiales

---

**Última actualización:** Octubre 2025
**Para:** ChatGon en Coolify
