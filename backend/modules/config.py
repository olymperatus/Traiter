import json, os, sys, logging
from pathlib import Path

log = logging.getLogger("assistant.config")

DEFAULT_CONFIG = {
    "server": {"host": "127.0.0.1", "port": 58901},
    "deepseek": {"api_key": "", "model": "deepseek-chat", "timeout": 30},
    "prompts": {"file": "prompts.json"},
    "stt": {"model_size": "tiny", "device": "cpu", "compute_type": "int8",
            "language": "es", "sample_rate": 16000, "record_timeout": 30,
            "silence_timeout": 3, "vad_threshold": 0.015, "no_speech_timeout": 8},
    "tts": {"sample_rate": 22050, "output_sample_rate": 44100},
    "pid_file": "/tmp/traiter_backend.pid",
    "colors_cache_ttl": 60,
}

def _deep_merge(base, override):
    merged = base.copy()
    for key, val in override.items():
        if key in merged and isinstance(merged[key], dict) and isinstance(val, dict):
            merged[key] = _deep_merge(merged[key], val)
        else:
            merged[key] = val
    return merged

def _resolve_path(name):
    return Path(__file__).parent.parent / name

def load():
    path = _resolve_path("config.json")
    if not path.exists():
        log.warning("config.json not found, using defaults")
        return DEFAULT_CONFIG
    try:
        with open(path) as f:
            cfg = json.load(f)
        return _deep_merge(DEFAULT_CONFIG, cfg)
    except Exception as e:
        log.error("Failed to load config: %s", e)
        return DEFAULT_CONFIG

def load_prompts(cfg):
    rel = cfg.get("prompts", {}).get("file", "prompts.json")
    path = _resolve_path(rel)
    if not path.exists():
        log.warning("%s not found", path.name)
        return {}
    try:
        with open(path) as f:
            return json.load(f)
    except Exception as e:
        log.error("Failed to load prompts: %s", e)
        return {}
