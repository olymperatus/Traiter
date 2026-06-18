# Traiter — Asistente de voz con IA para QuickShell / Hyprland

Asistente activado por voz que usa **DeepSeek AI**, **faster-whisper** y **piper-tts**. Integrado como overlay en QuickShell (Illogical Impulse). Presiona `SUPER + H`, habla, y la IA responde por audio.

## Requisitos

- **QuickShell** con la configuración **ii** (Illogical Impulse)
- **Hyprland** (o cualquier compositor Wayland con soporte de capas)
- **Python 3.10+**
- **pip** y **venv**

## Instalación

```bash
git clone https://github.com/tu-usuario/traiter
cd traiter
chmod +x install.sh
./install.sh
```

Esto:
1. Crea un entorno virtual Python e instala dependencias
2. Descarga el modelo de voz en español (sharvard-medium, ~50MB)
3. Enlaza los archivos QML a `~/.config/quickshell/ii/modules/ii/assistant/`
4. Enlaza el backend a `~/.config/quickshell/ii/scripts/assistant/main.py`

## Configuración manual

### 1. Agregar al panel familiar

En `~/.config/quickshell/ii/panelFamilies/IllogicalImpulseFamily.qml`:

```qml
PanelLoader { component: Assistant {} }
```

### 2. Agregar atajo de teclado

En `~/.config/hypr/hyprland/keybinds.lua` (o tu archivo de binds):

```lua
hl.bind("SUPER + H", hl.dsp.global("assistant:toggle"),
    { description = "Assistant: Toggle AI Assistant" })
```

### 3. Clave de API DeepSeek

Edita `backend/config.json` y agrega tu `api_key`:

```json
{
  "deepseek": {
    "api_key": "sk-tu-clave-aqui"
  }
}
```

Consigue una clave gratuita en [platform.deepseek.com](https://platform.deepseek.com).

### 4. Reiniciar QuickShell

```bash
killall quickshell; qs -c ii &
```

## Uso

1. `SUPER + H` — abre el overlay y empieza a escuchar automáticamente
2. Habla directamente (sin botones)
3. Después de 3 segundos de silencio, la IA procesa y responde por audio
4. Si no detecta voz, la IA igual responde (saludo)
5. `SUPER + H` o clic fuera — cierra y cancela la operación

## Archivos

```
traiter/
├── backend/
│   ├── main.py              — Servidor Python
│   ├── config.json          — Configuración (API key, tiempos, etc.)
│   ├── prompts.json         — Prompt del sistema de la IA
│   ├── requirements.txt     — Dependencias Python
│   ├── download_voice.py    — Descargar modelos TTS
│   ├── modules/
│   │   ├── stt.py           — Reconocimiento de voz (Whisper + WebRTC VAD)
│   │   ├── tts.py           — Síntesis de voz (Piper)
│   │   ├── ai.py            — Cliente DeepSeek
│   │   ├── server.py        — Servidor HTTP con ThreadingMixIn
│   │   ├── colors.py        — Colores Material You desde el wallpaper
│   │   ├── config.py        — Cargador de configuración
│   │   └── zombie.py        — Protección contra procesos duplicados
│   └── models/              — Modelos de voz .onnx
├── quickshell/
│   ├── Assistant.qml        — Controlador principal
│   ├── AssistantOverlay.qml — Interfaz de usuario
│   ├── AssistantBars.qml    — Barras animadas
│   ├── AssistantBar.qml     — Barra individual
│   ├── AssistantParticles.qml — Sistema de partículas
│   └── Particle.qml         — Partícula individual
├── install.sh               — Instalador completo
├── link.sh                  — Solo enlaces simbólicos
├── monitor.sh               — Panel de monitoreo
└── README.md
```

## Personalización

Edita `backend/config.json` para ajustar:

| Clave | Descripción | Default |
|-------|-------------|---------|
| `stt.silence_timeout` | Segundos de silencio tras hablar | 3 |
| `stt.no_speech_timeout` | Máx. segundos sin detectar voz | 8 |
| `stt.model_size` | Modelo Whisper (tiny/base/small) | tiny |
| `tts.output_sample_rate` | Frecuencia de salida de audio | 44100 |
| `deepseek.model` | Modelo de IA | deepseek-chat |

## Solución de problemas

**No se escucha respuesta**: verifica que `piper-tts` esté instalado y haya un modelo en `backend/models/`.

**El reconocimiento no funciona**: revisa el micrófono con `pavucontrol`. Ajusta `stt.vad_threshold` en `config.json`.

**Para reiniciar el backend**:
```bash
kill $(cat /tmp/traiter_backend.pid)
```

**Ver logs**:
```bash
./monitor.sh -w
```

## Licencia

GNU GPL v3.0
