#!/usr/bin/env python3
"""Compose localized App Store and Google Play screenshots from clean device captures.

Template from the app-store-screenshots skill. Copy into the project (e.g.
tools/generate_app_store_screenshots.py) and fill the PROJECT CONFIG block.
The device screen is a real, untouched capture — UI text can never be
mangled — and captions are font-rendered from per-locale string tables.

Usage:
    python3 generate_app_store_screenshots.py --locale en --src captures/en/iphone-6.3
    python3 generate_app_store_screenshots.py --locale ru --device ipad-13 --src <dir>
    python3 generate_app_store_screenshots.py --all --sheet --src captures
    python3 generate_app_store_screenshots.py --locale en --feature-graphic
Options: --all (every locale in CAPTIONS x BUILD_DEVICES, captures read from
<src>/<locale>/<device>/), --sheet (review sheet per set), --variant b (A/B
captions "01@b"), --fastlane (mirror into fastlane's upload folders),
--slides 01,03.

Inputs: portrait captures named per SLIDES[].src or 01.png … NN.png:
    iphone-6.3: 1206x2622 / 1179x2556 (iPhone 17 / 16 Pro simulators)
    iphone-6.9: 1320x2868 / 1290x2796 / 1260x2736 (any ~19.5:9 portrait)
    ipad-13:    2064x2752 / 2048x2732 (any ~3:4 portrait)
    android:    1080x2400 (`adb exec-out screencap -p`, Pixel-class emulator)
Output: app_store_screenshots/<locale>/<slot>/NN-slug.png, checked against the
sizes and counts the store accepts. A caption that doesn't fit, a device over
the caption, a missing glyph or caption, or low contrast stops the run with the
locale and slide named.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, features

ROOT = Path(__file__).resolve().parents[1]

# ============================== PROJECT CONFIG ==============================
# TODO: brand these for the app.
ACCENT = (0, 137, 123)          # punch-line color + logo chip
LOGO_LETTER = "A"               # letter inside the logo chip on slide 01
LOGO_WORDMARK = "AppName"       # wordmark next to the chip on slide 01

# Canvas palettes. A slide picks one with `theme`; "dark" suits the dark-mode
# slide. bezel is the device frame, lighter on dark so the frame stays visible.
THEMES = {
    "light": dict(bg=(247, 244, 239), blob=(213, 232, 226), ink=(18, 24, 28), muted=(88, 98, 104), bezel=(24, 24, 26)),
    "dark": dict(bg=(20, 24, 27), blob=(28, 52, 50), ink=(242, 244, 245), muted=(160, 168, 172), bezel=(66, 68, 72)),
}


@dataclass
class Slide:
    num: str
    slug: str
    src: str                    # default capture filename in --src (NN.png works too)
    layout: str = "hero"        # hero = large, bottom-cropped; float = whole device
    lean: float = -5.0          # degrees; negative leans the top to the left
    blob: str = "right"         # which side gets the big soft wash
    logo: bool = False          # slide 01 carries the logo chip + wordmark
    theme: str = "light"        # key of THEMES
    head_scale: float = 1.0     # below 1 for one headline much longer than the rest


# TODO: define the slide set. Proven 7-slide arc: home/progress (logo) → content
# depth → interactive w/ feedback (float) → catalog → differentiator (float) →
# retention/mistakes → dark mode. Alternate lean sign for variety.
SLIDES = [
    Slide("01", "home", "01.png", logo=True, lean=-5.0, blob="left"),
    Slide("02", "feature-two", "02.png", lean=4.5, blob="right"),
    Slide("03", "feature-three", "03.png", layout="float", lean=-4.0, blob="right"),
    # ...
    # Slide("07", "dark-mode", "07.png", lean=4.5, theme="dark"),
]

# Headline lines prefixed with "*" render in ACCENT; the rest render ink.
# TODO: fill every locale you ship. Benefit-first, short; the punch line gets "*".
# A key like "01@b" is an A/B variant of slide 01 for product page tests
# (--variant b); slides without one keep their base caption.
CAPTIONS: dict[str, dict[str, tuple[list[str], str]]] = {
    "en": {
        "01": (["Big Benefit.", "*Punch Line."], "One-line supporting subtitle."),
        "02": (["Second", "*Feature"], "Why it matters."),
        "03": (["Third", "*Feature"], "Why it matters."),
    },
}

# Google Play feature graphic (1024x500, no device): the name's keyword tail and
# what the app is. Keep it equal to the live listing so the two can't drift.
FEATURE: dict[str, tuple[str, str]] = {
    "en": ("Big Benefit", "What the app is, in a few words"),
}

# Locales whose script SF Pro lacks get their own font: (path, ttc index).
# A missing glyph stops the run, so you find out here, not in the store.
LOCALE_FONTS: dict[str, tuple[str, int]] = {
    # "zh-Hans": ("/System/Library/Fonts/Hiragino Sans GB.ttc", 0),
    # "ko": ("/System/Library/Fonts/AppleSDGothicNeo.ttc", 0),
    # "ar": ("/System/Library/Fonts/GeezaPro.ttc", 0),  # RTL: needs Pillow built with raqm
}

# Store locale codes for --fastlane.
ASC_LOCALES = {"en": "en-US"}
PLAY_LOCALES = {"en": "en-US"}

# Device sets --all builds for every locale.
BUILD_DEVICES = ["iphone-6.3", "ipad-13"]
# ============================ END PROJECT CONFIG ============================


@dataclass(frozen=True)
class Device:
    canvas: tuple[int, int]
    slot: str                   # output subdirectory, mirrors the store slot
    aspect: float               # expected capture aspect (w/h)
    hero_w: int                 # screen width when the device bleeds off the bottom
    float_w: int                # screen width when the whole device stays visible
    head_size: int
    head_min: int
    sub_size: int
    margin: int
    chip: int                   # logo chip side on slide 01
    cutout: str                 # "island" (iPhone), "punch" (Android), "none" (iPad)
    bez_scale: float            # bezel thickness as a fraction of the screen width
    r_scale: float              # screen corner radius, same fraction
    accepted: tuple[tuple[int, int], ...]  # portrait sizes the store takes; () = Play's rule
    max_count: int              # screenshots the store takes per slot
    min_count: int = 1


DEVICES = {
    # The size Apple requires ("iPhone with Dynamic Island, medium display").
    "iphone-6.3": Device(
        canvas=(1206, 2622), slot="iphone-6.3", aspect=1206 / 2622,
        hero_w=932, float_w=822, head_size=137, head_min=88, sub_size=57,
        margin=88, chip=108, cutout="island", bez_scale=26 / 1064, r_scale=165 / 1290,
        accepted=((1206, 2622), (1179, 2556)), max_count=10,
    ),
    "iphone-6.9": Device(
        canvas=(1320, 2868), slot="iphone-6.9", aspect=1290 / 2796,
        hero_w=1020, float_w=900, head_size=150, head_min=96, sub_size=62,
        margin=96, chip=118, cutout="island", bez_scale=26 / 1064, r_scale=165 / 1290,
        accepted=((1320, 2868), (1290, 2796), (1260, 2736)), max_count=10,
    ),
    "ipad-13": Device(
        canvas=(2064, 2752), slot="ipad-13", aspect=3 / 4,
        hero_w=1500, float_w=1280, head_size=190, head_min=120, sub_size=80,
        margin=130, chip=150, cutout="none", bez_scale=72 / 2064, r_scale=84 / 2064,
        accepted=((2064, 2752), (2048, 2732)), max_count=10,
    ),
    # Play recommends only 9:16 portrait screenshots (at least 4, 1080x1920 or
    # more), so the canvas is wider and shorter than the iPhone one and every
    # size below is re-fitted to it, not scaled. min_count: Play needs 2 across
    # device types; most apps ship phone screenshots only.
    "android": Device(
        canvas=(1440, 2560), slot="play-phone", aspect=1080 / 2400,
        # float_w is small on purpose: a whole 19.5:9 phone is 2.27x its own
        # width, and on this shorter canvas anything wider than ~800 doesn't
        # fit under the caption.
        hero_w=1060, float_w=760, head_size=132, head_min=88, sub_size=58,
        margin=104, chip=112, cutout="punch", bez_scale=0.022, r_scale=0.085,
        accepted=(), max_count=8, min_count=2,
    ),
}

_SFNS = "/System/Library/Fonts/SFNS.ttf"
_ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
_ARIAL = "/System/Library/Fonts/Supplemental/Arial.ttf"
_RTL = {"ar", "he", "fa", "ur"}
_CHAR_WRAP = {"ja", "zh"}       # scripts without spaces between words


class LayoutError(Exception):
    pass


def lang(locale: str) -> str:
    return locale.split("-")[0].split("_")[0]


def font(size: int, weight: str = "Bold", locale: str = "") -> ImageFont.FreeTypeFont:
    """San Francisco (variable) with an Arial fallback; LOCALE_FONTS override it."""
    if locale in LOCALE_FONTS:
        path, index = LOCALE_FONTS[locale]
        return ImageFont.truetype(path, size, index=index)
    try:
        f = ImageFont.truetype(_SFNS, size)
        f.set_variation_by_name(weight)
        return f
    except Exception:
        return ImageFont.truetype(
            _ARIAL_BOLD if weight in ("Bold", "Heavy", "Semibold") else _ARIAL, size
        )


def check_glyphs(f: ImageFont.FreeTypeFont, text: str, where: str) -> None:
    """A glyph the font lacks renders as the .notdef box; compare against it."""
    def sig(ch: str) -> tuple:
        m = f.getmask(ch)
        return m.size, bytes(m)
    notdef = sig("")
    missing = sorted({ch for ch in text if not ch.isspace() and sig(ch) == notdef})
    if missing:
        raise LayoutError(f"{where}: the font has no glyph for {' '.join(missing)}; add the locale to LOCALE_FONTS")


def luminance(rgb: tuple[int, int, int]) -> float:
    def ch(c: int) -> float:
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def check_themes(names: set[str]) -> list[str]:
    """WCAG: 4.5:1 for body text, 3:1 for the large accent headline line."""
    problems = []
    for name in sorted(names):
        if name not in THEMES:
            problems.append(f"theme {name!r} is not in THEMES")
            continue
        t = THEMES[name]
        for bg in ("bg", "blob"):
            for fg, need in (("ink", 4.5), ("muted", 4.5)):
                if (c := contrast(t[fg], t[bg])) < need:
                    problems.append(f"theme {name}: {fg} on {bg} is {c:.1f}:1, needs {need}:1")
            if (c := contrast(ACCENT, t[bg])) < 3:
                problems.append(f"theme {name}: ACCENT on {bg} is {c:.1f}:1, needs 3:1")
    return problems


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return mask


def background(dev: Device, slide: Slide, theme: dict) -> Image.Image:
    w, h = dev.canvas
    img = Image.new("RGB", (w, h), theme["bg"])
    draw = ImageDraw.Draw(img)
    if slide.blob == "right":
        draw.ellipse((w * 0.58, h * 0.24, w * 1.32, h * 0.60), fill=theme["blob"])
        draw.ellipse((-w * 0.29, h * 0.66, w * 0.32, h * 0.98), fill=theme["blob"])
    else:
        draw.ellipse((-w * 0.32, h * 0.26, w * 0.36, h * 0.61), fill=theme["blob"])
        draw.ellipse((w * 0.65, h * 0.68, w * 1.29, h * 0.98), fill=theme["blob"])
    # Soften the washes so they read as light, not shapes.
    return img.filter(ImageFilter.GaussianBlur(round(42 * w / 1320)))


def device_layer(dev: Device, shot: Image.Image, screen_w: int, bezel: tuple[int, int, int]) -> Image.Image:
    """Device mockup: bezel, rounded screen, and the camera cutout the real
    device has — a Dynamic Island on iPhone, a punch-hole on Android."""
    s = screen_w / shot.width
    screen_h = round(shot.height * s)
    shot = shot.resize((screen_w, screen_h), Image.LANCZOS)

    bez = max(2, round(dev.bez_scale * screen_w))
    r_screen = round(dev.r_scale * screen_w)
    dev_w, dev_h = screen_w + 2 * bez, screen_h + 2 * bez

    layer = Image.new("RGBA", (dev_w, dev_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((0, 0, dev_w - 1, dev_h - 1), r_screen + bez, fill=bezel + (255,))

    layer.paste(shot, (bez, bez), rounded_mask((screen_w, screen_h), r_screen))

    # Captures don't include the cutout, so draw it (it also cleanly covers
    # the island a simulator capture may contain).
    if dev.cutout == "island":
        iw, ih = round(316 * screen_w / 1290), round(95 * screen_w / 1290)
        ix, iy = bez + (screen_w - iw) // 2, bez + round(30 * screen_w / 1290)
        draw.rounded_rectangle((ix, iy, ix + iw, iy + ih), ih // 2, fill=(8, 8, 10, 255))
    elif dev.cutout == "punch":
        d = round(34 * screen_w / 1080)
        cx, cy = bez + screen_w // 2, bez + round(38 * screen_w / 1080)
        draw.ellipse((cx - d // 2, cy - d // 2, cx + d // 2, cy + d // 2), fill=(8, 8, 10, 255))
    return layer


def paste_device(canvas: Image.Image, dev: Device, slide: Slide, shot: Image.Image, top: int,
                 caption_bottom: int, bezel: tuple[int, int, int], where: str) -> None:
    W, H = dev.canvas
    screen_w = dev.hero_w if slide.layout == "hero" else dev.float_w
    layer = device_layer(dev, shot, screen_w, bezel)

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
    if y < caption_bottom + 16:
        raise LayoutError(f"{where}: the device would cover the caption (device top {y}px, caption ends "
                          f"{caption_bottom}px); lower float_w for this device or shorten the caption")

    shadow_alpha = rot.split()[3].point(lambda a: a * 45 // 100)
    shadow = Image.new("RGBA", rot.size, (10, 14, 16, 0))
    shadow.putalpha(shadow_alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(44))
    canvas.alpha_composite(shadow, (x, y + 38))
    canvas.alpha_composite(rot, (x, y))


def text_x(draw: ImageDraw.ImageDraw, W: int, margin: int, text: str, f: ImageFont.FreeTypeFont, locale: str) -> float:
    """Left-aligned, or right-aligned for right-to-left scripts."""
    if lang(locale) in _RTL:
        return W - margin - draw.textlength(text, font=f, direction="rtl")
    return margin


def draw_text(draw: ImageDraw.ImageDraw, xy: tuple[float, float], text: str, f, fill, locale: str) -> None:
    kw = {"direction": "rtl"} if lang(locale) in _RTL else {}
    draw.text(xy, text, font=f, fill=fill, **kw)


def draw_logo(draw: ImageDraw.ImageDraw, x: int, y: int, chip: int, word_size: int, ink) -> int:
    draw.rounded_rectangle((x, y, x + chip, y + chip), round(chip * 0.25), fill=ACCENT)
    f_v = font(round(chip * 0.66), "Heavy")
    vb = draw.textbbox((0, 0), LOGO_LETTER, font=f_v)
    draw.text(
        (x + (chip - vb[2] + vb[0]) / 2 - vb[0], y + (chip - vb[3] - vb[1]) / 2),
        LOGO_LETTER, font=f_v, fill=(255, 255, 255),
    )
    f_word = font(word_size, "Bold")
    wb = draw.textbbox((0, 0), LOGO_WORDMARK, font=f_word)
    draw.text((x + chip + round(chip * 0.37), y + (chip - wb[3] - wb[1]) / 2), LOGO_WORDMARK, font=f_word, fill=ink)
    return y + chip


def fit_headline(draw: ImageDraw.ImageDraw, dev: Device, slide: Slide, lines: list[str], max_w: int,
                 locale: str, where: str) -> ImageFont.FreeTypeFont:
    kw = {"direction": "rtl"} if lang(locale) in _RTL else {}
    start = round(dev.head_size * slide.head_scale)
    for size in [*range(start, dev.head_min, -6), dev.head_min]:
        f = font(size, "Bold", locale)
        if all(draw.textlength(line.lstrip("*"), font=f, **kw) <= max_w for line in lines):
            return f
    widest = max(lines, key=lambda line: draw.textlength(line.lstrip("*"), font=f, **kw)).lstrip("*")
    raise LayoutError(f"{where}: headline line “{widest}” is {draw.textlength(widest, font=f, **kw):.0f}px at the "
                      f"minimum size, {max_w}px fit; shorten it or move a word to the next line")


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, max_w: int, locale: str) -> list[str]:
    char_wrap = lang(locale) in _CHAR_WRAP
    tokens, glue = (list(text), "") if char_wrap else (text.split(), " ")
    kw = {"direction": "rtl"} if lang(locale) in _RTL else {}
    lines, cur = [], ""
    for tok in tokens:
        probe = f"{cur}{glue}{tok}" if cur else tok
        if draw.textlength(probe, font=f, **kw) <= max_w or not cur:
            cur = probe
        else:
            lines.append(cur)
            cur = tok.lstrip() if char_wrap else tok
    if cur:
        lines.append(cur)
    return lines


def caption_for(locale: str, num: str, variant: str | None) -> tuple[list[str], str]:
    table = CAPTIONS[locale]
    if variant and f"{num}@{variant}" in table:
        return table[f"{num}@{variant}"]
    return table[num]


def compose(dev: Device, slide: Slide, locale: str, src_dir: Path, out_dir: Path, variant: str | None) -> Path:
    where = f"{locale}/{dev.slot}/{slide.num}"
    shot_path = src_dir / slide.src
    if not shot_path.exists():
        alt = src_dir / f"{slide.num}.png"
        if not alt.exists():
            raise LayoutError(f"{where}: neither {shot_path.name} nor {alt.name} in {src_dir}")
        shot_path = alt
    shot = Image.open(shot_path).convert("RGB")
    if abs(shot.width / shot.height - dev.aspect) > 0.02:
        raise LayoutError(f"{where}: {shot_path.name} is {shot.width}x{shot.height}, not a {dev.slot} capture")

    theme = THEMES[slide.theme]
    headline, sub = caption_for(locale, slide.num, variant)
    W, H = dev.canvas
    canvas = background(dev, slide, theme).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    max_w = W - 2 * dev.margin

    y = round(H * 0.045)
    if slide.logo:
        check_glyphs(font(dev.chip, "Bold"), LOGO_LETTER + LOGO_WORDMARK, where)
        y = draw_logo(draw, dev.margin, y, dev.chip, round(dev.chip * 0.71), theme["ink"]) + round(dev.chip * 0.61)

    f_head = fit_headline(draw, dev, slide, headline, max_w, locale, where)
    check_glyphs(f_head, "".join(headline).replace("*", ""), where)
    line_h = round(f_head.size * 1.14)
    for line in headline:
        text = line.lstrip("*")
        fill = ACCENT if line.startswith("*") else theme["ink"]
        draw_text(draw, (text_x(draw, W, dev.margin, text, f_head, locale), y), text, f_head, fill, locale)
        y += line_h
    y += round(f_head.size * 0.24)

    f_sub = font(dev.sub_size, "Regular", locale)
    check_glyphs(f_sub, sub, where)
    sub_lines = wrap(draw, sub, f_sub, max_w, locale)
    if len(sub_lines) > 2:
        raise LayoutError(f"{where}: subtitle wraps to {len(sub_lines)} lines, 2 fit; shorten “{sub}”")
    for line in sub_lines:
        draw_text(draw, (text_x(draw, W, dev.margin, line, f_sub, locale), y), line, f_sub, theme["muted"], locale)
        y += round(f_sub.size * 1.3)

    # The device starts at the same height on every slide unless the caption is
    # taller than its band; then this one device moves down, and the run says so.
    band = round(H * (0.36 if slide.layout == "hero" else 0.33))
    top = max(band, y + round(H * 0.033))
    if top > band:
        print(f"  · {where}: caption taller than the band, the device sits {top - band}px lower on this slide")
    paste_device(canvas, dev, slide, shot, top, y, theme["bezel"], where)

    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{slide.num}-{slide.slug}.png"
    canvas.convert("RGB").save(out, "PNG")
    return out


def feature_graphic(locale: str, out_dir: Path) -> Path:
    """The 1024x500 banner Play shows above the screenshots. The middle of it is
    covered by the play button on some surfaces — so the wordmark sits left and
    nothing important goes near the centre."""
    W, H = 1024, 500
    theme = THEMES["light"]
    img = Image.new("RGB", (W, H), theme["bg"])
    draw = ImageDraw.Draw(img)
    draw.ellipse((W * 0.60, -H * 0.30, W * 1.22, H * 0.86), fill=theme["blob"])
    draw.ellipse((W * 0.72, H * 0.52, W * 1.16, H * 1.40), fill=theme["blob"])
    img = img.filter(ImageFilter.GaussianBlur(26))
    draw = ImageDraw.Draw(img)

    where = f"{locale}/feature-graphic"
    if locale not in FEATURE:
        raise LayoutError(f"{where}: no FEATURE entry for {locale}")
    m = 64
    draw_logo(draw, m, 76, 96, 72, theme["ink"])
    title, sub = FEATURE[locale]
    for text, size, floor, weight, fill, top in ((title, 64, 40, "Bold", ACCENT, 232), (sub, 34, 22, "Regular", theme["muted"], 325)):
        f = font(size, weight, locale)
        while draw.textlength(text, font=f) > W - 2 * m and f.size > floor:
            f = font(f.size - 2, weight, locale)
        if draw.textlength(text, font=f) > W - 2 * m:
            raise LayoutError(f"{where}: “{text}” doesn't fit even at {floor}px; shorten it")
        check_glyphs(f, text, where)
        draw_text(draw, (text_x(draw, W, m, text, f, locale), top), text, f, fill, locale)

    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / "feature-graphic-1024x500.png"
    img.save(out, "PNG")
    return out


def validate_set(dev: Device, out_dir: Path, expected: list[str]) -> tuple[list[str], list[str]]:
    """What App Store Connect / Play Console would reject (errors), and what
    keeps a Play set out of recommendations (warnings), checked before upload."""
    problems, notes = [], []
    files = sorted(out_dir.glob("*.png"))
    names = [f.name for f in files]
    for extra in sorted(set(names) - set(expected)):
        problems.append(f"{out_dir}: {extra} is not in SLIDES (left from an older run?)")
    if [n for n in names if n in expected] != expected:
        problems.append(f"{out_dir}: files don't sort in slide order")
    if not dev.min_count <= len(files) <= dev.max_count:
        problems.append(f"{out_dir}: {len(files)} screenshots, the store takes {dev.min_count}–{dev.max_count}")
    for f in files:
        with Image.open(f) as im:
            w, h = im.size
            if im.mode != "RGB":
                problems.append(f"{f}: mode {im.mode}; the store wants RGB without alpha")
        if dev.accepted:
            if (w, h) not in dev.accepted:
                problems.append(f"{f}: {w}x{h} is not an accepted {dev.slot} size {dev.accepted}")
        elif not (320 <= min(w, h) and max(w, h) <= 3840 and max(w, h) <= 2 * min(w, h)):
            problems.append(f"{f}: {w}x{h} breaks Play's rule (320–3840 px, long side at most twice the short)")
        elif abs(w * 16 - h * 9) > 16 or w < 1080:
            notes.append(f"{f}: {w}x{h} is not 9:16 at 1080x1920 or more; Play won't use it in recommendations")
    if not dev.accepted and len(files) < 4:
        notes.append(f"{out_dir}: {len(files)} screenshots; Play recommendations need at least 4")
    return problems, notes


def review_sheet(paths: list[Path], out: Path) -> Path:
    """All slides in a row, plus a row at App Store search-result size (~160 px
    wide): if a headline can't be read there, it won't be read in search."""
    big_h, thumb_w, pad = 1000, 160, 40
    shots = [Image.open(p).convert("RGB") for p in paths]
    big = [s.resize((round(s.width * big_h / s.height), big_h), Image.LANCZOS) for s in shots]
    thumbs = [s.resize((thumb_w, round(s.height * thumb_w / s.width)), Image.LANCZOS) for s in shots]
    width = max(sum(b.width for b in big), sum(t.width for t in thumbs)) + pad * (len(shots) + 1)
    height = pad * 3 + big_h + max(t.height for t in thumbs)
    sheet = Image.new("RGB", (width, height), (255, 255, 255))
    x = pad
    for b in big:
        sheet.paste(b, (x, pad))
        x += b.width + pad
    x = pad
    for t in thumbs:
        sheet.paste(t, (x, pad * 2 + big_h))
        x += t.width + pad
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, "PNG")
    return out


def mirror_to_fastlane(dev: Device, locale: str, paths: list[Path]) -> list[str]:
    """fastlane deliver reads fastlane/screenshots/<code>/, supply reads
    fastlane/metadata/android/<code>/images/. Nothing is uploaded here."""
    problems = []
    if dev.slot == "play-phone":
        if locale not in PLAY_LOCALES:
            return [f"--fastlane: add {locale} to PLAY_LOCALES"]
        target = ROOT / "fastlane/metadata/android" / PLAY_LOCALES[locale] / "images/phoneScreenshots"
        names = [p.name.replace("-", "_", 1) for p in paths]
    else:
        if locale not in ASC_LOCALES:
            return [f"--fastlane: add {locale} to ASC_LOCALES"]
        target = ROOT / "fastlane/screenshots" / ASC_LOCALES[locale]
        names = [f"{dev.slot}-{p.name}" for p in paths]
    target.mkdir(parents=True, exist_ok=True)
    for p, n in zip(paths, names):
        shutil.copyfile(p, target / n)
    ours = set(names)
    prefix = "" if dev.slot == "play-phone" else f"{dev.slot}-"
    for stale in sorted(f.name for f in target.glob(f"{prefix}*.png") if f.name not in ours):
        problems.append(f"{target}/{stale}: not part of this set; it would be uploaded too")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--locale", default="en", choices=sorted(CAPTIONS))
    ap.add_argument("--device", default="iphone-6.3", choices=sorted(DEVICES))
    ap.add_argument("--src", help="captures: a folder of NN.png, or with --all a root of <locale>/<device>/")
    ap.add_argument("--out", help="output dir (default app_store_screenshots/<locale>/<slot>)")
    ap.add_argument("--slides", help="comma-separated slide numbers, e.g. 01,03")
    ap.add_argument("--all", action="store_true", help="every locale in CAPTIONS x BUILD_DEVICES")
    ap.add_argument("--variant", help="A/B caption variant: CAPTIONS keys like 01@b")
    ap.add_argument("--sheet", action="store_true", help="also write a review sheet per set into app_store_screenshots/_review/")
    ap.add_argument("--feature-graphic", action="store_true", help="draw Google Play's 1024x500 banner instead")
    ap.add_argument("--fastlane", action="store_true", help="also copy the result into fastlane's upload folders")
    args = ap.parse_args()

    locales = sorted(CAPTIONS) if args.all else [args.locale]
    errors: list[str] = []
    if any(lang(l) in _RTL for l in locales) and not features.check("raqm"):
        errors.append("right-to-left locale, but this Pillow lacks raqm: brew install libraqm, then "
                      "pip install --force-reinstall --no-binary Pillow Pillow")

    if args.feature_graphic:
        for loc in locales:
            try:
                out = feature_graphic(loc, Path(args.out) if args.out else ROOT / "app_store_screenshots" / loc / "play-feature")
                print(f"✓ {out.relative_to(ROOT) if out.is_relative_to(ROOT) else out}")
                if args.fastlane:
                    if loc not in PLAY_LOCALES:
                        errors.append(f"--fastlane: add {loc} to PLAY_LOCALES")
                    else:
                        target = ROOT / "fastlane/metadata/android" / PLAY_LOCALES[loc] / "images"
                        target.mkdir(parents=True, exist_ok=True)
                        shutil.copyfile(out, target / "featureGraphic.png")
            except LayoutError as e:
                errors.append(str(e))
        for e in errors:
            print(f"✗ {e}", file=sys.stderr)
        return 1 if errors else 0

    if not args.src:
        ap.error("--src is required unless --feature-graphic is given")
    if args.all and args.out:
        ap.error("--out can't be combined with --all")
    wanted = set(args.slides.split(",")) if args.slides else None
    slides = [s for s in SLIDES if not wanted or s.num in wanted]
    devices = BUILD_DEVICES if args.all else [args.device]

    errors += check_themes({s.theme for s in slides})
    for loc in locales:
        missing = [s.num for s in slides if s.num not in CAPTIONS[loc]]
        if missing:
            errors.append(f"{loc}: no caption for slide {', '.join(missing)}")
    src = Path(args.src).expanduser()
    jobs = []
    for loc in locales:
        for key in devices:
            src_dir = src / loc / key if args.all else src
            if not src_dir.is_dir():
                errors.append(f"{loc}/{key}: no captures folder {src_dir}")
            suffix = f"@{args.variant}" if args.variant else ""
            out_dir = Path(args.out) if args.out else ROOT / "app_store_screenshots" / loc / f"{DEVICES[key].slot}{suffix}"
            jobs.append((loc, key, src_dir, out_dir))
    if errors:
        for e in errors:
            print(f"✗ {e}", file=sys.stderr)
        return 1

    warnings: list[str] = []
    for loc, key, src_dir, out_dir in jobs:
        dev = DEVICES[key]
        done = []
        for slide in slides:
            try:
                out = compose(dev, slide, loc, src_dir, out_dir, args.variant)
                done.append(out)
                print(f"✓ {out.relative_to(ROOT) if out.is_relative_to(ROOT) else out}")
            except LayoutError as e:
                errors.append(str(e))
        if not wanted and len(done) == len(slides):
            problems, notes = validate_set(dev, out_dir, [f"{s.num}-{s.slug}.png" for s in slides])
            errors += problems
            warnings += notes
        if args.sheet and done:
            name = f"{loc}-{dev.slot}{'@' + args.variant if args.variant else ''}.png"
            print(f"▦ {review_sheet(done, ROOT / 'app_store_screenshots' / '_review' / name).relative_to(ROOT)}")
        if args.fastlane and done and not errors:
            warnings += mirror_to_fastlane(dev, loc, done)

    # Captures that are byte-identical across locales mean the locale switch failed.
    if args.all and len(locales) > 1:
        for key in devices:
            for slide in slides:
                seen: dict[str, str] = {}
                for loc in locales:
                    p = src / loc / key / slide.src
                    p = p if p.exists() else src / loc / key / f"{slide.num}.png"
                    if p.exists():
                        digest = hashlib.sha256(p.read_bytes()).hexdigest()
                        if digest in seen:
                            warnings.append(f"{key}/{slide.num}: {seen[digest]} and {loc} captures are identical; "
                                            "did the locale switch fail?")
                        seen.setdefault(digest, loc)

    for w in warnings:
        print(f"! {w}", file=sys.stderr)
    for e in errors:
        print(f"✗ {e}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
