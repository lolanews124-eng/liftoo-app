"""Generate white-background splash + launcher assets from source logo PNG."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "images"
SRC = ASSETS / "liftoo_logo_source.png"
BLACK_THRESHOLD = 42


def _flatten_on_white(src: Image.Image) -> Image.Image:
    src = src.convert("RGBA")
    w, h = src.size
    out = Image.new("RGB", (w, h), (255, 255, 255))
    composed = Image.new("RGBA", (w, h), (255, 255, 255, 255))
    pixels = src.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 16:
                continue
            if r <= BLACK_THRESHOLD and g <= BLACK_THRESHOLD and b <= BLACK_THRESHOLD:
                continue
            composed.putpixel((x, y), (r, g, b, 255))
    out.paste(composed, mask=composed.split()[3])
    return out


def _fit_on_canvas(logo: Image.Image, size: int, fill_ratio: float = 0.82) -> Image.Image:
    canvas = Image.new("RGB", (size, size), (255, 255, 255))
    target = int(size * fill_ratio)
    ratio = min(target / logo.width, target / logo.height)
    nw, nh = int(logo.width * ratio), int(logo.height * ratio)
    resized = logo.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (size - nw) // 2
    y = (size - nh) // 2
    canvas.paste(resized, (x, y))
    return canvas


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"Missing source logo: {SRC}")

    raw = Image.open(SRC)
    flat = _flatten_on_white(raw)
    flat.save(ASSETS / "liftoo_logo.png", format="PNG", optimize=True)

    splash = _fit_on_canvas(flat, 1152, fill_ratio=0.88)
    splash.save(ASSETS / "liftoo_logo_splash.png", format="PNG", optimize=True)

    icon = _fit_on_canvas(flat, 1024, fill_ratio=0.78)
    icon.save(ASSETS / "liftoo_app_icon.png", format="PNG", optimize=True)

    web_icon = icon.resize((192, 192), Image.Resampling.LANCZOS)
    web_icon.save(ROOT / "web" / "favicon.png", format="PNG", optimize=True)
    web_icon.save(ROOT / "web" / "icons" / "Icon-192.png", format="PNG", optimize=True)
    icon512 = icon.resize((512, 512), Image.Resampling.LANCZOS)
    icon512.save(ROOT / "web" / "icons" / "Icon-512.png", format="PNG", optimize=True)

    print("OK: liftoo_logo.png, liftoo_logo_splash.png, liftoo_app_icon.png, web icons")


if __name__ == "__main__":
    main()
