# Feature status matrix

| Requirement | Status | Notes |
|---|---|---|
| Native SwiftUI app and five tabs | Implemented | iOS 16 deployment target |
| IPA file import and Open-In | Implemented | Copies file into app sandbox |
| IPA app metadata inspection | Implemented | Reads Info.plist from Payload app bundle |
| Install IPA | Not implemented | Needs privileged/signing bridge; no public install API |
| Apple ID login | Not implemented | Must be connected to an audited provider; no credential capture UI |
| App signing / provisioning | Not implemented | Needs developer portal auth, cert/key lifecycle and SideSign-like implementation |
| Installed app enumeration | Not implemented | Third-party app sandbox restrictions prevent full inventory |
| Pairing record import | Implemented with structural validation | Does not establish a live lockdown session |
| Pairing record secure storage | Implemented | Keychain, ThisDeviceOnly |
| Pairing record original-format export | Implemented | Preserves imported bytes |
| Certificate expiry display | Partial | DER cert expiry shown if discoverable in plist |
| Refresh individual/all | Not implemented | Requires the signing and device installation provider |
| Cellular refresh | Not implemented | Requires an active compatible tunnel/provider and background execution support |
| JIT activation | Not implemented | Cannot be granted by an ordinary sandboxed app |
| Network and tunnel diagnostics | Partial | Path and utun enumeration plus configurable TCP probe |
| Diagnostic export | Implemented | JSON event export |
| CI builds/tests/IPA packaging | Implemented as automation source | Must run on macOS/Xcode; no Xcode runner is available in this workspace |
| Installable signed release | Conditional | Requires user-supplied valid cert/profile secrets and registered devices |
