# PCalcs - Beechcraft 1900D Performance Calculator

A professional-grade iPad EFB (Electronic Flight Bag) application for Beechcraft 1900D performance calculations. Provides comprehensive takeoff and landing performance analysis with real-time weather integration, regulatory compliance checking, and audit-ready PDF reports.

## Features

- **Performance Calculations**: Takeoff and landing performance for Beechcraft 1900D
- **Weather Integration**: Real-time METAR/TAF data with automatic application to calculations
- **Regulatory Compliance**: Built-in AFM, OEI, and company policy checks
- **Professional Reports**: PDF export with signatures, evidence, and full audit trail
- **Calculation History**: Persistent storage with search and filtering
- **Evidence System**: Cryptographic verification of all calculations
- **Cloud Sync**: Optional secure backup and synchronization

## Evidence & Cloud Sync

PCalcs implements a comprehensive cryptographic evidence system to ensure calculation integrity and provide audit trails:

### Evidence Generation Flow

1. **Calculation Completion**: When a performance calculation is saved, the app generates canonical JSON payload containing all inputs, outputs, weather data, and metadata
2. **Deterministic Hashing**: The payload is encoded using deterministic JSON (lexicographically sorted keys, RFC3339 dates) and hashed with SHA256
3. **Digital Signing**: The hash is cryptographically signed using Ed25519 with device-specific keys stored securely in the iOS Keychain
4. **Evidence Storage**: Hash, signature, and device public key are stored with the calculation for verification

### Cloud Synchronization

When enabled, calculations are automatically uploaded to secure cloud storage:

1. **PDF Generation**: Complete performance report with embedded evidence information
2. **Secure Upload**: PDF stored in Supabase cloud storage with authenticated access
3. **History Backup**: Calculation metadata and evidence uploaded to database
4. **Offline First**: App functions fully without network; cloud sync is best-effort enhancement

### Security Features

- **Ed25519 Cryptography**: Industry-standard digital signatures for evidence integrity
- **Keychain Storage**: Private keys never leave device, stored with hardware encryption
- **Canonical Encoding**: Deterministic JSON ensures consistent hashing across devices
- **No Personal Data**: Only performance calculations and evidence are synchronized
- **Audit Trail**: Full chain of custody from calculation through cloud storage

### Configuration

Cloud sync is configured in Settings with:
- Supabase URL and anonymous key
- Enable/disable toggle
- Manual sync trigger
- Device public key display (debug mode)

The evidence system works offline and provides local verification even without cloud sync enabled.

## Technical Stack

- **Platform**: iOS (iPad) - SwiftUI, Swift 5.9+
- **Database**: SQLite (local), Supabase (cloud)
- **Cryptography**: CryptoKit (Ed25519, SHA256)
- **Weather**: Custom proxy service for METAR/TAF
- **PDF**: UIKit PDF rendering with custom layouts
- **Architecture**: MVVM with Combine, dependency injection

## Development

Requirements:
- Xcode 15+
- iOS 16+ deployment target
- Swift 5.9+

Build and run:
1. Open `PCalcs.xcodeproj` in Xcode
2. Select iPad simulator or device
3. Build and run (⌘R)

Tests:
```bash
# Run unit tests
xcodebuild test -project PCalcs.xcodeproj -scheme PCalcs -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)'
```

## License

Proprietary - All rights reserved.