# Traiter — Voice AI Assistant for QuickShell / Hyprland

Voice-activated AI assistant using **your preferred LLM provider**, powered by **faster-whisper** and **piper-tts**. Integrates as an overlay in QuickShell (Illogical Impulse). Press `SUPER + H`, speak, and the AI responds with voice.

## Requirements

- **QuickShell** with the **ii** profile (Illogical Impulse)
- **Hyprland** (or any Wayland compositor with layer-shell support)
- **Python 3.10+** with `pip` and `venv`
- **Arch Linux** recommended (scripts are tested on Arch)

## Quick Install

```bash
git clone https://github.com/olymperatus/Traiter.git
cd Traiter
chmod +x install.sh
./install.sh
```

This will:
1. Create a Python virtual environment and install dependencies
2. Download an English TTS voice model (amy-medium, ~44MB)
3. Symlink QML files to `~/.config/quickshell/ii/modules/ii/assistant/`
4. Symlink the backend to `~/.config/quickshell/ii/scripts/assistant/main.py`

## Manual Configuration

### 1. Register in panel family

In `~/.config/quickshell/ii/panelFamilies/IllogicalImpulseFamily.qml`:

```qml
PanelLoader { component: Assistant {} }
```

### 2. Add a keybind

In your Hyprland keybinds.lua:

```lua
hl.bind("SUPER + H", hl.dsp.global("assistant:toggle"),
    { description = "Assistant: Toggle AI Assistant" })
```

### 3. LLM provider setup

Edit `backend/config.json`:

```json
{
  "llm": {
    "api_key": "your-api-key",
    "model": "gemini-2.5-flash",
    "api_url": "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
  }
}
```

Supported providers (OpenAI-compatible API):
- **DeepSeek**: `https://api.deepseek.com/v1/chat/completions`
- **OpenAI**: `https://api.openai.com/v1/chat/completions`
- **OpenRouter**: `https://openrouter.ai/api/v1/chat/completions`
- **Gemini** (via OpenRouter): `model: google/gemini-2.5-flash`

Leave `api_url` empty to use the built-in DeepSeek endpoint.

### 4. Restart QuickShell

```bash
killall quickshell; qs -c ii &
```

## Usage

1. `SUPER + H` — opens the overlay and starts listening
2. Speak directly (no buttons needed)
3. After 3 seconds of silence, the AI processes your speech and responds with voice
4. If no speech is detected, the AI still responds (greeting)
5. `SUPER + H` or click outside — closes and cancels

## Project Structure

```
traiter/
├── backend/
│   ├── main.py              — Python server
│   ├── config.json          — Configuration (API key, timing, etc.)
│   ├── config.example.json  — Example config (safe for repo)
│   ├── prompts.json         — AI system prompt
│   ├── requirements.txt     — Python dependencies
│   ├── download_voice.py    — TTS voice model downloader
│   ├── modules/
│   │   ├── stt.py           — Speech-to-Text (Whisper + WebRTC VAD)
│   │   ├── tts.py           — Text-to-Speech (Piper)
│   │   ├── ai.py            — LLM client (provider-agnostic)
│   │   ├── server.py        — HTTP server (threaded)
│   │   ├── colors.py        — Material You color extraction
│   │   ├── config.py        — Config loader with legacy support
│   │   └── zombie.py        — PID guard (single instance)
│   └── models/              — TTS voice models (.onnx)
├── quickshell/
│   ├── Assistant.qml        — Main controller
│   ├── AssistantOverlay.qml — User interface overlay
│   ├── AssistantBars.qml    — Animated bars
│   ├── AssistantBar.qml     — Individual bar
│   ├── AssistantParticles.qml — Particle system
│   └── Particle.qml         — Single particle
├── install.sh               — Full installer
├── link.sh                  — Symlink only
└── README.md
```

## Configuration

Edit `backend/config.json` to adjust:

| Key | Description | Default |
|-----|-------------|---------|
| `stt.silence_timeout` | Seconds of silence after speech before stopping | 3 |
| `stt.no_speech_timeout` | Max seconds without detecting speech | 8 |
| `stt.model_size` | Whisper model (tiny/base/small) | tiny |
| `stt.language` | STT language code | en |
| `tts.output_sample_rate` | Audio output sample rate | 44100 |
| `llm.model` | LLM model name | gemini-2.5-flash |

## Troubleshooting

**No audio response**: Ensure piper-tts is installed and a voice model exists in `backend/models/`.

**Speech not recognized**: Check your microphone with `pavucontrol`. Adjust `stt.vad_threshold` in `config.json`.

**Restart the backend**:
```bash
kill $(cat /tmp/traiter_backend.pid)
```

**Monitor logs**:
```bash
tail -f /run/user/1000/quickshell/by-id/*/log.qslog
```

## License

GNU GPL v3.0
