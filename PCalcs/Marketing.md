# PCalcs — Penjet EFB Performance (B1900D)

PCalcs is an offline-first iPad EFB-style app for certified aircraft performance. It ships with a modular core engine and a premium SwiftUI interface tailored for iPad.

## Highlights
- **Offline-first**: All calculations run locally from versioned Data Packs (SQLite/GRDB).
- **Certified tables & no extrapolation**: Strict bounds enforcement with linear/bilinear interpolation only within certified envelopes.
- **OEI & Company limits**: Engines for OEI obstacle checks and company policy gates (PASS/FAIL) with clear surfacing.
- **Branded PDF**: Professional PDF export with Penjet branding, calculation hash, signatures, and detailed assumptions.

## Privacy
No personal data is collected. Weather and performance data are cached on device. The weather proxy may log ICAO and timestamp for reliability.

## Screenshots
If you enable the debug screenshot generator, images are exported under:
- `PCalcs/PCalcsScreenshots/Home.png`
- `PCalcs/PCalcsScreenshots/NewCalc.png`
- `PCalcs/PCalcsScreenshots/Results.png`
- `PCalcs/PCalcsScreenshots/History.png`
- `PCalcs/PCalcsScreenshots/Settings.png`

Use these in App Store Connect or internal docs as needed.