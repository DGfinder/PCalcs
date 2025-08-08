# PCalcs

An iPad EFB-style app for aircraft performance (initial type: Beechcraft 1900D). Offline-first, SwiftUI + MVVM, with a separate `PerfCalcCore` SwiftPM package.

## Run
1. Open `PCalcs/PCalcs.xcodeproj` in Xcode 15+.
2. Select the `PCalcs` scheme and iPad simulator (or device) and Run.
3. Optional: link the local SwiftPM package `PerfCalcCore` via File → Add Packages → Add Local… (or ensure Package.swift resolves correctly).

## Data Packs
- Drop `DataPack.sqlite` into the app bundle (Resources) when ready.
- To swap the provider, in `DataPackManager` (guarded by GRDB), switch to `GRDBDataPackProvider` (see commented example) and ensure GRDB is linked.

## RC Scheme & Demo Mode
- RC configuration enables `DEMO_LOCK` build flag. UI overlays a faint “DEMO” watermark on Results.
- When Demo Lock is enabled (see `Settings → Debug`), destructive actions are disabled (e.g., deleting history, DB reset). A caption indicates “Disabled in Demo Mode”.

## History — Read-Only Restore & Clone
- Restoring from History opens Results in read-only mode. Inputs, What-If, and export option edits are disabled, and a "READ-ONLY" pill is shown.
- Use “Clone to New Calc” to create an editable session: it deep-copies inputs/results and clears the history ID.

## Weather Behavior
- Auto-fetch can be enabled in Settings. On airport/runway change, weather auto-fetch debounces by ~300 ms.
- Fresh network or valid cache within TTL: no toast; WX chip animates with a pulse and haptic.
- Stale cache: amber toast “Using cached WX from hhmmZ”.
- Failure with cache present: amber toast “Weather proxy unreachable — using last cached at hhmmZ”.
- Failure with no cache: red toast “Weather unavailable — no cached data”.

## PDF Export
- Branded PDF with inputs, outputs, versions, calculation hash, signature lines, and Legal/Privacy block. Includes TAF and technical details when selected.

## Tests
- Unit tests cover core calculations, GRDB data provider (guarded by `#if canImport(GRDB)`), weather cache, PDF options, WX chip color logic, and UI smoke paths.

## Next Steps
- Integrate GRDB Data Pack provider and seed real AFM tables.
- Fill in CorrectionsEngine (wind/slope/wet) and CompanyLimits rules.
- Add screenshot generator for marketing assets.