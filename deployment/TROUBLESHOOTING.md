# ChatGon - Guía de Troubleshooting

## 🔧 Problema: Los logos de Chatwoot siguen apareciendo

### Causa
Los logos se almacenan en la base de datos (tabla `installation_configs`) y no se actualizan automáticamente solo copiando archivos a `/public/brand-assets/`.

### Solución

#### Opción 1: Ejecutar Script de Actualización (Recomendado)
```bash
# Desde el contenedor de Rails
docker exec -it chatgon-app bundle exec rails runner update_brand_assets.rb
```

#### Opción 2: Actualización Manual desde Rails Console
```bash
# Acceder a Rails console
docker exec -it chatgon-app bundle exec rails console

# Ejecutar en la consola:
configs = {
  'INSTALLATION_NAME' => 'ChatGon',
  'BRAND_NAME' => 'ChatGon',
  'BRAND_URL' => 'https://chat.monexgon.app',
  'WIDGET_BRAND_URL' => 'https://chat.monexgon.app',
  'BRAND_COLOR' => '#2781F6',
  'LOGO' => '/brand-assets/logo-cg.svg',
  'LOGO_DARK' => '/brand-assets/logo-dark.svg',
  'LOGO_THUMBNAIL' => '/brand-assets/logo-thumbnail.svg'
}

configs.each do |key, value|
  config = InstallationConfig.find_or_initialize_by(name: key)
  config.value = value
  config.save!
  puts "Updated #{key}"
end
```

#### Opción 3: Redeploy con Docker Compose
Si usas `docker-compose.chatgon.yaml`, simplemente reinicia:
```bash
docker-compose -f docker-compose.chatgon.yaml down
docker-compose -f docker-compose.chatgon.yaml up -d
```

El servicio `chatgon-brand-setup` se ejecutará automáticamente y actualizará la configuración.

### Verificación
```bash
# Ver configuración actual en base de datos
docker exec -it chatgon-app bundle exec rails runner "
  puts 'Current Brand Configuration:'
  ['LOGO', 'LOGO_DARK', 'LOGO_THUMBNAIL', 'BRAND_NAME'].each do |key|
    config = InstallationConfig.find_by(name: key)
    puts \"#{key}: #{config&.value || 'NOT SET'}\"
  end
"
```

### Después de la actualización:
1. **Reinicia la aplicación:**
   ```bash
   docker restart chatgon-app chatgon-sidekiq
   ```

2. **Limpia el caché del navegador:**
   - Chrome/Firefox: `Ctrl + Shift + R` (Windows/Linux)
   - Safari: `Cmd + Shift + R` (Mac)
   - O abre en ventana privada/incógnito

---

## 🔧 Problema: Alertas de Premium Features

### Síntomas
- Banner rojo en Super Admin Settings
- Mensaje: "Unauthorized premium changes detected"

### Solución
```bash
# Limpiar warning de Redis
docker exec -it chatgon-app bundle exec rails runner clear_premium_warning.rb

# O manualmente:
docker exec -it chatgon-app bundle exec rails runner "
  Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  puts 'Warning cleared'
"
```

---

## 🔧 Problema: Favicons no actualizados

### Causa
El navegador cachea los favicons agresivamente.

### Solución
1. **Limpia caché del navegador**
2. **Fuerza recarga con Ctrl+Shift+R**
3. **Verifica que los archivos existen:**
   ```bash
   docker exec -it chatgon-app ls -la /app/public/ | grep favicon
   ```

4. **Si faltan favicons, cópialos:**
   ```bash
   # Los favicons deben estar en:
   /public/favicon-16x16.png
   /public/favicon-32x32.png
   /public/favicon-96x96.png
   /public/apple-icon-*.png
   /public/android-icon-*.png
   ```

---

## 🔧 Problema: Logo no cambia en el widget

### Causa
El widget tiene su propia configuración de logo.

### Solución
1. **Verifica el archivo:**
   ```bash
   docker exec -it chatgon-app ls -la /app/public/brand-assets/logo_thumbnail.svg
   ```

2. **Actualiza la configuración:**
   ```bash
   docker exec -it chatgon-app bundle exec rails runner "
     config = InstallationConfig.find_or_create_by(name: 'LOGO_THUMBNAIL')
     config.value = '/brand-assets/logo-thumbnail.svg'
     config.save!
   "
   ```

3. **Reinicia servicios:**
   ```bash
   docker restart chatgon-app
   ```

---

## 🔧 Problema: Telemetría externa sigue activa

### Verificación
```bash
# Verificar variable de entorno
docker exec -it chatgon-app env | grep DISABLE_TELEMETRY
# Debe mostrar: DISABLE_TELEMETRY=true
```

### Solución
Agregar en variables de entorno de Coolify:
```
DISABLE_TELEMETRY=true
CHATGON_HUB_URL=https://chat.monexgon.app
```

Luego redeploy.

---

## 🔧 Problema: Idioma en inglés por defecto

### Solución
Agregar variable de entorno:
```
DEFAULT_LOCALE=es
```

O actualizar en base de datos:
```bash
docker exec -it chatgon-app bundle exec rails runner "
  config = InstallationConfig.find_or_create_by(name: 'DEFAULT_LOCALE')
  config.value = 'es'
  config.save!
"
```

---

## 📊 Comandos Útiles

### Ver todas las configuraciones:
```bash
docker exec -it chatgon-app bundle exec rails runner "
  InstallationConfig.all.each do |c|
    puts \"#{c.name}: #{c.value}\"
  end
"
```

### Ver estado de Redis:
```bash
docker exec -it chatgon-redis redis-cli -a \$REDIS_PASSWORD INFO
```

### Ver logs en tiempo real:
```bash
docker logs -f chatgon-app
docker logs -f chatgon-sidekiq
```

### Reiniciar todo:
```bash
docker restart chatgon-app chatgon-sidekiq
```

---

## 🆘 Soporte

Si ninguna solución funciona:
1. Revisa logs: `docker logs chatgon-app`
2. Verifica variables de entorno en Coolify
3. Confirma que los archivos están en `/public/brand-assets/`
4. Prueba un redeploy completo desde Coolify