# Changelog — Tidy

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
