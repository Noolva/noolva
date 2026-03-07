"""
Encryption Service for secure credential storage
Uses AES-256-GCM for authenticated encryption
"""
import os
import json
import base64
from typing import Dict, Any, Optional
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.backends import default_backend


class EncryptionService:
    """
    Service for encrypting and decrypting sensitive data (credentials, tokens, etc.)
    Uses AES-256-GCM for authenticated encryption with integrity verification
    """
    
    def __init__(self, key: Optional[bytes] = None):
        """
        Initialize encryption service
        
        Args:
            key: Optional 32-byte encryption key. If not provided, reads from ENCRYPTION_KEY env var.
                 If ENCRYPTION_KEY is not set, generates a key and stores it in .env file for reuse.
        """
        if key is None:
            key_str = os.getenv("ENCRYPTION_KEY")
            
            # If not set, try to load from .env file or generate new one
            if not key_str:
                key_str = self._get_or_create_encryption_key()
            
            # Try to decode as base64 first
            try:
                key = base64.b64decode(key_str)
                if len(key) != 32:
                    raise ValueError("ENCRYPTION_KEY must be 32 bytes when base64 decoded")
            except Exception:
                # If base64 decode fails, treat as raw string and pad/truncate to 32 bytes
                key_bytes = key_str.encode('utf-8')
                if len(key_bytes) < 32:
                    key = key_bytes.ljust(32, b'\0')
                elif len(key_bytes) > 32:
                    key = key_bytes[:32]
                else:
                    key = key_bytes
        
        if len(key) != 32:
            raise ValueError("Encryption key must be exactly 32 bytes for AES-256")
        
        self.key = key
        self.backend = default_backend()
    
    @staticmethod
    def _get_or_create_encryption_key() -> str:
        """
        Get encryption key from .env file or generate and save a new one
        
        Returns:
            Base64-encoded encryption key string
        """
        from pathlib import Path
        
        # Find .env file (look in current directory and parent directories)
        env_file = None
        current_dir = Path(__file__).parent
        search_dirs = [
            current_dir,  # api/app/utils/
            current_dir.parent,  # api/app/
            current_dir.parent.parent,  # api/
            Path.cwd(),  # Current working directory
        ]
        
        for search_dir in search_dirs:
            potential_env = search_dir / '.env'
            if potential_env.exists():
                env_file = potential_env
                break
        
        # If no .env found, use the api directory
        if env_file is None:
            # Try to find api directory
            api_dir = current_dir.parent.parent  # api/
            env_file = api_dir / '.env'
        
        # Read existing .env file if it exists
        env_vars = {}
        if env_file.exists():
            try:
                with open(env_file, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            env_vars[key.strip()] = value.strip().strip('"').strip("'")
            except Exception:
                pass  # If we can't read, continue to generate new key
        
        # Check if key already exists in .env
        if 'ENCRYPTION_KEY' in env_vars:
            return env_vars['ENCRYPTION_KEY']
        
        # Generate new key
        new_key = EncryptionService.generate_key()
        
        # Append to .env file
        try:
            # Ensure directory exists
            env_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(env_file, 'a', encoding='utf-8') as f:
                f.write(f'\n# Encryption key for credential storage (auto-generated)\n')
                f.write(f'ENCRYPTION_KEY={new_key}\n')
        except Exception:
            # If we can't write to .env, use a default development key
            # WARNING: This is not secure for production!
            import warnings
            warnings.warn(
                f"Could not write ENCRYPTION_KEY to .env file. "
                "Using default development key. Set ENCRYPTION_KEY in .env for production!",
                UserWarning
            )
            # Default development key (32 bytes base64 encoded)
            # This is NOT secure for production - only for development
            # Generated from: base64.b64encode(b"test-development-key-only-not-prod").decode()
            return "dGVzdC1kZXZlbG9wbWVudC1rZXktb25seS1ub3QtcHJvZA=="
        
        return new_key
    
    def encrypt(self, data: Dict[str, Any]) -> str:
        """
        Encrypt a dictionary to base64-encoded string
        
        Args:
            data: Dictionary to encrypt
            
        Returns:
            Base64-encoded encrypted string (nonce + ciphertext)
        """
        # Convert dictionary to JSON string
        plaintext = json.dumps(data, sort_keys=True).encode('utf-8')
        
        # Create AESGCM cipher
        aesgcm = AESGCM(self.key)
        
        # Generate 96-bit (12-byte) nonce
        nonce = os.urandom(12)
        
        # Encrypt with authenticated encryption
        ciphertext = aesgcm.encrypt(nonce, plaintext, None)
        
        # Combine nonce + ciphertext and encode to base64
        encrypted = nonce + ciphertext
        return base64.b64encode(encrypted).decode('utf-8')
    
    def decrypt(self, encrypted_data: str) -> Dict[str, Any]:
        """
        Decrypt base64-encoded string to dictionary
        
        Args:
            encrypted_data: Base64-encoded encrypted string
            
        Returns:
            Decrypted dictionary
            
        Raises:
            ValueError: If decryption fails (authentication error, invalid format, etc.)
        """
        try:
            # Decode from base64
            encrypted = base64.b64decode(encrypted_data)
            
            # Extract nonce (first 12 bytes) and ciphertext (remaining bytes)
            if len(encrypted) < 13:
                raise ValueError("Invalid encrypted data format")
            
            nonce = encrypted[:12]
            ciphertext = encrypted[12:]
            
            # Create AESGCM cipher
            aesgcm = AESGCM(self.key)
            
            # Decrypt with authentication verification
            plaintext = aesgcm.decrypt(nonce, ciphertext, None)
            
            # Convert JSON string back to dictionary
            return json.loads(plaintext.decode('utf-8'))
        
        except Exception as e:
            raise ValueError(f"Decryption failed: {str(e)}")
    
    @staticmethod
    def generate_key() -> str:
        """
        Generate a random 32-byte key and return as base64-encoded string
        
        Returns:
            Base64-encoded 32-byte key
        """
        key = os.urandom(32)
        return base64.b64encode(key).decode('utf-8')
    
    def verify_reversibility(self, test_data: Optional[Dict[str, Any]] = None) -> bool:
        """
        Verify that encryption is reversible (encrypt -> decrypt works correctly)
        
        Args:
            test_data: Optional test data. If not provided, uses default test data
            
        Returns:
            True if encryption/decryption works correctly, False otherwise
        """
        if test_data is None:
            test_data = {"test": "data", "number": 123, "nested": {"key": "value"}}
        
        try:
            encrypted = self.encrypt(test_data)
            decrypted = self.decrypt(encrypted)
            
            # Compare original and decrypted data
            return decrypted == test_data
        except Exception:
            return False


# Singleton instance (lazy initialization)
_encryption_service: Optional[EncryptionService] = None
_encryption_key: Optional[bytes] = None


def get_encryption_service(key: Optional[bytes] = None) -> EncryptionService:
    """
    Get or create singleton encryption service instance
    This ensures the same encryption key is used globally across the application
    
    Args:
        key: Optional encryption key. If provided, uses this key instead of env var.
             Useful for testing or when you need a specific key.
    
    Returns:
        EncryptionService instance (singleton)
    """
    global _encryption_service, _encryption_key
    
    # If key is provided, use it and reset singleton
    if key is not None:
        _encryption_key = key
        _encryption_service = EncryptionService(key=key)
        return _encryption_service
    
    # If singleton exists and key hasn't changed, return it
    if _encryption_service is not None:
        return _encryption_service
    
    # Create new instance (will auto-generate key if needed)
    _encryption_service = EncryptionService()
    return _encryption_service


def reset_encryption_service():
    """
    Reset the singleton encryption service instance
    Useful for testing or when you need to reload with a new key
    """
    global _encryption_service, _encryption_key
    _encryption_service = None
    _encryption_key = None
