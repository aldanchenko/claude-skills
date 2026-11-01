# Google Play listing

Play differs from the App Store in what it indexes, so don't port App Store
metadata one to one.

| Field | Limit | Notes |
|---|---|---|
| App name | 30 chars | Strongest signal, same as on iOS |
| Short description | 80 chars | Shown on the listing; indexed |
| Full description | 4,000 chars | Indexed. Use the main queries naturally a few times, no keyword lists |
| Keyword field | — | Doesn't exist |

Limits are the same for every script ("regardless of character type").
[Google: store listing](https://support.google.com/googleplay/android-developer/answer/9859152)

## Metadata policy (rejection risk)

In the title, icon and developer name, Google forbids
([metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842)):

- store performance or rank: "App of the year", "#1", "Best of Play 20XX",
  "Popular";
- price or promotion: "10% off", "free for limited time only";
- hints at Play programs: "Editor's choice", "New";
- emojis, emoticons, repeated special characters; ALL CAPS unless it is the
  brand.

The description must not be a keyword list or carry unattributed user
testimonials.

## Other levers

- Store listing experiments (A/B tests of icon, graphics and texts) and custom
  store listings per country — the Play equivalents of product page tests and
  custom product pages.
- Screenshots and the 1024×500 feature graphic: the `app-store-screenshots`
  skill.
- Metadata layout for fastlane supply:
  `fastlane/metadata/android/<locale>/{title,short_description,full_description}.txt`.
