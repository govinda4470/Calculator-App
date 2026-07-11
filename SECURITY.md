# Security posture

Precision Calc follows a privacy-first baseline, but no mobile application can honestly guarantee that it is "unhackable." A rooted device, compromised operating system, stolen signing key, malicious dependency, or breached upstream provider can bypass client-only controls. Paid entitlements and privileged operations must therefore be verified by a trusted backend.

## Implemented controls

- HTTPS-only Android network policy; clear-text HTTP is blocked.
- Trust is limited to Android's system certificate authorities in release builds.
- Android cloud backup and device-transfer backup are disabled.
- Crypto screens use Android `FLAG_SECURE` to block screenshots and recent-app thumbnails.
- No contacts, location, camera, microphone, storage, or advertising permissions.
- Portfolio entries, market cache, and user-provided AI credentials are memory-only.
- API hosts are allow-listed, requests have timeouts, and responses have strict size limits.
- Provider/socket internals are not displayed in user-facing errors.
- AI questions and outputs are length-limited.
- Release builds enable R8 code/resource shrinking and never use the debug signing key.

## Production requirements before accounts or subscriptions

1. Put AI provider secrets behind a server-side proxy. Never ship owner API keys in Dart, APK assets, or `--dart-define` values.
2. Add authenticated user accounts and short-lived access tokens.
3. Enforce row-level security so users can read and modify only their own rows.
4. Validate Google Play purchases and RevenueCat webhooks on the server.
5. Verify Google Play Integrity verdicts on the server for sensitive operations.
6. Add per-user AI quotas, server-side rate limits, idempotency keys, and spending limits.
7. Store secrets in a managed secret vault and rotate them regularly.
8. Require MFA for administrators and record immutable admin audit events.
9. Add dependency, SAST, secret, and signed-release checks in CI.
10. Publish a reviewed privacy policy, retention schedule, deletion process, and incident-response contact.

## Secure release

Use a private upload key managed by CI or Google Play App Signing. Never commit a keystore or its password.

```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=private-symbols/android
```

Keep `private-symbols/` private for crash symbolication. Upload the AAB to a closed Play testing track before production. Do not distribute a debug-signed APK as a production release.

## Data minimization

The current application does not persist calculations, portfolio holdings, or AI credentials. If backend persistence is added, collect only fields needed for the feature, encrypt data in transit and at rest, use explicit retention periods, and support export/deletion requests.
