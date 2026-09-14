# CFI-IOS

Two iPhone clients for the CFI football intelligence Worker.

| | `ios/` | `web/` |
|---|---|---|
| What it is | Native SwiftUI app | Installable web app |
| Install | Sideload an IPA with iLoader or AltStore | Safari, Add to Home Screen |
| Needs a build | Yes, on a GitHub macOS runner | No |
| Expiry | 7 days on a free Apple ID | Never |

Both call the same API and show the same thing. Start with `web/` if you want
something working today; build `ios/` if you want a real installed app.

## Getting the IPA without a Mac

`.github/workflows/build-ios-ipa.yml` runs on a GitHub-hosted macOS runner and
produces an **unsigned** IPA. No Mac, no Apple Developer account, no certificate.

1. **Actions** → **Build CFI iOS IPA** → **Run workflow**
2. Put `v1.0.0` in the tag field
3. Wait about five minutes
4. Download `CFI-unsigned.ipa` from **Releases**

Filling in the tag matters: it attaches the IPA to a Release, which downloads
cleanly on an iPhone. Leave it blank and you get a zipped artifact instead,
which Safari on iOS handles poorly.

Then open iLoader, import the IPA, and let it sign with your Apple ID. First
launch needs **Settings → General → VPN & Device Management** to trust the
profile.

A free Apple ID signature expires after 7 days and the app stops opening;
refresh it in the sideloading tool before then. That limit is Apple's and
applies to every sideloaded app.

## Using the web app instead

Turn on **Settings → Pages → Source: GitHub Actions**, or serve `web/` from any
static host. On the phone, open it in Safari and choose Add to Home Screen.
It runs standalone, without browser chrome.

To try it locally:

```bash
python3 -m http.server 8788 --directory web
```

## Point it at your Worker

Both clients default to the CFI production Worker and can be repointed in their
own settings screen.

**The web app needs CORS on the Worker.** Browsers block cross-origin reads
without it, so every request fails until the Worker sends the headers. The
change lives in the main CFI repository as `src/runtime/web-cors.ts`. The native
app is not subject to CORS and works either way.

## Reading the output

Each market is drawn on one axis:

- **white tick** — Method A, historical statistics
- **blue tick** — Method B, Match DNA
- **green bar** — the calibrated Final

Two ticks far apart means the models disagree, and where Final sits between them
shows which way the calibration leaned. Collapsing them into a single number in
the presentation layer would hide exactly that.

A missing probability shows as a gap, never as `0.0%`. A non-OK server status
shows the reason instead of rendering a prediction.

## Scope

Both clients are read-only. They hold no key and call no write endpoint. Smart
Image Intake is absent rather than stubbed; it needs the screenshot merge path
and a server-side key.

Probabilities are model distribution mass, not a guaranteed match script.
