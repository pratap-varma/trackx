# Secure QR Attendance Verification

TrackX implements confirmation-based QR presence scanning.

## Security Design

1. **Short-Lived Signed Tokens**: Payloads must expire after 60 seconds.
2. **Signature Verification**: Verifies the HMAC-SHA256 signature against university public keys.
3. **Replay Nonce Lists**: Prevent double scanning by storing nonces locally.

## Limitations

QR verification proves a code was scanned; it does not prove physical classroom presence. TrackX is read-only and local; university logs remain the authoritative source.
