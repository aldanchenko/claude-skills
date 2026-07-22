---
name: aso
description: Audit and improve App Store Optimization — name/subtitle/keywords per storefront locale with hard character limits, promoted in-app purchases, conversion copy. Use when the user mentions ASO, keywords, subtitle, метаданные App Store, поисковую выдачу, or wants more installs from search.
---

# ASO audit & metadata

Improve App Store search visibility (indexed metadata) and conversion (everything
else). Always work per storefront locale — every language the app ships deserves
its own metadata set; localized metadata + localized screenshots convert far
better than English-everywhere.

## What search actually indexes

| Field | Limit | Notes |
|---|---|---|
| Name | 30 chars | Strongest signal. Put the #1 keyword here: `Brand: главный запрос` |
| Subtitle | 30 chars | Second strongest. Complementary keywords, human-readable |
| Keywords | 100 chars | Comma-separated, NO spaces after commas |
| Promoted IAP | name 30 / desc 45 | Shows as its own search result card — free extra slot |

NOT indexed (conversion only): description, promotional text, what's new,
screenshots. Don't burn effort putting keywords there for ranking.

## Hard rules for the keyword field

- Never repeat a word already in Name or Subtitle — it's already indexed; a
  repeat burns limit for zero gain.
- Singular is enough; Apple matches plural forms.
- No competitor app names (rejection risk), no category name ("app", "игра").
- Verify EVERY proposed string with an exact character count and show it as
  `21/30` next to the text. Cyrillic counts per character, same as Latin.
- For ru/uk include morphology variants that Apple matches poorly
  (выучить/учить), geo terms the audience actually types (молдова, румыния).

## Conversion levers (not indexed, still matter)

- **Promotional text** (170 chars) — editable WITHOUT a release; keep current
  update highlights here.
- **Description** — only the first ~3 lines show before "more"; lead with who
  the app is for, not a feature list.
- **Screenshots** — order = story; first 3 dominate search cards. For building
  the sets themselves use the `app-store-screenshots` skill.
- **Ratings** — make sure an in-app review prompt exists (e.g. in_app_review).
- **Categories** — primary + secondary both set.

## Release coupling

Name, Subtitle and Keywords can only change together with a new app version —
bundle metadata changes with the next release. Promotional text, promoted-IAP
promo image and description edits go live anytime.

## Workflow

1. Collect current state: ASC name/subtitle/keywords per locale (ask the user or
   read repo docs/fastlane metadata), supported UI languages, target audience.
2. Identify the #1 search query per locale (what the audience literally types).
3. Propose a per-locale table: Name / Subtitle / Keywords, each with `NN/limit`
   counts, keywords deduplicated against name+subtitle.
4. Add promotional text draft and description opening lines.
5. Flag anything requiring a release vs instantly editable.
6. Remind about promoted IAP setup if the app has one.
