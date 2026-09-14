# CFI for iOS — native app, sideloaded

A native SwiftUI app for the CFI production Worker, built to be installed with
iLoader, AltStore, Sideloadly or any other sideloading tool.

This is not a web view. It is a real iOS binary that calls `/api/predict`
directly and renders the result with native controls.

## Getting the IPA without owning a Mac

The `Build CFI iOS IPA` workflow runs on a GitHub-hosted macOS runner and
produces an **unsigned** `.ipa`. You do not need Xcode, a Mac, an Apple
Developer account or a certificate to get the file.

1. Push this repository to GitHub.
2. Open **Actions** → **Build CFI iOS IPA** → **Run workflow**.
3. Fill in a tag such as `v1.0.0` if you want the IPA attached to a Release.
   A Release is easier to download straight onto an iPhone; a plain artifact
   downloads as a zip that Safari on iOS handles poorly.
4. Wait roughly five minutes, then download `CFI-unsigned.ipa`.

## Installing with iLoader

1. Open iLoader on the iPhone and sign in with your Apple ID.
2. Import `CFI-unsigned.ipa`.
3. Let it sign and install.
4. First launch only: **Settings → General → VPN & Device Management**, then
   trust the developer profile.

**A free Apple ID signature expires after 7 days.** Reopen the sideloading tool
and refresh before then, or the app stops launching. A paid developer account
extends this to a year. That limit comes from Apple, not from this app.

## The Worker must have CORS deployed first

A native app is not bound by browser CORS, so this app would work without it.
The shared web app is not, which is why `src/runtime/web-cors.ts` exists. Deploy
the Worker either way so both clients behave the same:

```bash
npm ci && npx wrangler deploy
```

## Building locally, if you do have a Mac

```bash
brew install xcodegen
cd ios
xcodegen generate
open CFI.xcodeproj
```

Select your own team under Signing & Capabilities, then run on a device.

## Structure

| File | Role |
|---|---|
| `project.yml` | XcodeGen spec; the `.xcodeproj` is generated, never committed |
| `CFI/Sources/Models.swift` | Lenient JSON tree plus the four frozen markets |
| `CFI/Sources/CFIClient.swift` | Networking and payload to model conversion |
| `CFI/Sources/Theme.swift` | Palette and the market measure view |
| `CFI/Sources/ContentView.swift` | Screens and state |

## Design notes

Each market draws Method A, Method B and the calibrated Final on one axis, plus
the spread between the two methods. Collapsing them into a single number in the
presentation layer would hide the disagreement, which is the substance of what
CFI computes.

The payload is decoded as a JSON tree rather than fixed structs. Engine versions
add and remove fields, and a rigid decoder would make the app fail on a response
the Worker considers valid.

## Frozen semantics in the UI

- A missing probability renders as "chưa đủ dữ liệu", never as `0.0%`.
- A non-OK server status never renders as a prediction; the reason is shown.
- The app is read-only. It holds no key and calls no write endpoint.
