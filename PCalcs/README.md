# PCalcs (Beechcraft 1900D Performance)

This repository contains an iPadOS SwiftUI app skeleton for offline aircraft performance calculations with a separate core calculation module. The initial target is the Beechcraft 1900D.

Highlights:
- MVVM architecture with a dedicated calculator service
- Core engine in `PerfCalcCore` Swift Package (no UI deps)
- Offline-first, local Data Pack loading via `DataPackManager` (GRDB-ready, currently stubbed)
- Strict input validation and clear error types
- SwiftUI forms and results screens with PDF export stub
- XCTest placeholder tests and golden dataset loader stub

## Open and run in Xcode (15+)
1. Open `PCalcs.xcodeproj` in Xcode.
2. Select the `PCalcs` scheme and an iPad simulator.
3. Build and run. The app will compile and run with dummy outputs.

Optional (link the core module):
- In Xcode, add the local Swift package `PerfCalcCore`:
  - File → Add Packages… → Add Local → select the `PerfCalcCore` folder
  - Link the `PerfCalcCore` product to the `PCalcs` app target (Frameworks, Libraries, and Embedded Content → Add `PerfCalcCore`)
  - The app will automatically use the real `PerformanceCalculator` if the package is linked

## Data Packs
- `DataPackManager` is structured for GRDB/SQLite, but GRDB is not required to compile.
- Replace the stub provider with a GRDB-backed provider when integrating real data.
- Schema assumption (tables): `to_tables`, `ld_tables`, `v_speeds`, `corrections`, `limits`, `metadata`.

## Tests
- Placeholder tests are included in `PerfCalcCore/Tests/PerfCalcCoreTests`.
- Once the package is added to the Xcode project, enable the tests in the Test navigator.

## Notes
- All internal units are SI. UI converts as needed for display.
- Never extrapolates beyond certified data: inputs are validated and will return descriptive errors.
- PDF export is a stub using `UIGraphicsPDFRenderer`; wire in your branding and formatting later.