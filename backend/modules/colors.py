import logging, time
from pathlib import Path
from materialyoucolor import quantize
from materialyoucolor.hct import Hct
from materialyoucolor.scheme import SchemeContent

log = logging.getLogger("assistant.colors")

DEFAULT = {
    "primary": "#d1c2d2", "onPrimary": "#372d3a",
    "secondary": "#cbc1c9", "tertiary": "#d6c3d8",
    "surface": "#141314", "background": "#141314",
    "surfaceVariant": "#494648", "onSurface": "#e7e1e3",
}

_cache = {"data": None, "ts": 0, "ttl": 60}

def _hex(hct_obj):
    try:
        r, g, b, _ = hct_obj.to_rgba()
        return f"#{r:02x}{g:02x}{b:02x}"
    except Exception:
        return "#d1c2d2"

def extract(wallpaper_path=None, cache_ttl=60):
    _cache["ttl"] = cache_ttl
    now = time.time()
    if _cache["data"] and (now - _cache["ts"]) < _cache["ttl"]:
        return _cache["data"]

    if not wallpaper_path or not Path(wallpaper_path).is_file():
        p = Path.home() / ".local/state/quickshell/user/generated/wallpaper/path.txt"
        if p.exists():
            wallpaper_path = p.read_text().strip()
    if not wallpaper_path or not Path(wallpaper_path).is_file():
        _cache["data"] = DEFAULT
        _cache["ts"] = now
        return DEFAULT

    try:
        color_counts = quantize.ImageQuantizeCelebi(wallpaper_path, 128, 10000)
        if not color_counts:
            _cache["data"] = DEFAULT
            _cache["ts"] = now
            return DEFAULT
        sorted_c = sorted(color_counts.items(), key=lambda x: x[1], reverse=True)
        top = [(Hct.from_int(argb), count) for argb, count in sorted_c[:10]]
        best = max(top, key=lambda x: x[0].chroma)
        scheme = SchemeContent(best[0], True, 0.0)
        result = {
            "primary": _hex(scheme.primary),
            "onPrimary": _hex(scheme.on_primary),
            "secondary": _hex(scheme.secondary),
            "tertiary": _hex(scheme.tertiary),
            "surface": _hex(scheme.surface),
            "background": _hex(scheme.background),
            "surfaceVariant": _hex(scheme.surface_variant),
            "onSurface": _hex(scheme.on_surface),
        }
        _cache["data"] = result
        _cache["ts"] = now
        return result
    except Exception as e:
        log.error("Color error: %s", e)
        _cache["data"] = DEFAULT
        _cache["ts"] = now
        return DEFAULT
