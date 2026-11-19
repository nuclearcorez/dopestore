# Security notes

- Never commit Apple ID credentials, private signing keys, PKCS#12 files, mobile provisioning profiles, pairing records, anisette data, or device UDIDs.
- The pairing store is scoped to the app's Keychain service and uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- The importer validates the plist shape before storing it. Validation is structural only; it does not prove that Apple or a connected device will accept the record.
- The TCP diagnostic probe sends no credentials and logs only the endpoint and pass/fail result.
- The app has no LocalDevVPN, task-port, JIT, or private installation entitlements.
- GitHub Actions signing material is read only from repository secrets and imported into a temporary CI keychain.
- Review generated diagnostic JSON before sharing because it includes timestamps, OS version, and connection test details.
