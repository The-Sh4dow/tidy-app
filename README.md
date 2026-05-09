# Download Organizer 📁

App nativa para macOS (SwiftUI) que organiza automáticamente tu carpeta Downloads.

## Características

- **Organización manual**: Botón para organizar todos los archivos al instante
- **Vigilancia automática**: Toggle para monitorear Downloads y organizar cada archivo nuevo al llegar
- **Categorías editables**: Agrega, elimina y edita extensiones por categoría
- **Historial completo**: Log de todos los archivos movidos con fecha y destino
- **8 categorías por defecto**: Images, Documents, Videos, Audio, Archives, Code, Apps, Fonts

## Categorías por defecto

| Carpeta      | Extensiones                                      |
|--------------|--------------------------------------------------|
| Images       | png, jpg, jpeg, gif, webp, bmp, tiff, heic, svg… |
| Documents    | pdf, doc, docx, txt, rtf, xls, xlsx, ppt, key…  |
| Videos       | mp4, mov, avi, mkv, wmv, webm, m4v…             |
| Audio        | mp3, wav, aac, flac, ogg, m4a, aiff…            |
| Archives     | zip, rar, 7z, tar, gz, dmg, iso, pkg…           |
| Code         | swift, py, js, ts, html, css, json, yaml…       |
| Apps         | app, apk, ipa, exe, msi                          |
| Fonts        | ttf, otf, woff, woff2                            |

## Cómo abrir en Xcode

1. Abre `DownloadOrganizer.xcodeproj` con Xcode 15+
2. Coloca todos los archivos `.swift` dentro del grupo `DownloadOrganizer` en el Project Navigator
3. En **Signing & Capabilities**, selecciona tu Team y activa:
   - App Sandbox
   - User Selected File (Read/Write)
   - Downloads Folder (Read/Write)
4. Presiona ▶ para compilar y ejecutar

## Requisitos

- macOS 14.0 (Sonoma) o superior
- Xcode 15+

## Notas

- Los archivos sin extensión reconocida son omitidos (no se mueven)
- Si hay conflicto de nombre, se agrega un sufijo numérico aleatorio
- El historial se guarda solo en memoria (se limpia al cerrar la app)
