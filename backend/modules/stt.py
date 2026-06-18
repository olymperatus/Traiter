import time, threading, logging
import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel

log = logging.getLogger("assistant.stt")

try:
    import webrtcvad
    HAS_WEBRTC = True
except ImportError:
    HAS_WEBRTC = False
    log.warning("webrtcvad not installed, falling back to energy VAD")


class STT:
    def __init__(self, cfg):
        self.cfg = cfg
        self.model = None
        self._stop_ev = threading.Event()
        self._warm_up()

    def _warm_up(self):
        log.info("Loading Whisper %s...", self.cfg["model_size"])
        self.model = WhisperModel(
            self.cfg["model_size"],
            device=self.cfg["device"],
            compute_type=self.cfg["compute_type"],
        )
        dummy = np.zeros(int(self.cfg["sample_rate"] * 0.5), dtype=np.float32)
        self.model.transcribe(dummy, beam_size=1, language=self.cfg["language"])
        log.info("Whisper loaded & warmed up")

    def listen(self):
        self._stop_ev.clear()
        buf = []
        sr = self.cfg["sample_rate"]
        silence_timeout = self.cfg.get("silence_timeout", 3)
        max_timeout = self.cfg["record_timeout"]
        threshold = self.cfg.get("vad_threshold", 0.015)
        no_speech_timeout = self.cfg.get("no_speech_timeout", 8)

        vad = webrtcvad.Vad(1) if HAS_WEBRTC else None
        frame_ms = 30
        frame_size = int(sr * frame_ms / 1000)
        spoke = False
        speech_frames = 0
        silence_frames = 0

        def cb(indata, frames, time_info, status):
            if status and status.value:
                log.warning("Audio status: %s", status)
            buf.append(indata.copy())

        try:
            with sd.InputStream(
                samplerate=sr, channels=1,
                dtype="float32", callback=cb,
                blocksize=frame_size,
            ):
                t0 = time.time()

                while not self._stop_ev.is_set():
                    elapsed = time.time() - t0
                    if elapsed > max_timeout:
                        log.debug("Max timeout")
                        break

                    if len(buf) == 0:
                        self._stop_ev.wait(0.01)
                        continue

                    latest = buf[-1].flatten()

                    if vad is not None:
                        raw = (latest * 32767).clip(-32768, 32767).astype(np.int16)
                        speech = vad.is_speech(raw.tobytes(), sr)
                    else:
                        rms = np.sqrt(np.mean(latest ** 2))
                        speech = rms > threshold

                    if speech:
                        speech_frames += 1
                        if speech_frames >= 2 and not spoke:
                            spoke = True
                            log.debug("Speech started at %.1fs", elapsed)
                        silence_frames = 0
                    else:
                        speech_frames = 0
                        if spoke:
                            silence_frames += 1
                            silence_ms = silence_frames * frame_ms
                            if silence_ms >= silence_timeout * 1000:
                                log.debug("Silence timeout at %.1fs", elapsed)
                                break

                    if not spoke and elapsed > no_speech_timeout:
                        log.debug("No speech within %.0fs", no_speech_timeout)
                        break

                    self._stop_ev.wait(0.01)

            if not buf:
                return ""
            audio = np.concatenate(buf, axis=0).flatten()
            elapsed = time.time() - t0
            log.debug("Recorded %.1fs, spoke=%s", elapsed, spoke)

            if not spoke:
                return ""

            segments, _ = self.model.transcribe(
                audio, beam_size=5, language=self.cfg["language"],
                vad_filter=True, vad_parameters={"threshold": 0.5, "min_speech_duration_ms": 250}
            )
            text = " ".join(s.text for s in segments).strip()
            log.info("STT: %s (in %.1fs)", text, time.time() - t0)
            return text
        except Exception as e:
            log.error("STT error: %s", e)
            raise

    def stop(self):
        self._stop_ev.set()
