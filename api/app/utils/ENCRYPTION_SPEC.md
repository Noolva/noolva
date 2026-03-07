# Data model field encryption spec

This document describes how encrypted field values are produced by the Noolva API (auto-crud and data models). Use the same algorithms and keys in another application to decrypt content encrypted by this application.

**Note:** Login passwords are stored with **bcrypt** (one-way hash), not with these methods. This spec applies only to **reversible** encryption used for data model fields (`encryption_method`: `xor_cipher` or `aes`). The same AES key (`ENCRYPTION_KEY`) is used for credentials and for AES field encryption.

---

## 1. XOR cipher (`encryption_method = 'xor_cipher'`)

- **Key:** The UTF-8 encoding of the string `"noolva"` (fixed). No padding or truncation.
- **Encoding:** Plaintext and key are UTF-8 bytes.

**Encryption:**
1. `key_bytes = "noolva".encode("utf-8")`
2. `data = plaintext.encode("utf-8")`
3. For each index `i`: `out[i] = data[i] XOR key_bytes[i % len(key_bytes)]`
4. Ciphertext = **Base64** encode of `out`.

**Decryption:**
1. `out = Base64` decode of stored value.
2. Same key_bytes as above.
3. For each index `i`: `data[i] = out[i] XOR key_bytes[i % len(key_bytes)]`
4. Plaintext = `data.decode("utf-8")`.

**Example (Python):**
```python
import base64

def xor_decrypt(value: str, key: str = "noolva") -> str:
    key_bytes = key.encode("utf-8")
    data = base64.b64decode(value.encode("utf-8"))
    out = bytes([b ^ key_bytes[i % len(key_bytes)] for i, b in enumerate(data)])
    return out.decode("utf-8")
```

---

## 2. AES (`encryption_method = 'aes'`)

- **Cipher:** AES-256-GCM (authenticated encryption).
- **Key:** 32 bytes. Source: environment variable **`ENCRYPTION_KEY`** (same key as used for credentials and elsewhere in the app).
  - If the value is valid **Base64**, decode it; decoded length must be 32 bytes.
  - If not Base64, use the UTF-8 bytes of the string: **pad with zero bytes to 32** or **truncate to 32** bytes.
- **Per encryption:**
  - **Nonce:** 12 bytes (96-bit), random (e.g. `os.urandom(12)`).
  - **Plaintext:** JSON object with a single key `"v"` and the string value: `{"v": "<string value>"}`. Serialized with UTF-8 (JSON keys sorted in our implementation).
  - **Ciphertext:** AES-GCM encrypt(nonce, plaintext_bytes, no additional authenticated data).
  - **Stored value:** **Base64**(nonce || ciphertext), i.e. nonce first, then ciphertext, then Base64 encode.

**Decryption:**
1. Decode the stored value from **Base64** → raw bytes.
2. **Nonce** = first **12 bytes**; **ciphertext** = remaining bytes.
3. AES-GCM decrypt(nonce, ciphertext) → plaintext bytes.
4. Decode as UTF-8, parse as JSON, and take the **`"v"`** field as the decrypted string.

**Example (Python, using cryptography):**
```python
import os
import json
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

def get_key():
    key_str = os.environ.get("ENCRYPTION_KEY")
    if not key_str:
        raise ValueError("ENCRYPTION_KEY not set")
    try:
        key = base64.b64decode(key_str)
        if len(key) != 32:
            raise ValueError("ENCRYPTION_KEY must decode to 32 bytes")
        return key
    except Exception:
        key_bytes = key_str.encode("utf-8")
        if len(key_bytes) < 32:
            key = key_bytes.ljust(32, b"\0")
        else:
            key = key_bytes[:32]
        return key

def aes_decrypt_field(encrypted_b64: str) -> str:
    raw = base64.b64decode(encrypted_b64)
    if len(raw) < 13:
        raise ValueError("Invalid encrypted data format")
    nonce, ciphertext = raw[:12], raw[12:]
    aesgcm = AESGCM(get_key())
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    payload = json.loads(plaintext.decode("utf-8"))
    return payload["v"]
```

---

## 3. Summary

| Method      | Key source        | Stored format                          |
|------------|-------------------|----------------------------------------|
| `xor_cipher` | Fixed: `"noolva"` | Base64(XOR(plaintext_utf8, repeating_key)) |
| `aes`        | `ENCRYPTION_KEY` (32 bytes) | Base64(nonce_12 || AES256GCM(JSON `{"v":"<value>"}`)) |

Use the **same** `ENCRYPTION_KEY` in the other application as in this application to decrypt AES fields.
