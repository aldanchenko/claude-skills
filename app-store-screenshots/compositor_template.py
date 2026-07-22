#!/usr/bin/env python3
"""Compose localized App Store screenshots from clean device captures.

Template from the app-store-screenshots skill. Copy into the project (e.g.
tools/generate_app_store_screenshots.py) and fill the PROJECT CONFIG block.
The phone/tablet screen is a real, untouched capture — UI text can never be
mangled — and captions are font-rendered from per-locale string tables.

Usage:
    python3 generate_app_store_screenshots.py \
        --locale en --src "/path/to/captures" [--device ipad]

Inputs: portrait captures named per SLIDES[].src or `01.png` … `NN.png`:
    iphone: 1290x2796 / 1320x2868 / 1206x2622 (any ~19.5:9 portrait)
    ipad:   2064x2752 / 2048x2732 (any ~3:4 portrait)
Output: app_store_screenshots/<locale>/<slot>/NN-slug.png
    iphone → iphone-6.9 at 1320x2868, ipad → ipad-13 at 2064x2752.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]

# ============================== PROJECT CONFIG ==============================
# TODO: brand these for the app.
ACCENT = (0, 137, 123)          # brand color for teal headline lines + logo chip
LOGO_LETTER = "V"               # letter inside the logo chip on slide 01
LOGO_WORDMARK = "Vorbi"         # wordmark next to the chip on slide 01

BG = (247, 244, 239)            # warm off-white canvas
BLOB = (213, 232, 226)          # soft wash, usually a pale tint of ACCENT
INK = (18, 24, 28)
MUTED = (88, 98, 104)
BEZEL = (24, 24, 26)


@dataclass
class Slide:
    num: str
    slug: str
    src: str                    # default capture filename in --src (NN.png works too)
    layout: str = "hero"        # hero = large, bottom-cropped; float = whole device
    lean: float = -5.0          # degrees; negative leans the top to the left
    blob: str = "right"         # which side gets the big soft wash
    logo: bool = False          # slide 01 carries the logo chip + wordmark


# TODO: define the slide set. Proven 7-slide arc: home/progress (logo) → content
# depth → interactive w/ feedback (float) → catalog → differentiator (float) →
# retention/mistakes → dark mode. Alternate lean sign for variety.
SLIDES = [
    Slide("01", "home", "01.png", logo=True, lean=-5.0, blob="left"),
    Slide("02", "feature-two", "02.png", lean=4.5, blob="right"),
    Slide("03", "feature-three", "03.png", layout="float", lean=-4.0, blob="right"),
    # ...
]

# Headline lines prefixed with "*" render in ACCENT; the rest render ink.
# TODO: fill every locale you ship. Benefit-first, short; the punch line gets "*".
CAPTIONS: dict[str, dict[str, tuple[list[str], str]]] = {
    "en": {
        "01": (["Big Benefit.", "*Punch Line."], "One-line supporting subtitle."),
        "02": (["Second", "*Feature"], "Why it matters."),
        "03": (["Third", "*Feature"], "Why it matters."),
    },
}
# ============================ END PROJECT CONFIG ============================


@dataclass(frozen=True)
class Device:
    canvas: tuple[int, int]
    slot: str                   # output subdirectory, mirrors the ASC slot
    aspect: float               # expected capture aspect (w/h)
    hero_w: int                 # screen width when the device bleeds off the bottom
    float_w: int                # screen width when the whole device stays visible
    head_size: int
    head_min: int
    sub_size: int
    margin: int
    chip: int                   # logo chip side on slide 01
    island: bool                # Dynamic Island (iPhone) vs plain bezel (iPad)


DEVICES = {
    "iphone": Device((1320, 2868), "iphone-6.9", 1290 / 2796, 1020, 900, 150, 96, 62, 96, 118, True),
    "ipad": Device((2064, 2752), "ipad-13", 3 / 4, 1500, 1280, 190, 120, 80, 130, 150, False),
}

_SFNS = "/System/Library/Fonts/SFNS.ttf"
_ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
_ARIAL = "/System/Library/Fonts/Supplemental/Arial.ttf"


def font(size: int, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    """San Francisco (variable) with an Arial fallback. Cyrillic-safe."""
    try:
        f = ImageFont.truetype(_SFNS, size)
        f.set_variation_by_name(weight)
        return f
    except Exception:
        return ImageFont.truetype(
            _ARIAL_BOLD if weight in ("Bold", "Heavy", "Semibold") else _ARIAL, size
        )


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return mask


def background(dev: Device, slide: Slide) -> Image.Image:
    w, h = dev.canvas
    img = Image.new("RGB", (w, h), BG)
    draw = ImageDraw.Draw(img)
    if slide.blob == "right":
        draw.ellipse((w * 0.58, h * 0.24, w * 1.32, h * 0.60), fill=BLOB)
        draw.ellipse((-w * 0.29, h * 0.66, w * 0.32, h * 0.98), fill=BLOB)
    else:
        draw.ellipse((-w * 0.32, h * 0.26, w * 0.36, h * 0.61), fill=BLOB)
        draw.ellipse((w * 0.65, h * 0.68, w * 1.29, h * 0.98), fill=BLOB)
    # Soften the washes so they read as light, not shapes.
    return img.filter(ImageFilter.GaussianBlur(round(42 * w / 1320)))


def device_layer(dev: Device, shot: Image.Image, screen_w: int) -> Image.Image:
    """Device mockup: dark bezel, rounded screen, Dynamic Island on iPhone."""
    s = screen_w / shot.width
    screen_h = round(shot.height * s)
    shot = shot.resize((screen_w, screen_h), Image.LANCZOS)

    if dev.island:
        bez = round(26 * screen_w / 1064)
        r_screen = round(165 * (screen_w / 1290))
    else:
        bez = round(72 * screen_w / 2064)
        r_screen = round(84 * (screen_w / 2064))
    dev_w, dev_h = screen_w + 2 * bez, screen_h + 2 * bez

    layer = Image.new("RGBA", (dev_w, dev_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((0, 0, dev_w - 1, dev_h - 1), r_screen + bez, fill=BEZEL + (255,))

    layer.paste(shot, (bez, bez), rounded_mask((screen_w, screen_h), r_screen))

    if dev.island:
        # Real-device captures don't include the cutout, so draw it (it also
        # cleanly covers the island a simulator capture may contain).
        iw, ih = round(316 * screen_w / 1290), round(95 * screen_w / 1290)
        ix, iy = bez + (screen_w - iw) // 2, bez + round(30 * screen_w / 1290)
        draw.rounded_rectangle((ix, iy, ix + iw, iy + ih), ih // 2, fill=(8, 8, 10, 255))
    return layer


def paste_device(canvas: Image.Image, dev: Device, slide: Slide, shot: Image.Image, top: int) -> None:
    W, H = dev.canvas
    screen_w = dev.hero_w if slide.layout == "hero" else dev.float_w
    layer = device_layer(dev, shot, screen_w)

    rot = layer.rotate(slide.lean, expand=True, resample=Image.BICUBIC)
    # For "float" keep the whole device (plus shadow room) above the bottom edge.
    if slide.layout == "float":
        top = min(top, H - rot.height - 40)

    x = (W - rot.width) // 2 + (round(W * 0.023) if slide.lean < 0 else -round(W * 0.023))
    # Never let the frame clip at the sides — a corner dying mid-edge reads
    # as a bug, unlike the intentional bottom bleed of "hero" slides.
    if rot.width <= W - 48:
        x = max(24, min(x, W - 24 - rot.width))
    y = top - (rot.height - layer.height) // 2 if slide.layout == "hero" else top

    shadow_alpha = rot.split()[3].point(lambda a: a * 45 // 100)
    shadow = Image.new("RGBA", rot.size, (10, 14, 16, 0))
    shadow.putalpha(shadow_alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(44))
    canvas.alpha_composite(shadow, (x, y + 38))
    canvas.alpha_composite(rot, (x, y))


def draw_logo(draw: ImageDraw.ImageDraw, dev: Device, y: int) -> int:
    chip = dev.chip
    draw.rounded_rectangle((dev.margin, y, dev.margin + chip, y + chip), round(chip * 0.25), fill=ACCENT)
    f_v = font(round(chip * 0.66), "Heavy")
    vb = draw.textbbox((0, 0), LOGO_LETTER, font=f_v)
    draw.text(
        (dev.margin + (chip - vb[2] + vb[0]) / 2 - vb[0], y + (chip - vb[3] - vb[1]) / 2),
        LOGO_LETTER, font=f_v, fill=(255, 255, 255),
    )
    f_word = font(round(chip * 0.71), "Bold")
    wb = draw.textbbox((0, 0), LOGO_WORDMARK, font=f_word)
    draw.text((dev.margin + chip + round(chip * 0.37), y + (chip - wb[3] - wb[1]) / 2), LOGO_WORDMARK, font=f_word, fill=INK)
    return y + chip + round(chip * 0.61)


def fit_headline(draw: ImageDraw.ImageDraw, dev: Device, lines: list[str], max_w: int) -> ImageFont.FreeTypeFont:
    size = dev.head_size
    while size > dev.head_min:
        f = font(size, "Bold")
        if all(draw.textlength(line.lstrip("*"), font=f) <= max_w for line in lines):
            return f
        size -= 6
    return font(dev.head_min, "Bold")


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, max_w: int) -> list[str]:
    words, lines, cur = text.split(), [], ""
    for w_ in words:
        probe = f"{cur} {w_}".strip()
        if draw.textlength(probe, font=f) <= max_w or not cur:
            cur = probe
        else:
            lines.append(cur)
            cur = w_
    if cur:
        lines.append(cur)
    return lines


def compose(dev: Device, slide: Slide, locale: str, src_dir: Path, out_dir: Path) -> Path:
    shot_path = src_dir / slide.src
    if not shot_path.exists():
        alt = src_dir / f"{slide.num}.png"
        if not alt.exists():
            raise FileNotFoundError(f"{slide.num}: neither {shot_path.name} nor {alt.name} in {src_dir}")
        shot_path = alt
    shot = Image.open(shot_path).convert("RGB")
    if abs(shot.width / shot.height - dev.aspect) > 0.02:
        raise ValueError(f"{shot_path.name}: unexpected aspect {shot.width}x{shot.height} for this device")

    W, H = dev.canvas
    canvas = background(dev, slide).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    y = round(H * 0.045)
    if slide.logo:
        y = draw_logo(draw, dev, y)

    headline, sub = CAPTIONS[locale][slide.num]
    f_head = fit_headline(draw, dev, headline, W - 2 * dev.margin)
    line_h = round(f_head.size * 1.14)
    for line in headline:
        accent = line.startswith("*")
        draw.text((dev.margin, y), line.lstrip("*"), font=f_head, fill=ACCENT if accent else INK)
        y += line_h
    y += round(f_head.size * 0.24)

    f_sub = font(dev.sub_size, "Regular")
    for line in wrap(draw, sub, f_sub, W - 2 * dev.margin):
        draw.text((dev.margin, y), line, font=f_sub, fill=MUTED)
        y += round(f_sub.size * 1.3)

    ratio = 0.36 if slide.layout == "hero" else 0.33
    device_top = max(round(H * ratio), y + round(H * 0.033))
    paste_device(canvas, dev, slide, shot, device_top)

    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{slide.num}-{slide.slug}.png"
    canvas.convert("RGB").save(out, "PNG")
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--locale", default="en", choices=sorted(CAPTIONS))
    ap.add_argument("--device", default="iphone", choices=sorted(DEVICES))
    ap.add_argument("--src", required=True, help="directory with device captures")
    ap.add_argument("--out", default=None, help="output dir (default app_store_screenshots/<locale>/<slot>)")
    ap.add_argument("--slides", default=None, help="comma-separated slide numbers, e.g. 01,03")
    args = ap.parse_args()

    dev = DEVICES[args.device]
    src_dir = Path(args.src).expanduser()
    out_dir = Path(args.out) if args.out else ROOT / "app_store_screenshots" / args.locale / dev.slot
    wanted = set(args.slides.split(",")) if args.slides else None

    for slide in SLIDES:
        if wanted and slide.num not in wanted:
            continue
        out = compose(dev, slide, args.locale, src_dir, out_dir)
        shown = out.relative_to(ROOT) if out.is_relative_to(ROOT) else out
        print(f"✓ {shown}")


if __name__ == "__main__":
    main()
