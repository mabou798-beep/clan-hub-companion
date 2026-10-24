# Clan Hub — Publishing handover

Unofficial companion app for Clash of Clans (Supercell). Free, ads only, no IAP.
Project folder: Desktop\clan-hub-companion

## Key values (approved 2026-10-24)

| Field | Value |
|---|---|
| Game / publisher | Clash of Clans / Supercell |
| App Store name (draft, final in Phase 8) | Clan Hub: Stats & Guide |
| Home-screen name (CFBundleDisplayName) | Clan Hub |
| Bundle ID | com.mabou.clanhub (not yet applied to ios/ — Phase 5) |
| SKU | CLANHUB2026 |
| GitHub repo | mabou798-beep/clan-hub-companion |
| Support URL | https://mabou798-beep.github.io/clan-hub-companion/ |
| Privacy URL | https://mabou798-beep.github.io/clan-hub-companion/privacy.html |
| Team ID | K4PS39S352 |
| AdMob publisher | ca-app-pub-5383120911029833 (no other publisher ID may ship) |
| Support email | mabou798@gmail.com |
| Copyright | 2026 Mohamed Abounachit |
| Category | Reference |

## Phase 1 — Legal and IP check: DONE (GO)

Read in full 2026-10-24: https://supercell.com/en/fan-content-policy/ (last updated 2023-09-27) and
https://developer.apple.com/app-store/review/guidelines/ (4.1, 5.2.1, 5.2.2, 2.3.7).

Disclaimer (verbatim, in lib/config.dart):

> This material is unofficial and is not endorsed by Supercell. For more information see Supercell's Fan Content Policy: www.supercell.com/fan-content-policy.

Constraints: ads OK; no fee / IAP of any kind; no leaks or non-public info; no cheats, account trading,
merch, blockchain, gambling; never imply endorsement; no game name/logo/character in app name or icon;
no domain/social account containing a Supercell trademark; no fabricated data.

## Phase 2 — Data sources: DONE (official API JSON still to verify once the token exists)

| Source | Use | Auth | Verified |
|---|---|---|---|
| Official API via RoyaleAPI proxy `https://cocproxy.royaleapi.dev/v1` | player, gold pass, raid weekend, clan war, released list | Bearer token bound to IP 45.79.218.79 | 403 "Missing authorization" without token (2026-10-24); payload shapes from the official docs, re-check after deploy |
| ClashKing CDN `https://assets.clashk.ing` | `manifest.json` (art index), `static_data/*.json` (troops, heroes, pets, spells, equipment, league_tiers, war_leagues, capital_leagues) | none, CORS `*` | fetched and parsed 2026-10-24 |
| ClashKing API `https://api.clashk.ing` | not used (season dates there are shifted by a month) | — | probed |
| Supercell Fan Kit (Frontify, JS-only) | wallpapers, curated by hand into `docs/wallpapers.json` | none | TODO |

Findings:
- Official timestamps look like `20261020T080000.000Z` → `parseApiTime` in lib/util/time.dart.
- Static data has **no released flag**. Leak guard = the Worker's `/released` (union of unit names owned by the
  top 25 global players), with a bundled snapshot `assets/data/released.json` (currently EMPTY → release builds
  show no units until it is generated). Debug builds show everything with a red DEBUG banner.
- Crossover blocklist (third-party wrestling characters, my judgement): `K.A.N.E`, `Yeti Undertaker`.
- Duplicate names (Baby Dragon home/builder, Meteor Golem seasonal/permanent): keyed by name+village, permanent wins.
- Art: troop icons are framed portraits (their silhouettes are blobs/squares) → never silhouettes. Cut-outs measured
  (>=25% transparent, clear edges) → `assets/data/silhouettes.json`: 6 heroes, 8 pets, 42 equipment.
- Matching across sources uses `norm()` (lowercase letters + digits).

## Phase 3 — App: IN PROGRESS

Built: Home (live rail with 1-min countdowns + refetch at boundaries, explore cards, heroes strip), Units
(5 kinds, home/builder, search, GridView.extent, native tile every 18), Unit detail (facts + level table),
Leagues (Ranked / CWL / Capital, native tile every 10), My stats (tag saved on device, validation hints,
pull to refresh, progress per hero/equipment/troop/spell), Quiz (10 questions, silhouettes only from cut-outs),
Wallpapers (reads docs/wallpapers.json), More (support, privacy, licences, sources, disclaimer + policy link).
Fonts bundled (OFL): Lilita One (display), Nunito (body). Palette: night stone, torch gold, elixir violet.
`flutter analyze`: No issues found! (2026-10-24). Web preview checked: home, units grid, unit detail render.

Worker code: `worker/` (routes /player/:tag, /live?clan=, /released; edge-cached; token in secret COC_TOKEN).

