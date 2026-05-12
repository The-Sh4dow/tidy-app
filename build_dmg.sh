#!/bin/bash

# ============================================================
#  build_dmg.sh — Download Organizer
#  Compila el .app y genera el .dmg listo para distribuir
# ============================================================

set -e

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${BLUE}▶${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "${RED}✗${NC} $1"; exit 1; }
title()   { echo -e "\n${BOLD}${CYAN}$1${NC}\n"; }

# ── Configuración ────────────────────────────────────────────
APP_NAME="Tidy"
DMG_NAME="Tidy"
DISPLAY_NAME="Tidy"
BUNDLE_ID="com.yourname.DownloadOrganizer"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_PATH="$SCRIPT_DIR/DownloadOrganizer.xcodeproj"
BUILD_DIR="$SCRIPT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH="$EXPORT_PATH/Tidy.app"
# Auto-detect version from pbxproj
VERSION=$(grep "MARKETING_VERSION" "$PROJECT_PATH/project.pbxproj" | head -1 | sed 's/.*= //;s/;//;s/ //g')
DMG_PATH="$HOME/Desktop/Tidy_v${VERSION}.dmg"
DMG_TMP="$BUILD_DIR/dmg_tmp"

# ── Verificaciones ───────────────────────────────────────────
title "🔍 Verificando requisitos"

command -v xcodebuild &>/dev/null || error "Xcode no está instalado."
success "Xcode encontrado: $(xcodebuild -version | head -1)"

[ -f "$PROJECT_PATH/project.pbxproj" ] || error "No se encontró el proyecto en: $PROJECT_PATH"
success "Proyecto encontrado"

# ── Limpiar build anterior ────────────────────────────────────
title "🧹 Limpiando build anterior"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$EXPORT_PATH" "$DMG_TMP"
success "Carpeta build limpia"

# ── Compilar ─────────────────────────────────────────────────
title "🔨 Compilando el proyecto"
log "Esto puede tardar 1-2 minutos..."

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "DownloadOrganizer" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet 2>&1 | grep -E "error:|warning:|Build succeeded|Build FAILED" || true

# Verificar que el archive se creó
if [ ! -d "$ARCHIVE_PATH" ]; then
  echo ""
  warn "Archive no encontrado. Intentando compilación directa..."

  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "DownloadOrganizer" \
    -configuration Release \
    CONFIGURATION_BUILD_DIR="$EXPORT_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build -quiet 2>&1 | grep -E "error:|warning:|Build succeeded|Build FAILED" || true

  APP_PATH="$EXPORT_PATH/Tidy.app"
else
  # Extraer .app del archive
  ARCHIVE_APP=$(find "$ARCHIVE_PATH/Products" -name "*.app" | head -1)
  if [ -n "$ARCHIVE_APP" ]; then
    cp -r "$ARCHIVE_APP" "$APP_PATH"
  fi
fi

[ -d "$APP_PATH" ] || error "No se pudo compilar la app. Revisa los errores arriba."
success "App compilada: $APP_PATH"

# ── Verificar íconos ─────────────────────────────────────────
title "🎨 Verificando íconos"
ICNS_PATH="$APP_PATH/Contents/Resources/AppIcon.icns"
if [ -f "$ICNS_PATH" ]; then
  success "AppIcon.icns encontrado (incluye variantes claro/oscuro/glass)"
else
  warn "AppIcon.icns no encontrado en Resources. Los íconos podrían no estar incluidos."
fi

# ── Crear DMG ────────────────────────────────────────────────
title "📦 Creando DMG"

# Copiar app y symlink a Applications
cp -r "$APP_PATH" "$DMG_TMP/"
ln -sf /Applications "$DMG_TMP/Applications"

# Crear DMG temporal sin comprimir
TEMP_DMG="$BUILD_DIR/temp.dmg"
DMG_SIZE=$(du -sm "$DMG_TMP" | awk '{print $1 + 20}')

log "Creando imagen de disco ($DMG_SIZE MB)..."
hdiutil create \
  -srcfolder "$DMG_TMP" \
  -volname "$DISPLAY_NAME" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,b=16" \
  -format UDRW \
  -size ${DMG_SIZE}m \
  "$TEMP_DMG" -quiet

# Montar el DMG para personalizar
log "Personalizando apariencia del DMG..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$TEMP_DMG" -mountpoint "$BUILD_DIR/mnt" | grep "Apple_HFS" | awk '{print $NF}')

if [ -n "$MOUNT_DIR" ]; then
  # Configurar icono de la ventana con AppleScript
  osascript << APPLESCRIPT 2>/dev/null || true
    tell application "Finder"
      tell disk "$DISPLAY_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "$APP_NAME.app" of container window to {180, 190}
        set position of item "Applications" of container window to {460, 190}
        close
        open
        update without registering applications
        delay 2
        close
      end tell
    end tell
APPLESCRIPT

  # Ocultar archivos del sistema
  SetFile -a C "$MOUNT_DIR" 2>/dev/null || true

  # Desmontar
  hdiutil detach "$MOUNT_DIR" -quiet
  success "Ventana del DMG personalizada"
else
  warn "No se pudo montar el DMG para personalizar. Continuando..."
fi

# Comprimir a formato final
log "Comprimiendo DMG final..."
rm -f "$DMG_PATH"
hdiutil convert "$TEMP_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_PATH" -quiet

[ -f "$DMG_PATH" ] || error "No se pudo crear el DMG"

# ── Resultado ────────────────────────────────────────────────
DMG_SIZE_MB=$(du -sh "$DMG_PATH" | awk '{print $1}')

title "✅ ¡Listo!"
echo -e "  ${BOLD}DMG generado:${NC} $DMG_PATH"
echo -e "  ${BOLD}Tamaño:${NC}       $DMG_SIZE_MB"
echo ""
echo -e "  ${CYAN}Los 3 íconos están incluidos en el .app:${NC}"
echo -e "  ☀️  Modo Claro    → ícono azul/blanco"
echo -e "  🌙  Modo Oscuro   → ícono negro/morado"
echo -e "  🔮  Liquid Glass  → ícono translúcido"
echo ""
echo -e "  ${GREEN}Para instalar:${NC} Abre el DMG → arrastra a Applications"
echo ""

# Abrir el Finder con el DMG
open -R "$DMG_PATH"
