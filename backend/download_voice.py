#!/usr/bin/env python3
"""Download a Spanish piper-tts voice model."""

import sys
import os
from pathlib import Path

MODEL_DIR = Path(__file__).parent / 'models'

VOICES = {
    "sharvard-medium": {
        "url": "https://huggingface.co/rhasspy/piper-voices/resolve/main/es/es_ES/sharvard/medium/es_ES-sharvard-medium.onnx",
        "config": "https://huggingface.co/rhasspy/piper-voices/resolve/main/es/es_ES/sharvard/medium/es_ES-sharvard-medium.onnx.json",
        "size_mb": 50,
    },
    "carlofia-x-low": {
        "url": "https://huggingface.co/rhasspy/piper-voices/resolve/main/es/es_ES/carlofia/x_low/es_ES-carlofia-x-low.onnx",
        "config": "https://huggingface.co/rhasspy/piper-voices/resolve/main/es/es_ES/carlofia/x_low/es_ES-carlofia-x-low.onnx.json",
        "size_mb": 10,
    },
}

def download_file(url, dest):
    import requests
    print(f"Downloading {url.split('/')[-1]}...")
    resp = requests.get(url, stream=True)
    resp.raise_for_status()
    total = int(resp.headers.get('content-length', 0))
    downloaded = 0
    with open(dest, 'wb') as f:
        for chunk in resp.iter_content(chunk_size=8192):
            f.write(chunk)
            downloaded += len(chunk)
            if total:
                pct = downloaded / total * 100
                print(f"\r  {pct:.0f}% ({downloaded//1024//1024}MB/{total//1024//1024}MB)", end='')
    print()

def main():
    os.makedirs(MODEL_DIR, exist_ok=True)

    if len(sys.argv) > 1:
        choice = sys.argv[1]
    else:
        print("Available voices:")
        for i, name in enumerate(VOICES.keys(), 1):
            info = VOICES[name]
            print(f"  {i}. {name} ({info['size_mb']}MB)")
        print(f"\nDefault: sharvard-medium (recommended)")
        choice = "sharvard-medium"

    if choice not in VOICES:
        try:
            idx = int(choice) - 1
            choice = list(VOICES.keys())[idx]
        except (ValueError, IndexError):
            print(f"Unknown voice: {choice}")
            sys.exit(1)

    info = VOICES[choice]
    model_path = MODEL_DIR / f"{choice}.onnx"
    config_path = MODEL_DIR / f"{choice}.onnx.json"

    download_file(info["url"], model_path)
    download_file(info["config"], config_path)
    print(f"Done! Model saved to {model_path}")

if __name__ == '__main__':
    main()
