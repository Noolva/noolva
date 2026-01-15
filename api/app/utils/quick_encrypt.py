import base64
SECRET_KEY = "mysecretkey"
def encrypt(cls, text: str) -> str:
        encrypted_bytes = bytes([ord(char) ^ ord(cls.SECRET_KEY[i % len(cls.SECRET_KEY)]) for i, char in enumerate(text)])
        return base64.b64encode(encrypted_bytes).decode()
    
def decrypt(cls, encrypted_text: str) -> str:
        decoded_bytes = base64.b64decode(encrypted_text)
        return "".join([chr(byte ^ ord(cls.SECRET_KEY[i % len(cls.SECRET_KEY)])) for i, byte in enumerate(decoded_bytes)])
""" 
react
 static encrypt(text) {
    const key = this.SECRET_KEY;
    const encrypted = text
      .split("")
      .map((char, i) => char.charCodeAt(0) ^ key.charCodeAt(i % key.length));
    return btoa(String.fromCharCode(...encrypted));
  }

  static decrypt(encryptedText) {
    const key = this.SECRET_KEY;
    const decoded = atob(encryptedText)
      .split("")
      .map((char, i) => char.charCodeAt(0) ^ key.charCodeAt(i % key.length));
    return String.fromCharCode(...decoded);
  }
"""


""" 
   public static function encrypt($text) {
        $key = self::$SECRET_KEY;
        $encrypted = "";
        for ($i = 0; $i < strlen($text); $i++) {
            $encrypted .= chr(ord($text[$i]) ^ ord($key[$i % strlen($key)]));
        }
        return base64_encode($encrypted);
    }

    public static function decrypt($encryptedText) {
        $key = self::$SECRET_KEY;
        $decoded = base64_decode($encryptedText);
        $decrypted = "";
        for ($i = 0; $i < strlen($decoded); $i++) {
            $decrypted .= chr(ord($decoded[$i]) ^ ord($key[$i % strlen($key)]));
        }
        return $decrypted;
    }
"""