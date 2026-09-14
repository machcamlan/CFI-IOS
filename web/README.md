# CFI Mobile

A read-only web app for the CFI production Worker, built to be installed on an iPhone home screen.

No build step, no framework, no bundler. Three files and a folder of icons, served as static assets.

## Install on iPhone

1. Open the published URL in **Safari** (Chrome on iOS cannot add to the home screen).
2. Tap the share button, then **Add to Home Screen**.
3. Launch it from the icon. It opens standalone, without Safari chrome.

## What it does

Enter home team, away team and a target date. The app calls `POST /api/predict` and renders:

- the verdict and the leading market;
- all four frozen markets, each showing Method A, Method B and the calibrated Final on one axis;
- top 3 HT and FT scorelines, expected goals, and the most likely HT to FT path;
- evidence counts and HT/FT coverage;
- the control gates the Worker reports.

`GET /api/status` drives the health indicator in the header.

## What it deliberately does not do

- **No manual stat entry.** Every number comes from the Worker.
- **No fabricated zeros.** A missing probability renders as a gap, never as `0.0%`.
- **No writes.** It never calls the bet ledger, importer, or settlement endpoints, and stores no key.
- **No cached predictions.** The service worker caches the app shell only; a stale probability is worse than none.
- **No image intake yet.** Smart Image Intake needs the screenshot merge path and a server-side key, so it is out of scope here rather than faked.

## Configuration

The Worker address defaults to the production host and can be changed under **Cài đặt máy chủ** in the app. It is kept in `localStorage`, with an in-memory fallback so the app still works in Safari private browsing.

For local development, serve the folder over HTTP rather than opening the file directly, so the service worker and manifest resolve:

```bash
python3 -m http.server 8788 --directory web
```

## CORS

Browser origins need `Access-Control-Allow-Origin`, which the Worker did not previously send. The fix lives in the main CFI repository as `src/runtime/web-cors.ts`, applied in `cloudflare-worker/src/index-gpt-core-v5.ts`. Until that is deployed, every request from this app fails with a network error. Credentials are never granted to a browser origin.
