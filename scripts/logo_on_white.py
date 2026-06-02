"""Place Liftoo logo on a solid white background for splash & assets."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "liftoo_logo.png"
OUT = ROOT / "assets" / "images" / "liftoo_logo.png"
BLACK_THRESHOLD = 42


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    w, h = src.size
    out = Image.new("RGB", (w, h), (255, 255, 255))
    pixels = src.load()
    composed = Image.new("RGBA", (w, h), (255, 255, 255, 255))
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 16:
                continue
            if r <= BLACK_THRESHOLD and g <= BLACK_THRESHOLD and b <= BLACK_THRESHOLD:
                continue
            composed.putpixel((x, y), (r, g, b, 255))
    out.paste(composed, mask=composed.split()[3])
    out.save(OUT, format="PNG", optimize=True)
    print(f"Saved white-background logo: {OUT} ({w}x{h})")


if __name__ == "__main__":
    main()
