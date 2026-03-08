"""
Data model field encryption: XOR cipher and AES (same as EncryptionService).

Used by auto-crud for fields with encryption_method = 'xor_cipher' or 'aes'.
AES uses the same key (ENCRYPTION_KEY) as login credentials and other app secrets.
See ENCRYPTION_SPEC.md in this directory for algorithm details so other apps can decrypt.

For file/image fields with encryption: encrypt the file content (bytes), not the DB column value.
Use encrypt_file_content / decrypt_file_content for binary data.
"""
import base64
from typing import Optional

# Default XOR key used by data_models auto-crud (must match ENCRYPTION_SPEC.md)
XOR_DEFAULT_KEY = "noolva"


def xor_encrypt(value: Optional[str], key: str = XOR_DEFAULT_KEY) -> Optional[str]:
    """Encrypt a string with XOR cipher; output is base64."""
    if value is None:
        return value
    key_bytes = (key or XOR_DEFAULT_KEY).encode("utf-8")
    data = value.encode("utf-8")
    out = bytes([b ^ key_bytes[i % len(key_bytes)] for i, b in enumerate(data)])
    return base64.b64encode(out).decode("utf-8")


def xor_decrypt(value: Optional[str], key: str = XOR_DEFAULT_KEY) -> Optional[str]:
    """Decrypt a base64 XOR-cipher string."""
    if value is None:
        return value
    key_bytes = (key or XOR_DEFAULT_KEY).encode("utf-8")
    data = base64.b64decode(value.encode("utf-8"))
    out = bytes([b ^ key_bytes[i % len(key_bytes)] for i, b in enumerate(data)])
    return out.decode("utf-8")


def aes_encrypt_field(value: str) -> str:
    """
    Encrypt a single field value with AES (same service as credentials).
    Stored format: base64(nonce_12_bytes || aes_gcm_ciphertext).
    Plaintext is JSON: {"v": "<value>"}.
    """
    from utils.encryption_service import get_encryption_service
    enc = get_encryption_service()
    return enc.encrypt({"v": str(value)})


def aes_decrypt_field(encrypted_value: str) -> Optional[str]:
    """
    Decrypt a field value encrypted by aes_encrypt_field.
    Returns payload["v"] or None if decryption fails.
    """
    from utils.encryption_service import get_encryption_service
    enc = get_encryption_service()
    try:
        payload = enc.decrypt(encrypted_value)
        return payload.get("v")
    except Exception:
        return None


def encrypt_field_value(method: str, value: Optional[str], xor_key: str = XOR_DEFAULT_KEY) -> Optional[str]:
    """
    Encrypt a field value by method ('none', 'xor_cipher', 'aes').
    Returns None for None or method 'none'; otherwise encrypted string.
    """
    if value is None or method == "none" or not method:
        return value
    if method == "xor_cipher":
        return xor_encrypt(value, xor_key)
    if method == "aes":
        return aes_encrypt_field(value)
    return value


def decrypt_field_value(
    method: str,
    encrypted_value: Optional[str],
    xor_key: str = XOR_DEFAULT_KEY,
) -> Optional[str]:
    """
    Decrypt a field value by method ('none', 'xor_cipher', 'aes').
    Returns original value for None or method 'none'; otherwise decrypted string.
    On AES failure returns the raw value (best-effort).
    """
    if encrypted_value is None or method == "none" or not method:
        return encrypted_value
    if method == "xor_cipher":
        try:
            return xor_decrypt(encrypted_value, xor_key)
        except Exception:
            return encrypted_value
    if method == "aes":
        out = aes_decrypt_field(encrypted_value)
        return out if out is not None else encrypted_value
    return encrypted_value


# --- File content encryption (for file/image fields: encrypt bytes, not the path) ---

def xor_encrypt_bytes(data: bytes, key: str = XOR_DEFAULT_KEY) -> bytes:
    """Encrypt raw bytes with XOR cipher. Key is repeated to match data length."""
    if not data:
        return data
    key_bytes = (key or XOR_DEFAULT_KEY).encode("utf-8")
    return bytes([b ^ key_bytes[i % len(key_bytes)] for i, b in enumerate(data)])


def xor_decrypt_bytes(data: bytes, key: str = XOR_DEFAULT_KEY) -> bytes:
    """Decrypt bytes encrypted with xor_encrypt_bytes (XOR is symmetric)."""
    return xor_encrypt_bytes(data, key)


def encrypt_file_content(method: str, data: bytes, xor_key: str = XOR_DEFAULT_KEY) -> Optional[bytes]:
    """
    Encrypt file/content bytes by method ('xor_cipher' or 'aes').
    Returns encrypted bytes to store in S3. For 'aes', format is 12-byte nonce + ciphertext.
    Returns None for None/empty or method 'none'.
    """
    if data is None or method == "none" or not method:
        return data
    method = (method or "").strip().lower()
    if method == "xor_cipher":
        return xor_encrypt_bytes(data, xor_key)
    if method == "aes":
        from utils.encryption_service import get_encryption_service
        enc = get_encryption_service()
        return enc.encrypt_bytes(data)
    return data


def decrypt_file_content(method: str, data: bytes, xor_key: str = XOR_DEFAULT_KEY) -> Optional[bytes]:
    """
    Decrypt file/content bytes by method ('xor_cipher' or 'aes').
    Returns decrypted bytes. On failure returns None.
    """
    if data is None or method == "none" or not method:
        return data
    method = (method or "").strip().lower()
    if method == "xor_cipher":
        return xor_decrypt_bytes(data, xor_key)
    if method == "aes":
        from utils.encryption_service import get_encryption_service
        enc = get_encryption_service()
        try:
            return enc.decrypt_bytes(data)
        except Exception:
            return None
    return data
