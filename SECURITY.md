# Security Policy

## Reporting a vulnerability

Please report security vulnerabilities in PCM Notes **privately**, so they can be
fixed before they are disclosed.

**Preferred:** GitHub's
[private vulnerability reporting](https://github.com/apoorvdarshan/iitjee/security/advisories/new).
The report is visible only to the maintainer.

**Alternative:** email **ad13dtu@gmail.com**
with "PCM Notes security" in the subject.

Please include:

- what the vulnerability is and what an attacker could do with it;
- steps to reproduce, ideally a minimal proof of concept;
- the affected component and version: the app version from **About** in the app
  (or `MARKETING_VERSION` in `ios/iitjee/iitjee.xcodeproj/project.pbxproj`), the
  website page, or the workflow or script;
- whether you would like to be credited, and under what name.

Please do not open a public issue, pull request or discussion for a security
problem, and do not disclose it publicly until a fix has been released.

## What to expect

- **Acknowledgement within 7 days**, and an initial assessment (whether it is
  accepted, its severity and a fix plan) within **14 days**.
- **Fixes:** critical vulnerabilities are fixed as a priority, with a target of a
  fix or mitigation within **14 days** of confirmation; others within
  **60 days**. If a fix needs an App Store release, the target is submission for
  review within that time.
- **Disclosure:** once a fix is released, the issue is published as a GitHub
  security advisory, and the release notes identify the fixed vulnerability (with
  its CVE, when one is assigned).
- **Credit:** reporters are credited in the advisory and the release notes unless
  they ask to stay anonymous.

## Supported versions

Only the latest version on the App Store receives security fixes. The `main`
branch tracks the next release. The website at
[iitjee.apoorvdarshan.com](https://iitjee.apoorvdarshan.com/) is always served
from `main`.

## Scope

In scope:

- the iOS and iPadOS app in `ios/`: the PDF reader, the bundled offline notes,
  locally stored preferences and reading progress, and the optional tip jar
  (StoreKit and RevenueCat);
- the website: the static pages, `script.js` and the Cloudflare Workers
  static-asset configuration in `wrangler.jsonc`;
- the build, test and release tooling: the offline-notes generator in
  `ios/iitjee/BuildTools/`, the scripts in `scripts/` and `fuzz/`, and the GitHub
  Actions workflows in `.github/workflows/`, including handling of App Store
  Connect credentials.

Out of scope:

- vulnerabilities in Apple's platforms (iOS, PDFKit, StoreKit), RevenueCat,
  Cloudflare or GitHub themselves; please report those to the vendor;
- attacks that need physical access to an unlocked device;
- reports from automated scanners without a demonstrated impact on PCM Notes;
- the accuracy of the notes' content; please open an ordinary issue for mistakes
  in the notes.

## Safe harbor

Good-faith security research that follows this policy is welcome. PCM Notes will
not pursue legal action over it. Please do not access other people's data,
degrade the website or the App Store listing, or use social engineering, and give
reasonable time for a fix before any disclosure.
