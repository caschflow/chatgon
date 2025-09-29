# ChatGon - Sistema de Branding Dinámico

Este documento explica cómo personalizar el branding de tu instalación de ChatGon.

## Características

El sistema de branding dinámico permite personalizar:

- **Nombre de la instalación** (`INSTALLATION_NAME`)
- **Nombre del brand** (`BRAND_NAME`)
- **URLs del brand** (`BRAND_URL`, `WIDGET_BRAND_URL`)
- **Color primario del brand** (`BRAND_COLOR`) ⭐ **NUEVO**
- **Logos** (`LOGO`, `LOGO_DARK`, `LOGO_THUMBNAIL`)
- **Manifest display** (`DISPLAY_MANIFEST`)

## Configuración

### 1. Variables de Entorno (.env)

La forma más sencilla es configurar las variables en tu archivo `.env`:

```bash
# Branding Configuration
INSTALLATION_NAME=ChatGon
BRAND_NAME=ChatGon
BRAND_URL=https://chat.monexgon.app
WIDGET_BRAND_URL=https://chat.monexgon.app
BRAND_COLOR=#2781F6
LOGO=/brand-assets/logo.svg
LOGO_DARK=/brand-assets/logo_dark.svg
LOGO_THUMBNAIL=/brand-assets/logo_thumbnail.svg
DISPLAY_MANIFEST=false
```

### 2. Docker Compose

El archivo `docker-compose.chatgon.yaml` incluye un servicio especial `chatgon-brand-setup` que:

1. Se ejecuta automáticamente después de las migraciones
2. Lee las variables de entorno
3. Actualiza la configuración en la base de datos

**Orden de ejecución:**
```
chatgon-db (healthy)
   ↓
chatgon-redis (healthy)
   ↓
chatgon-migrate (completed)
   ↓
chatgon-brand-setup (completed) ⭐ **NUEVO**
   ↓
chatgon-app / chatgon-sidekiq
```

### 3. Cambiar el Color del Brand

El color del brand (`BRAND_COLOR`) ahora se aplica automáticamente en toda la aplicación usando variables CSS.

**Ejemplos de colores:**

```bash
# Azul (default ChatGon)
BRAND_COLOR=#2781F6

# Rojo
BRAND_COLOR=#FF0000

# Verde
BRAND_COLOR=#00FF00

# Morado
BRAND_COLOR=#9333EA
```

**Dónde se aplica:**

- Dashboard principal
- Páginas de autenticación (login, signup, reset password)
- Widget de chat
- Formularios de encuestas
- Todos los componentes que usen la clase `text-n-brand`, `bg-n-brand`, etc.

## Despliegue

### Primera vez

```bash
# 1. Configurar variables en .env
nano .env

# 2. Iniciar servicios
docker-compose -f docker-compose.chatgon.yaml up -d

# El servicio chatgon-brand-setup aplicará automáticamente la configuración
```

### Cambiar branding en instalación existente

```bash
# 1. Actualizar variables en .env
nano .env

# 2. Reiniciar solo el servicio de brand setup
docker-compose -f docker-compose.chatgon.yaml up chatgon-brand-setup

# 3. Reiniciar la aplicación para reflejar cambios
docker-compose -f docker-compose.chatgon.yaml restart chatgon-app
```

### Cambio manual (sin reinicio)

También puedes cambiar la configuración desde Rails console:

```ruby
# Conectar a la consola
docker exec -it chatgon-app bundle exec rails console

# Cambiar el color del brand
config = InstallationConfig.find_by(name: 'BRAND_COLOR')
config.update(value: '#FF0000')

# Los cambios se aplicarán en la próxima recarga de página
```

## Implementación Técnica

### Variables CSS

El sistema usa variables CSS inyectadas dinámicamente en el `<head>` de cada página:

```html
<style>
  :root {
    --brand-color: #2781F6;
  }
</style>
```

### Tailwind Configuration

La configuración de Tailwind (`theme/colors.js`) usa la variable CSS:

```javascript
{
  brand: 'var(--brand-color)',
}
```

### Layouts actualizados

- `app/views/layouts/vueapp.html.erb` - Dashboard principal
- `app/views/widgets/show.html.erb` - Widget de chat
- `app/views/survey/responses/show.html.erb` - Encuestas

## Troubleshooting

### El color no cambia

1. Verificar que la variable esté en `.env`
2. Verificar que el servicio `chatgon-brand-setup` se ejecutó correctamente:
   ```bash
   docker-compose -f docker-compose.chatgon.yaml logs chatgon-brand-setup
   ```
3. Limpiar caché del navegador (Ctrl+Shift+R)

### Servicio brand-setup falla

```bash
# Ver logs
docker-compose -f docker-compose.chatgon.yaml logs chatgon-brand-setup

# Re-ejecutar manualmente
docker-compose -f docker-compose.chatgon.yaml up chatgon-brand-setup
```

### Valores por defecto

Si no se especifica una variable, se usan estos valores por defecto:

- `INSTALLATION_NAME`: ChatGon
- `BRAND_NAME`: ChatGon
- `BRAND_URL`: https://chat.monexgon.app
- `WIDGET_BRAND_URL`: https://chat.monexgon.app
- `BRAND_COLOR`: #2781F6
- `LOGO`: /brand-assets/logo.svg
- `LOGO_DARK`: /brand-assets/logo_dark.svg
- `LOGO_THUMBNAIL`: /brand-assets/logo_thumbnail.svg
- `DISPLAY_MANIFEST`: false

## Archivos Modificados

### Backend
- `config/installation_config.yml` - Nueva configuración `BRAND_COLOR`

### Frontend
- `theme/colors.js` - Color brand usando variable CSS
- `app/views/layouts/vueapp.html.erb` - Inyección de variable CSS
- `app/views/widgets/show.html.erb` - Inyección de variable CSS
- `app/views/survey/responses/show.html.erb` - Inyección de variable CSS

### Docker
- `docker-compose.chatgon.yaml` - Servicio `chatgon-brand-setup`
- `.env.example` - Variables de branding documentadas

## Soporte

Para más información sobre la configuración de Chatwoot, visita:
https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables/