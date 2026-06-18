import logging
from pathlib import Path
import numpy as np
import sounddevice as sd

log = logging.getLogger("assistant.tts")

class TTS:
    def __init__(self, cfg):
        self.cfg = cfg
        self.voice = None
        self._load()

    def _load(self):
        try:
            import piper
        except ImportError:
            log.warning("piper-tts not installed")
            return
        model_dir = Path(__file__).parent.parent / "models"
        onnx = sorted(model_dir.glob("*.onnx"))
        if not onnx:
            log.warning("No voice model in %s", model_dir)
            return
        try:
            self.voice = piper.PiperVoice.load(onnx[0])
            log.info("Piper voice: %s", onnx[0].name)
        except Exception as e:
            log.error("Piper load failed: %s", e)

    def speak(self, text):
        if not self.voice:
            raise RuntimeError("TTS unavailable")
        chunks = list(self.voice.synthesize(text))
        if not chunks:
            raise RuntimeError("No audio generated")
        audio = np.concatenate([c.audio_float_array for c in chunks])
        sr = chunks[0].sample_rate
        target = self.cfg["output_sample_rate"]
        if sr != target:
            old_len = len(audio)
            new_len = int(old_len * target / sr)
            audio = np.interp(
                np.linspace(0, old_len - 1, new_len),
                np.arange(old_len), audio
            )
            sr = target
        sd.play(audio, samplerate=sr)
        sd.wait()
