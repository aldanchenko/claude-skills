# Storefronts and localizations

Every App Store storefront has a default language and a few additional ones. The
storefront shows, and searches, the app's metadata in those languages only. The
full table is Apple's [App Store localizations](https://developer.apple.com/help/app-store-connect/reference/app-store-localizations)
page. Re-read it when planning a new storefront; it changes.

## Storefronts that matter for ru / uk / ro apps (checked 2026-10-28)

| Storefront | Default | Additional |
|---|---|---|
| United States | English (US) | Arabic, Chinese (Simplified), Chinese (Traditional), French, Korean, Portuguese (Brazil), Russian, Spanish (Mexico), Vietnamese |
| Russia | Russian | English (U.K.), Ukrainian |
| Ukraine | English (U.K.) | Russian, Ukrainian |
| Romania | English (U.K.) | Romanian |
| Germany | German | English (U.K.) |
| Poland | English (U.K.) | Polish |
| Canada | English (Canada) | French (Canada) |
| United Kingdom | English (U.K.) | — |
| Moldova, Belarus, Kazakhstan, Georgia, Armenia, Azerbaijan, Uzbekistan, Kyrgyzstan | English (U.K.) | — |

## What follows from it

- Pick the target storefronts first, then fill the localizations each one shows.
  A storefront whose languages the app has no metadata for shows the app's
  primary language.
- **Cross-localization** (reported by ASO vendors such as AppTweak and
  MobileAction; Apple doesn't state it): a storefront indexes the name, subtitle
  and keywords of every localization it supports. The US also searches the ru
  and es-MX fields; Ukraine searches en-GB, ru and uk. That is extra keyword
  space, so:
  - don't repeat a word across localizations of the same storefront
    (`check_metadata.py --storefront US=en-US,ru,es-MX` lists repeats);
  - words from different localizations don't combine into one phrase;
  - an identical keyword field in two localizations adds nothing.
- **Geo terms reach only the storefronts that show that localization.**
  "молдова" in the ru field can rank in Russia, Ukraine and the US, but Moldova
  lists English (U.K.) only, so the ru field is unlikely to be searched there:
  the en-GB localization, or without one the primary language, is. Check ranks
  in the storefront before relying on a geo term.
- For the same reason an en-GB localization decides what the single-language
  English (U.K.) storefronts (Moldova, Kazakhstan, …) show. Decide deliberately,
  especially when the primary language is Russian.
- Which localization a storefront really shows: open
  `https://apps.apple.com/<cc>/app/id<ID>` (`md`, `ua`, `us`, …).
