#!/usr/bin/env python3
"""Check App Store metadata against Apple's limits and the keyword-field rules.

Script from the aso skill. Reads a fastlane-style metadata folder
(<dir>/<locale>/name.txt, subtitle.txt, keywords.txt, promotional_text.txt,
description.txt, release_notes.txt), prints NN/limit for every field and lists
what wastes the 100-character keyword field. Counting is done here, not by eye:
models miscount Cyrillic and decomposed letters.

Usage:
    python3 check_metadata.py fastlane/metadata \
        [--developer "Company Name"] [--category Education] \
        [--storefront US=en-US,ru,es-MX] [--storefront UA=en-GB,ru,uk]

--category defaults to <dir>/primary_category.txt when it exists.
--storefront lists the localizations one storefront shows (see the skill's
references/storefronts.md); words repeated across them are reported.

Exit status 1 when a field is over its limit or the keyword field is malformed.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "release_notes": 4000,
}
# Words that never earn their place in the keyword field.
FILLER = {"app", "apps", "application", "приложение", "приложения", "застосунок", "додаток"}
WORD = re.compile(r"[^\W_]+")
SEPARATORS = re.compile(r"[,，]")  # Apple accepts an English or a Chinese comma


def words(text: str) -> set[str]:
    return {w.casefold() for w in WORD.findall(text)}


def read_locale(path: Path) -> dict[str, str]:
    fields = {}
    for field in LIMITS:
        f = path / f"{field}.txt"
        if f.exists():
            fields[field] = f.read_text(encoding="utf-8").strip()
    return fields


def plural_pairs(ws: set[str]) -> list[str]:
    pairs = []
    for w in sorted(ws):
        for plural in (w + "s", w + "es", w[:-1] + "ies" if w.endswith("y") else None):
            if plural and plural in ws:
                pairs.append(f"{w}/{plural}")
    return pairs


def check_locale(locale: str, fields: dict[str, str], taken: set[str]) -> tuple[list[str], list[str]]:
    errors, warnings = [], []
    print(f"\n{locale}")
    for field, limit in LIMITS.items():
        if field not in fields:
            continue
        raw = fields[field]
        text = unicodedata.normalize("NFC", raw)
        if text != raw:
            warnings.append(f"{field}: not NFC; decomposed letters (й, ё, ă) count twice. Normalize before pasting")
        n = len(text)
        shown = text if field in ("name", "subtitle", "keywords") else text[:60] + ("…" if n > 60 else "")
        print(f"  {field:<17}{n:>5}/{limit:<5} {shown}")
        if n > limit:
            errors.append(f"{field}: {n}/{limit}, {n - limit} over the limit")
    for field in ("name", "subtitle", "keywords"):
        if field not in fields:
            warnings.append(f"{field}: missing")

    kw = unicodedata.normalize("NFC", fields.get("keywords", ""))
    if not kw:
        return errors, warnings
    if re.search(r"[,，] | [,，]", kw):
        errors.append("keywords: spaces around commas waste characters")
    if re.search(r"[;|]", kw):
        errors.append("keywords: separate with commas only, not ; or |")
    terms = [t.strip() for t in SEPARATORS.split(kw)]
    if any(not t for t in terms):
        errors.append("keywords: empty term (double, leading or trailing comma)")
    terms = [t for t in terms if t]
    short = [t for t in terms if len(t) <= 2]
    if short:
        warnings.append(f"keywords: terms of two characters or fewer: {', '.join(short)}")
    seen, dupes = set(), set()
    for t in (t.casefold() for t in terms):
        (dupes if t in seen else seen).add(t)
    if dupes:
        warnings.append(f"keywords: duplicate terms: {', '.join(sorted(dupes))}")

    kw_words = [w.casefold() for t in dict.fromkeys(t.casefold() for t in terms) for w in WORD.findall(t)]
    repeated = sorted({w for w in kw_words if kw_words.count(w) > 1})
    if repeated:
        warnings.append(f"keywords: word repeated across terms (Apple combines single words): {', '.join(repeated)}")
    already = sorted(set(kw_words) & taken)
    if already:
        warnings.append(f"keywords: already indexed via name/subtitle/developer/category: {', '.join(already)}")
    filler = sorted(set(kw_words) & FILLER)
    if filler:
        warnings.append(f"keywords: filler words: {', '.join(filler)}")
    if locale.lower().startswith("en"):
        pairs = plural_pairs(set(kw_words) | taken)
        if pairs:
            warnings.append(f"keywords: singular and plural both present, keep the singular: {', '.join(pairs)}")
    free = LIMITS["keywords"] - len(kw)
    if free > 10:
        warnings.append(f"keywords: {free} characters unused")
    return errors, warnings


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("metadata", type=Path, help="fastlane-style metadata folder")
    ap.add_argument("--developer", default="", help="seller / developer name shown on the App Store")
    ap.add_argument("--category", default=None, help="primary category, e.g. Education")
    ap.add_argument("--storefront", action="append", default=[], metavar="CC=loc,loc",
                    help="localizations one storefront shows, e.g. US=en-US,ru,es-MX")
    args = ap.parse_args()

    if not args.metadata.is_dir():
        print(f"no such folder: {args.metadata}", file=sys.stderr)
        return 2
    category = args.category
    if category is None and (args.metadata / "primary_category.txt").exists():
        category = (args.metadata / "primary_category.txt").read_text(encoding="utf-8").replace("MZGenre.", "")
    common = words(args.developer) | words(category or "")

    locales = {
        p.name: read_locale(p)
        for p in sorted(args.metadata.iterdir())
        if p.is_dir() and any((p / f"{f}.txt").exists() for f in ("name", "subtitle", "keywords"))
    }
    if not locales:
        print(f"no locale folders with name/subtitle/keywords.txt in {args.metadata}", file=sys.stderr)
        return 2

    problems: dict[str, tuple[list[str], list[str]]] = {}
    for locale, fields in locales.items():
        taken = words(fields.get("name", "")) | words(fields.get("subtitle", "")) | common
        problems[locale] = check_locale(locale, fields, taken)

    # Identical keyword fields: every localization a storefront shows is indexed there,
    # so a copied field adds nothing.
    by_kw: dict[str, list[str]] = {}
    for locale, fields in locales.items():
        if fields.get("keywords"):
            by_kw.setdefault(fields["keywords"].casefold(), []).append(locale)
    shared = [" = ".join(ls) for ls in by_kw.values() if len(ls) > 1]

    cross = []
    for spec in args.storefront:
        code, _, locs = spec.partition("=")
        locs = [l.strip() for l in locs.split(",") if l.strip()]
        missing = [l for l in locs if l not in locales]
        if missing:
            cross.append(f"{code}: no metadata for {', '.join(missing)}; that keyword space in {code} is unused")
        present = [l for l in locs if l in locales]
        for l in present:
            mine = {w.casefold() for t in SEPARATORS.split(locales[l].get("keywords", "")) for w in WORD.findall(t)}
            others = set()
            for o in present:
                if o != l:
                    f = locales[o]
                    others |= words(f.get("name", "")) | words(f.get("subtitle", "")) | words(f.get("keywords", ""))
            dup = sorted(mine & others)
            if dup:
                cross.append(f"{code}: {l} keywords repeat words from other localizations of this storefront: {', '.join(dup)}")

    print()
    errors = 0
    for locale, (errs, warns) in problems.items():
        for e in errs:
            print(f"ERROR {locale} {e}")
        for w in warns:
            print(f"warn  {locale} {w}")
        errors += len(errs)
    for s in shared:
        print(f"warn  identical keyword fields: {s}")
    for c in cross:
        print(f"warn  storefront {c}")
    if not errors and not any(w for _, w in problems.values()) and not shared and not cross:
        print("clean")
    heavy = [l for l, f in locales.items() if len(f.get("keywords", "").encode("utf-8")) > LIMITS["keywords"]]
    if heavy:
        print(f"\nnote: keywords of {', '.join(heavy)} exceed 100 UTF-8 bytes. Fine: App Store Connect counts"
              " characters, though its reference still says bytes. Only if an upload is rejected for length is this why.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
