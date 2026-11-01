# Conversion surfaces beyond the default product page

All three are reviewed but need no new app version. Facts from Apple's pages,
checked 2026-10-28.

## Custom product pages

- Up to 70 extra versions of the product page (screenshots, previews,
  promotional text), each with its own URL — for ads, links and campaigns.
- Keywords can be assigned to a page: it then appears in search for those
  keywords instead of the default page. Match the page's intent; each keyword
  combination belongs to one page only.
- Use them when the app serves clearly different audiences (a learner of
  Romanian vs a traveller) — each page tells one story.

[Apple: custom product pages](https://developer.apple.com/app-store/custom-product-pages/)

## Product page optimization (A/B tests)

- Up to 3 treatments against the default page: icon, screenshots, app previews.
- Runs up to 90 days, or until stopped. Each treatment can cover all
  localizations or chosen ones; fewer localizations means slower results.
- Alternate icons must already be in the live binary; tests without icon changes
  are submitted on their own.
- Test the first screenshot first — it carries the search card. Change one idea
  per treatment so the result means something.

[Apple: product page optimization](https://developer.apple.com/app-store/product-page-optimization/)

## In-app events

- Name 30 characters (title case), short description 50, long description 120
  (sentence case). Specific prices in the text lead to rejection.
- Up to 10 published at a time (15 approved in App Store Connect); each lasts up
  to 31 days and can be promoted up to 14 days before it starts.
- Event cards appear in search results for people who have the app, and events
  can be searched directly — a timely way to reach a seasonal query.

[Apple: in-app events](https://developer.apple.com/app-store/in-app-events/)

## Ratings and reviews

- The system prompt (SKStoreReviewController; Flutter `in_app_review`) shows at
  most 3 times in 365 days. Ask right after a success moment (lesson finished,
  goal reached), never mid-task, and never behind a custom "Do you like the
  app?" dialog: App Review Guideline 5.6.1 allows only the system prompt.
- A permanent "Rate the app" row in settings can open
  `https://apps.apple.com/app/id<ID>?action=write-review`.
- The summary rating is per territory and can be reset with a new version — use
  it sparingly; written reviews stay.
- Reply to reviews; read them for the words users use (keyword research).

[Apple: ratings and reviews](https://developer.apple.com/app-store/ratings-and-reviews/)
