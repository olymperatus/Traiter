import json, logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

log = logging.getLogger("assistant.server")

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

class Handler(BaseHTTPRequestHandler):
    stt = None
    tts = None
    ai_cfg = None
    prompts = None

    def log_message(self, *a):
        pass

    def _json(self, data, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode())

    def _read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        if not length:
            return {}
        try:
            return json.loads(self.rfile.read(length).decode())
        except json.JSONDecodeError:
            return {}

    def do_GET(self):
        if self.path == "/ping":
            return self._json({"status": "ok"})
        elif self.path == "/listen":
            try:
                text = self.stt.listen()
                return self._json({"text": text})
            except Exception as e:
                return self._json({"error": str(e)}, 500)
        elif self.path == "/stop_listen":
            self.stt.stop()
            return self._json({"status": "ok"})
        elif self.path == "/colors":
            from . import colors
            ttl = getattr(Handler, "colors_cache_ttl", 60)
            return self._json({"colors": colors.extract(None, ttl)})
        self._json({"error": "not found"}, 404)

    def do_POST(self):
        data = self._read_body()
        if self.path == "/speak":
            try:
                self.tts.speak(data.get("text", ""))
                return self._json({"status": "ok"})
            except Exception as e:
                return self._json({"error": str(e)}, 500)
        elif self.path == "/query":
            from . import ai
            try:
                text = ai.query(data.get("text", ""), self.ai_cfg, self.prompts)
                return self._json({"text": text})
            except Exception as e:
                return self._json({"error": str(e)}, 500)
        elif self.path == "/stop_listen":
            self.stt.stop()
            return self._json({"status": "ok"})
        self._json({"error": "not found"}, 404)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()


def start(host, port, stt, tts, ai_cfg, prompts=None):
    Handler.stt = stt
    Handler.tts = tts
    Handler.ai_cfg = ai_cfg
    Handler.prompts = prompts or {}
    server = ThreadedHTTPServer((host, port), Handler)
    log.info("Server on http://%s:%d", host, port)
    print(json.dumps({"type": "ready", "port": port}), flush=True)
    server.serve_forever()
