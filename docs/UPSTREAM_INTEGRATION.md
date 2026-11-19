# Upstream signing and device bridge integration

DopeStore deliberately separates its IPA library, pairing-record store, diagnostics, and SwiftUI presentation from the privileged signing/install/refresh operations.

Candidate upstream components reviewed:

- [SideStore](https://github.com/SideStore/SideStore): an established on-device app that signs apps with a personal development certificate and uses a local VPN/loopback path. Its current README describes EM Proxy, Minimuxer, and a dedicated VPN entitlement. The project is AGPL-3.0.
- [SideSign](https://github.com/SideStore/SideSign): a Swift library for app bundle resigning, provisioning certificates/profiles, and Apple Developer API communication. Its repository declares GPL-3.0 and documents `AppBundleSigner`, CSR generation, PKCS#12 handling, and provisioning-profile support.
- [Minimuxer](https://github.com/SideStore/minimuxer): the lockdown muxer used by SideStore to reach the device services exposed over its tunnel.

These are not linked in this build. Integrating them safely requires reviewing current public API compatibility, transitive dependencies, licensing obligations, iOS 16.7.16 behavior, and test coverage. The provider must not assume a VPN interface being up means the peer is reachable. It must expose typed results for tunnel, endpoint, pairing protocol, provisioning, and signing failures.

## Required provider contract

A production `SideloadingProvider` should expose:

1. Apple account sign-in and 2FA without persisting passwords outside Keychain.
2. Team, certificate, App ID, device registration, and provisioning-profile lifecycle.
3. IPA extraction, entitlement rewriting, nested code signing, and archive repackaging.
4. Separate lockdown and remote-pairing transports, selected by OS compatibility and pairing-file contents.
5. Endpoint probing that tests the configured TCP service, not only ICMP or VPN interface presence.
6. Install/update calls with idempotency keys and structured errors.
7. Refresh scheduling with background execution limitations documented and no claim of guaranteed background operation.
8. A JIT provider that confirms OS-level activation for a specific target process before displaying an enabled state.

No Apple-private entitlement should be requested from the ordinary DopeStore target. Any privileged tunnel/installer app must be a separate signed component with its own capability provisioning and security review.
