#!/usr/bin/env python3
"""Traiter AI Assistant - Entry point"""

import sys, logging, atexit

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s %(message)s")
log = logging.getLogger("assistant")

from modules import config, zombie, stt, tts, server

cfg = config.load()

zombie.guard(cfg["pid_file"])
atexit.register(lambda: zombie.cleanup(cfg["pid_file"]))

log.info("Initializing STT...")
stt_mod = stt.STT(cfg["stt"])

log.info("Initializing TTS...")
tts_mod = tts.TTS(cfg["tts"])

prompts = config.load_prompts(cfg)

log.info("Starting server...")
server.start(
    cfg["server"]["host"],
    cfg["server"]["port"],
    stt_mod,
    tts_mod,
    cfg["llm"],
    prompts,
)