## Phase 4 — Ads: CODE READY, IDs MISSING
lib/ads/: banner above tab bar, interstitial only at quiz round end (>=3 min, max 3/session), App Open on each
foreground return, native tiles labelled "Sponsored" (SDK template, so no Swift factory needed).
Real iOS IDs in lib/ads/ad_ids.dart are EMPTY (= no ads) until the IDs are provided.
- AdMob app ID ca-app-pub-5383120911029833~9319456318 → Info.plist GADApplicationIdentifier + AndroidManifest (2026-10-24).
- Units (lib/ads/ad_ids.dart, 2026-10-24): banner /2331998253, interstitial /5643935188, native /6327083583,
  app open /1968328332 — all under ca-app-pub-5383120911029833.
- Reminder: a new app shows "Limited ad serving" and serves no real ads until it is live on the App Store and
  linked via "Add store" in AdMob. Expected, not a bug.
- Info.plist also has NSUserTrackingUsageDescription, ITSAppUsesNonExemptEncryption=false and the 50 SKAdNetwork IDs
  from https://developers.google.com/admob/ios/privacy/strategies (fetched 2026-10-24).
- Only Google test IDs (ca-app-pub-3940256099942544) remain besides ours: lib/ads/ad_ids.dart, used only in debug
  or with USE_TEST_ADS=true.

## Worker: DEPLOYED 2026-10-24
URL: https://clan-hub-proxy.mabou798.workers.dev (Cloudflare account of the user, secret COC_TOKEN set by the user).
Developer key "clan-hub-proxy" bound to 45.79.218.79. Verified live: /live (gold pass + raid weekend, compact
timestamps), /player/%232PP (real profile; league is under "leagueTier", icons small/large only), /released
(150 names). released.json snapshot written from it; it hides event troops nobody currently owns.
Redeploy: `npx wrangler deploy --config worker/wrangler.toml` from the project root.
Bundle ID com.mabou.clanhub and IPHONEOS_DEPLOYMENT_TARGET 15.5 applied (all occurrences).

## Phase 5 — iOS config: DONE (2026-10-24)
Bundle ID com.mabou.clanhub; IPHONEOS_DEPLOYMENT_TARGET 15.5 (3/3); CFBundleDisplayName "Clan Hub";
ITSAppUsesNonExemptEncryption false; icon assets/icon/icon-1024.png (original shield + hub star, no game art,
RGB, only IHDR/IDAT/IEND) generated into all 19 iOS sizes + Android mipmaps + web; .gitattributes "* text=auto".
iPhone-only is set later in App Store Connect.

## Design update (2026-10-24, user request)
- Palette moved to the game's colour mood: evening-sky blues, gold, grass-green primary buttons, elixir pink;
  display text has a dark drop shadow. No logo, wordmark or character reused.
- Icon redrawn at 4096 px → 1024: gold shield with dark outline, hub star, four elixir gems, sky rays.
  Original art. All sizes regenerated (IHDR/IDAT/IEND only, RGB).
- Home now has: Live rail (real: Raid Weekend + Gold Pass seen live), Today (village card, daily challenge with
  local streak, unit of the day), favourites strip (star on unit page), Explore, Heroes, "Did you know?" facts
  computed from real stats. Daily challenge = 5 questions seeded by local date, once per day.

- Icon replaced by the user's own artwork (castle, red shield with gold crown, gems, coins, guide book),
  1254 px source → 1024 + all sizes; colour profile stripped (IHDR/IDAT/IEND only). Previous shield kept at
  assets/icon/icon-1024-shield-backup.png. Open risk flagged to the user: the gold crown on a shield may read as
  close to Supercell's crown marks (Fan Content Policy "similar to logos") / Apple 4.1. User decides.
- Same artwork used as the Home header banner (assets/images/home_banner.jpg, 240 px tall, fades to the background).

## Phase 6 — GitHub and pages: IN PROGRESS
docs/index.html (support), docs/privacy.html, docs/style.css, docs/icon.png, docs/wallpapers.json (empty).
No gh CLI on this PC → repo is created on github.com. Token check before commit: none in repo.

## Next
1. Create the public repo, push, enable Pages from /docs.
2. DONE 2026-10-24: docs/wallpapers.json has 12 official Fan Kit images (media.ffycdn.net, thumb ?width=600,
   full ?width=2400; checked by eye: no logos; WWE crossover and *_logo variants excluded). The screen works once
   GitHub Pages is live. User chose to keep the crown on the icon (2026-10-24).
3. Phase 7: Apple identifiers/profile, App Store Connect app, Codemagic.

## Standing rules
- Reply in Darija (Arabic script); Latin values on their own lines.
- Never submit, publish, pay or delete without a clear yes.
- Ad behaviour fixed per master prompt section 5; do not change without asking.
- Re-read files from disk after writing; close VS Code tabs before edits.
- Before every release build: grep that only ca-app-pub-5383120911029833 IDs remain and released.json is not empty.
