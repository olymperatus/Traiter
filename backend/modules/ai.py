import json, urllib.request, logging

log = logging.getLogger("assistant.ai")

API_URL = "https://api.deepseek.com/v1/chat/completions"

def query(text, cfg, prompts=None):
    messages = []
    if prompts and "system_prompt" in prompts:
        messages.append({"role": "system", "content": prompts["system_prompt"]})
    messages.append({"role": "user", "content": text})

    payload = json.dumps({
        "model": cfg["model"],
        "messages": messages,
        "stream": False,
        "max_tokens": prompts.get("max_tokens", 512) if prompts else 512,
        "temperature": prompts.get("temperature", 0.7) if prompts else 0.7,
    }).encode()
    req = urllib.request.Request(
        API_URL, data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {cfg['api_key']}",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=cfg.get("timeout", 30)) as resp:
            result = json.loads(resp.read())
        content = result.get("choices", [{}])[0].get("message", {}).get("content", "")
        return content
    except Exception as e:
        log.error("AI error: %s", e)
        raise
