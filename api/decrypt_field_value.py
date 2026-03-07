#!/usr/bin/env python3
"""
Decrypt a value that was encrypted by the Noolva API (data model field encryption).

Uses the same key as the app: ENCRYPTION_KEY for AES, fixed key "noolva" for XOR.
Run from repo root: python api/decrypt_field_value.py <method> <encrypted_value>
  method: aes | xor_cipher
  encrypted_value: base64-encoded string (e.g. from DB or API response)

Example:
  python api/decrypt_field_value.py xor_cipher "SGVsbG8="
  python api/decrypt_field_value.py aes "dGVzdC1ub25jZTEyMzQ1Njc4OTBhYmM..."
"""
import os
import sys

# Allow importing app when run as script from repo root or api/
_script_dir = os.path.dirname(os.path.abspath(__file__))
if _script_dir not in sys.path:
    sys.path.insert(0, _script_dir)

def main():
    if len(sys.argv) != 3:
        print("Usage: python api/decrypt_field_value.py <method> <encrypted_value>", file=sys.stderr)
        print("  method: aes | xor_cipher", file=sys.stderr)
        sys.exit(1)
    method = (sys.argv[1] or "").strip().lower()
    encrypted = (sys.argv[2] or "").strip()
    if method not in ("aes", "xor_cipher"):
        print("method must be 'aes' or 'xor_cipher'", file=sys.stderr)
        sys.exit(1)
    if method == "aes" and not os.environ.get("ENCRYPTION_KEY"):
        print("ENCRYPTION_KEY must be set for AES decryption (e.g. in .env or export)", file=sys.stderr)
        sys.exit(1)

    from app.utils.field_encryption import decrypt_field_value

    out = decrypt_field_value(method, encrypted)
    if out is None and encrypted:
        print("Decryption failed (invalid value or wrong key).", file=sys.stderr)
        sys.exit(1)
    print(out or "")

if __name__ == "__main__":
    main()
