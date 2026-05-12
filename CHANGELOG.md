# Changelog — Tidy

## [1.7.0] — En desarrollo

### 🔐 Seguridad
- **App Sandbox reactivado** — Tidy solo accede a Downloads, nada más
- **Validación de destinos** — las reglas no pueden mover archivos fuera de Downloads
- **Modo protegido** — confirmación antes de mover archivos mayores a X MB
- **Log de errores** — registra cuando un movimiento falla y por qué
- **Manejo explícito de errores** — ya no se silencian con `try?`

### ✨ Nuevas features
- **Papelera primero** — opción de enviar a papelera en vez de organizar directamente
- **Detector de duplicados** — encuentra archivos con el mismo nombre en distintas subcarpetas
- **Quick Look** — previsualiza archivos desde la vista previa antes de moverlos
- **Log de errores visible** — nueva sección en Historial para ver movimientos fallidos

### 🔧 Mejoras
- URL del repositorio como constante configurable
- Mensajes de error claros cuando un archivo no se puede mover

---

## [1.6.1] — 2025-05-09

### 🐛 Fixes
- Migración automática de categorías — extensiones nuevas (`avif`, `jxl`, `epub`, etc.) se agregan a instalaciones existentes
- App renombrada correctamente a **Tidy** (bundle ID y nombre de producto)
- Ícono modo claro rediseñado con mayor contraste y visibilidad
- Actividad reciente limitada a 5 entradas con botón "Ver todos" que navega al Historial

---

## [1.6.0] — 2025-05-09

### ✨ Nuevas features
- **Categoría Books** — `epub`, `mobi`, `azw3`, `djvu`, `ics`, `vcf`
- **Categoría Design** — `psd`, `ai`, `sketch`, `figma`, `xcf`, `indd`
- **Lista de exclusiones** — define extensiones que Tidy nunca debe mover
- **Vista previa** — muestra qué archivos va a mover antes de ejecutar
- **Exportar/importar configuración** — guarda y restaura categorías y reglas

### 🗂️ Extensiones nuevas en categorías existentes
- Imágenes: `avif`, `jxl`
- Código: `kt`, `kts`, `vue`, `svelte`, `toml`, `env`
- Documentos: `epub` movido a Books

### 🔧 Mejoras
- Filosofía "solo archivos sueltos" — carpetas existentes nunca se tocan
- Archivos del sistema (`.DS_Store`, `.localized`) excluidos automáticamente
- Eliminada la ruta de carpeta en Panel Principal — UI más limpia
- Sonido sutil al organizar archivos
- Onboarding en primer uso
- Contador de archivos movidos hoy en Menu Bar
- Modo silencioso — organizar sin notificaciones temporalmente
- No mover archivos menores a tamaño mínimo configurable

---

## [1.5.0] — 2025-05-08

### ✨ Nuevas features
- **Menu Bar App** — Tidy vive en la barra superior del Mac con acceso rápido a organizar, deshacer y ver estadísticas
- **Reglas personalizadas** — Mueve archivos por nombre, extensión, tamaño o antigüedad a carpetas específicas
- **Deshacer movimientos** — Revierte cualquier movimiento desde el historial o con `Cmd+Shift+Z`
- **Estadísticas semanales** — Gráfica de actividad por día y desglose por categoría
- **Organización programada** — Configura Tidy para organizar cada hora, día o semana automáticamente
- **Notificaciones nativas** — Aviso cuando Tidy organiza archivos automáticamente
- **Ajustes** — Panel centralizado para todas las preferencias
- **Persistencia** — La configuración se guarda entre sesiones (UserDefaults)

### 🔧 Mejoras
- Renombrada la app de "DownloadOrganizer" a **Tidy**
- Sidebar expandida con secciones General y Análisis
- Reglas tienen prioridad sobre categorías al organizar
- El watcher ahora llama a `recalcStats()` automáticamente

### 🐛 Fixes
- Corregido `onChange` deprecado en macOS 14 (HomeView)
- Eliminado warning de `"vibrant"` en Assets.xcassets

---

## [1.0.0] — 2025-05-07

### 🚀 Lanzamiento inicial
- Organización manual de la carpeta Downloads
- Vigilancia automática al detectar archivos nuevos
- 8 categorías editables (Images, Documents, Videos, Audio, Archives, Code, Apps, Fonts)
- Historial de movimientos con búsqueda
- Íconos adaptativos: claro, oscuro y Liquid Glass
- Script `build_dmg.sh` para generar instalador automático
