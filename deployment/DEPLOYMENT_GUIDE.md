# Guía de Despliegue ChatGon en Coolify

## 📋 Pasos para Actualizar la Aplicación

### 1. Acceder al Panel de Coolify

1. Ingresar a tu panel de Coolify
2. Navegar a tu proyecto **ChatGon**
3. Seleccionar el servicio/aplicación que deseas actualizar

### 2. Realizar el Deploy Desde Git

#### Opción A: Deploy Manual
1. En el panel de tu aplicación, ir a la sección **Deployments**
2. Hacer clic en **Deploy** o **Redeploy**
3. Coolify automáticamente:
   - Descargará los últimos cambios desde la rama `develop`
   - Construirá la nueva imagen Docker
   - Ejecutará las migraciones si están configuradas
   - Reiniciará los servicios

#### Opción B: Deploy Automático (Webhook)
Si tienes configurado el webhook de GitHub:
1. Los cambios pusheados automáticamente dispararán el deploy
2. Coolify detectará el push y comenzará el proceso

### 3. Limpiar Redis Después del Deploy

Una vez completado el deploy, necesitas ejecutar el script de limpieza:

#### Método 1: Desde la Terminal de Coolify
1. En tu aplicación, ir a la sección **Terminal** o **Execute Command**
2. Seleccionar el contenedor **Rails** (app principal)
3. Ejecutar:
```bash
bundle exec rails runner clear_premium_warning.rb
```

#### Método 2: Usar Docker Exec
Si tienes acceso SSH al servidor:
```bash
# Encuentra el ID del contenedor Rails
docker ps | grep chatgon

# Ejecuta el script
docker exec -it <CONTAINER_ID> bundle exec rails runner clear_premium_warning.rb
```

#### Método 3: Configurar como Post-Deploy Hook
Agregar al archivo de configuración de Coolify o Docker:

**Crear archivo**: `deployment/post-deploy.sh`
```bash
#!/bin/bash
echo "Running post-deployment tasks..."

# Limpiar warning de Redis
bundle exec rails runner clear_premium_warning.rb

echo "✓ Redis cleaned successfully"
```

Luego configurar en Coolify:
- **Build Pack** → **Post Deployment Command**: `bash deployment/post-deploy.sh`

### 4. Verificar la Actualización

1. **Verificar que los servicios están corriendo:**
   ```bash
   docker ps
   ```

2. **Ver logs de la aplicación:**
   - En Coolify: Ir a **Logs** y verificar que no hay errores
   - O por terminal:
   ```bash
   docker logs -f <CONTAINER_NAME> --tail 100
   ```

3. **Acceder al Super Admin:**
   - Ir a: `https://chat.monexgon.app/super_admin/settings`
   - Verificar que NO aparece el banner de alerta roja
   - Verificar que todas las features aparecen habilitadas

4. **Verificar Redis:**
   ```bash
   # Conectar a Redis
   docker exec -it <REDIS_CONTAINER_ID> redis-cli -a $REDIS_PASSWORD

   # Verificar que la key no existe
   GET CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING
   # Debe retornar: (nil)
   ```

## 🔄 Proceso Completo de Actualización

### Resumen Paso a Paso:

```
1. Push a GitHub (develop) ✓ [YA REALIZADO]
   ↓
2. Coolify detecta cambios o deploy manual
   ↓
3. Coolify construye nueva imagen
   ↓
4. Coolify ejecuta migraciones (si existen)
   ↓
5. Coolify reinicia contenedores
   ↓
6. Ejecutar script de limpieza de Redis
   ↓
7. Verificar en Super Admin que no hay alertas
   ↓
8. ✓ Deploy completado
```

## 🚨 Troubleshooting

### Si la alerta sigue apareciendo:

1. **Verificar que el script se ejecutó:**
   ```bash
   docker exec -it <RAILS_CONTAINER> bundle exec rails runner "puts Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING).inspect"
   ```
   Debe retornar: `nil`

2. **Ejecutar manualmente la limpieza:**
   ```bash
   docker exec -it <RAILS_CONTAINER> bundle exec rails runner "Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING); puts 'Deleted'"
   ```

3. **Reiniciar todos los servicios:**
   - En Coolify: **Actions** → **Restart All**

4. **Limpiar caché de navegador:**
   - Ctrl + Shift + R (Chrome/Firefox)
   - O abrir en ventana incógnita

### Si los cambios no se reflejan:

1. **Verificar que Coolify usó el último commit:**
   - En **Deployments**, revisar el commit hash
   - Debe ser: `0e92a1c67` o posterior

2. **Forzar rebuild sin caché:**
   - Agregar variable temporal: `DOCKER_BUILDKIT=1`
   - Deploy con opción "Force Rebuild"

3. **Verificar logs de build:**
   - Revisar que no hubo errores durante la construcción
   - Verificar que se instalaron las dependencias correctamente

## 📝 Comandos Útiles

### Verificar estado de la aplicación:
```bash
# Ver todos los contenedores
docker ps

# Ver logs en tiempo real
docker logs -f chatgon-rails

# Ejecutar comando en Rails
docker exec -it chatgon-rails bundle exec rails console

# Verificar versión desplegada
docker exec -it chatgon-rails cat VERSION
```

### Acceder a Rails Console:
```bash
docker exec -it <RAILS_CONTAINER> bundle exec rails console

# Dentro de la consola:
Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
# Debe retornar: nil
```

## ✅ Checklist Post-Deploy

- [ ] Deploy completado sin errores
- [ ] Script de limpieza de Redis ejecutado
- [ ] Super Admin Settings sin alerta roja
- [ ] Todas las features muestran como habilitadas
- [ ] No aparecen botones de "Upgrade"
- [ ] Logo y branding de ChatGon visible
- [ ] Locale en español funcionando
- [ ] Sidekiq procesando jobs correctamente

## 📞 Soporte

Si encuentras problemas durante el despliegue:
1. Revisar logs de Coolify
2. Verificar variables de entorno en `deployment/variables-coolify.md`
3. Contactar al administrador del sistema