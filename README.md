# DopeStore

An iOS 16.7.16-first sideloading project. This repository is an engineering foundation, not yet a production replacement for SideStore.

The initial source package includes a native SwiftUI app, IPA import and metadata inspection, pairing-record validation and Keychain storage/export, device/network diagnostics, XcodeGen configuration, scripts, documentation, and six GitHub Actions workflows.

## Important status

This revision does not yet contain a complete sideloading engine. Apple ID authentication, provisioning, IPA re-signing and installation, app refresh, privileged tunnel setup, and JIT activation require a compatible device-side provider and signing setup. Those operations must not be reported as successful until implemented and tested on physical devices.

The CI build without signing secrets produces an unsigned IPA artifact only; it is not installable. See docs/FEATURE_STATUS.md, docs/IOS16_COMPATIBILITY.md, and docs/SECURITY.md.

## Build locally

Requirements: macOS, Xcode 15.4 or newer, Homebrew, and XcodeGen.

```sh
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild build -project DopeStore.xcodeproj -scheme DopeStore -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

The deployment target is iOS 16.0, which includes iOS 16.7.16.

## GitHub Actions

The source package defines workflows for IPA builds, validation, unit tests, dependency checks, compatibility checks, and signed releases. Signed releases require valid Apple signing and provisioning material stored as repository Actions secrets; never commit those secrets.

## Security

Pairing records contain sensitive device-pairing material. Keep them private. The app stores imported records in the Keychain and avoids placing them in diagnostic exports. The app intentionally does not declare private Apple entitlements.

## License

See LICENSE and THIRD_PARTY_NOTICES.md.