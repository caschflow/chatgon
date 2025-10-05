# 🔧 Troubleshooting: Errores de Deploy en Coolify

## 🐛 Error: Container name conflict

### Error Completo:
```
Error response from daemon: Conflict. The container name "/g0wo0wskckwko4oko80gg8wg"
is already in use by container "ffb87a525a..."
You have to remove (or rename) that container to be able to reuse that name.
```

### Causa:
Un deploy anterior no terminó correctamente y dejó contenedores "huérfanos" que están bloqueando el nuevo deploy.

---

## ✅ SOLUCIÓN RÁPIDA

### Opción 1: Desde el Panel de Coolify (MÁS FÁCIL)

1. **En tu aplicación ChatGon en Coolify:**
   - Ve a la sección **"Danger Zone"** o **"Advanced"**
   - Busca el botón **"Force Stop"** o **"Stop All"**
   - Click en **"Force Stop"**
   - Espera 30 segundos

2. **Limpiar contenedores:**
   - En la misma sección, busca **"Cleanup"** o **"Clean Resources"**
   - Click en **"Clean Build Containers"** o similar
   - Espera a que complete

3. **Reintentar Deploy:**
   - Ve a **Deployments**
   - Click en **Deploy**
   - ✅ **NO actives Force Rebuild** (por ahora)
   - Espera a que complete

---

### Opción 2: Vía SSH al Servidor (SI TIENES ACCESO)

```bash
# 1. Conectar al servidor
ssh usuario@tu-servidor.com

# 2. Ver contenedores problemáticos
docker ps -a | grep "g0wo0wskckwko4oko80gg8wg"

# 3. Forzar eliminación del contenedor problemático
docker rm -f g0wo0wskckwko4oko80gg8wg

# 4. Si el anterior falla, eliminar por ID
docker rm -f ffb87a525a933362e311f2270a28608ab37fa5b19e0d0211c954ad54bb5eae29

# 5. Limpiar todos los contenedores detenidos
docker container prune -f

# 6. Limpiar recursos huérfanos de build
docker builder prune -f

# 7. Ver contenedores de Coolify/ChatGon
docker ps | grep chatgon

# 8. Si hay contenedores viejos, detenerlos
docker stop $(docker ps -q --filter "name=chatgon")

# 9. Eliminar contenedores detenidos de ChatGon
docker rm $(docker ps -aq --filter "name=chatgon")
```

Después de ejecutar estos comandos, **volver a Coolify y hacer Deploy normal**.

---

### Opción 3: Reiniciar Docker Daemon (ÚLTIMO RECURSO)

**⚠️ CUIDADO:** Esto detendrá TODOS los contenedores en el servidor.

```bash
# Solo si tienes acceso SSH y las opciones anteriores fallaron

# 1. Reiniciar Docker
sudo systemctl restart docker

# 2. Esperar 30 segundos
sleep 30

# 3. Verificar que Docker esté corriendo
sudo systemctl status docker

# 4. Limpiar recursos
docker system prune -f

# 5. Volver a Coolify y reintentar deploy
```

---

## 🔍 DIAGNÓSTICO

### Ver estado actual de contenedores:

```bash
# Todos los contenedores
docker ps -a

# Solo de ChatGon/Coolify
docker ps -a | grep -i "chatgon\|coolify"

# Ver contenedores en estado de eliminación
docker ps -a --filter "status=removing"

# Ver volúmenes huérfanos
docker volume ls -f dangling=true

# Ver imágenes sin uso
docker images -f "dangling=true"
```

---

## 🛠️ LIMPIEZA COMPLETA (Si nada más funciona)

**⚠️ ADVERTENCIA:** Esto eliminará TODOS los contenedores detenidos, volúmenes huérfanos, e imágenes sin uso.

```bash
# 1. Detener todos los contenedores
docker stop $(docker ps -q)

# 2. Limpiar todo (CUIDADO: destructivo)
docker system prune -a --volumes -f

# 3. Revisar que quedó limpio
docker ps -a
docker images
docker volume ls

# 4. En Coolify, hacer deploy desde cero
```

