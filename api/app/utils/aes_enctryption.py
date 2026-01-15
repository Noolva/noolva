from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend
from base64 import b64encode, b64decode

SECRET_KEY = b"mysecretaeskey12"  # 16-byte key for AES

def encrypt(cls, device_code: str) -> str:
    """Encrypts a string using AES encryption with ECB mode."""
    padder = padding.PKCS7(128).padder()
    padded_code = padder.update(device_code.encode()) + padder.finalize()

    cipher = Cipher(algorithms.AES(cls.SECRET_KEY), modes.ECB(), backend=default_backend())
    encryptor = cipher.encryptor()
    encrypted = encryptor.update(padded_code) + encryptor.finalize()
    
    return b64encode(encrypted).decode()

def decrypt(cls, encrypted_code: str) -> str:
    """Decrypts an AES-encrypted string."""
    decoded = b64decode(encrypted_code)

    cipher = Cipher(algorithms.AES(cls.SECRET_KEY), modes.ECB(), backend=default_backend())
    decryptor = cipher.decryptor()
    decrypted = decryptor.update(decoded) + decryptor.finalize()

    unpadder = padding.PKCS7(128).unpadder()
    unpadded_decrypted = unpadder.update(decrypted) + unpadder.finalize()

    return unpadded_decrypted.decode()
