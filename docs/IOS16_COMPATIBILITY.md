# iOS 16.7.16 compatibility notes

## Known SideStore failure pattern

SideStore issue #1466 documents an iPhone X on iOS 16.7.16 where LocalDevVPN reported connected and the pairing file loaded, but device reachability remained unreachable and refresh failed with `DeviceEndpointNotInitialized`. The reporter said moving to the EMProxy/WireGuard route restored reachability and Refresh All on that device:

- https://github.com/SideStore/SideStore/issues/1466

This is a field report, not proof that WireGuard fixes every iOS 16 device. Issue #1488 reports the opposite behavior on another iOS 16.7.16 setup: WireGuard caused a hang while LocalDevVPN without WireGuard was stable:

- https://github.com/SideStore/SideStore/issues/1488

SideStore's 0.6.4 release notes also list difficulty connecting to LocalDevVPN on iOS 16 as a known issue:

- https://github.com/SideStore/SideStore/releases

## DopeStore behavior today

This app can observe general network connectivity and enumerate visible `utun` interfaces. Settings includes a TCP probe for a user-configured device endpoint (default `10.7.0.1:49152`). A successful TCP probe means only that a TCP connection was accepted. It does not establish that pairing, signing, app installation, or refresh is valid.

DopeStore does not create a VPN profile, reconfigure LocalDevVPN, or change private Apple network entitlements. Those actions require the relevant provider app and user consent.

## Physical-device test matrix required before claiming iOS 16.7.16 support

- Fresh install + original lockdown pairing record.
- Existing SideStore 0.6.4 data migration / clean install comparison.
- LocalDevVPN with the default address configuration and local-network permission enabled.
- LocalDevVPN with a separately tested peer/tunnel address configuration.
- EMProxy/WireGuard enabled and disabled independently.
- TCP reachability to the actual pairing service port, not just ICMP ping.
- Refresh over Wi-Fi and cellular, repeated across app relaunch and reboot.
- On-device Anisette enabled/disabled on the actual device/OS combination.
- Lockdown vs remote-pairing record selection matched to the OS version.

Capture diagnostic logs and exact provider versions for every failure. Never automatically change the user's VPN configuration without consent.