**Nota:** Después de esto, Coolify tendrá que reconstruir todo desde cero (tardará más).

---

## 📋 PREVENCIÓN

### Para evitar este error en el futuro:

1. **Esperar a que deploys terminen completamente:**
   - No cancelar deploys a medio proceso
   - No cerrar la pestaña mientras hace deploy
   - Esperar a ver "Deployment successful" o "Failed"

2. **No hacer múltiples deploys simultáneos:**
   - Esperar que el deploy actual termine
   - No hacer click múltiple en "Deploy"

3. **Usar "Stop" antes de "Deploy" si hay problemas:**
   - Si un deploy está tardando mucho
   - Hacer "Stop" primero
   - Esperar 1 minuto
   - Luego hacer "Deploy"

4. **Limpiar periódicamente:**
   - Una vez al mes, hacer "Clean Resources"
   - Esto elimina builds antiguos

---

## 🔄 FLUJO RECOMENDADO DESPUÉS DE SOLUCIONAR

### Pasos para deploy exitoso:

1. ✅ **Limpiar contenedores huérfanos** (Opción 1 o 2 arriba)

2. ✅ **Verificar que no hay contenedores en conflicto:**
   ```bash
   docker ps -a | grep chatgon
   # No debe aparecer nada con status "removing" o "created"
   ```

3. ✅ **Deploy SIN Force Rebuild primero:**
   - Coolify → Deployments → Deploy
   - **NO** activar Force Rebuild
   - Esperar 5-10 min

4. ✅ **Si el deploy normal funciona, ENTONCES hacer Force Rebuild:**
   - Para aplicar los cambios de código JavaScript
   - Coolify → Deployments → Deploy
   - ✅ **Ahora SÍ** activar Force Rebuild
   - Esperar 10-15 min

---

## ❓ FAQ

### P: ¿Por qué sucede este error?

**R:** Cuando un deploy se cancela o falla a medio camino, Docker puede dejar contenedores en estados inconsistentes ("removing", "created", etc.) que bloquean futuros deploys.

### P: ¿Puedo simplemente ignorar el error y reintentar?

**R:** No, debes limpiar los contenedores primero. Coolify seguirá fallando hasta que se limpien.

### P: ¿Perderé datos al limpiar contenedores?

**R:** No, los datos persistentes están en volúmenes. Solo se eliminan contenedores temporales de build.

### P: ¿Cuánto tarda la limpieza?

**R:** Opción 1: 1-2 minutos
**R:** Opción 2: 30 segundos
**R:** Opción 3: 2-3 minutos

### P: ¿El error puede volver a ocurrir?

**R:** Sí, si se cancela un deploy o hay problemas de red durante el deploy. Sigue las recomendaciones de prevención.

---

## 🚨 SI NADA FUNCIONA

### Contactar Soporte de Coolify:

1. **Capturar información:**
   ```bash
   # Logs del daemon de Docker
   sudo journalctl -u docker.service --no-pager -n 100 > docker_logs.txt

   # Estado de contenedores
   docker ps -a > containers_state.txt

   # Logs de Coolify
   docker logs coolify > coolify_logs.txt
   ```

2. **Reportar en:**
   - Discord de Coolify
   - GitHub Issues de Coolify
   - Soporte de tu proveedor de hosting

3. **Información a incluir:**
   - Logs capturados
   - Error exacto de Coolify
   - Pasos para reproducir
   - Versión de Coolify
   - Sistema operativo del servidor

---

## ✅ CHECKLIST POST-SOLUCIÓN

Después de solucionar, verificar:

- [ ] Contenedores huérfanos eliminados
- [ ] Deploy se completó sin errores
- [ ] Aplicación está corriendo (`docker ps | grep chatgon`)
- [ ] Aplicación responde en https://chat.monexgon.app
- [ ] Logs no muestran errores (`docker logs <CONTAINER_NAME>`)
- [ ] Funcionalidades clave funcionan (login, envío de mensajes)

---

**Última actualización:** Octubre 2025
**Para:** ChatGon en Coolify
