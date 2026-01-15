import traceback
import json
from datetime import datetime, date
from decimal import Decimal

def json_serializer(obj):
    """JSON serializer for objects not serializable by default json code"""
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serializable")

class ERPError(Exception):
    """ERP error handling with structured JSON output."""
    def __init__(self, error, errorType, errorData=None, message=None):
        self.errorType = errorType
        self.original_error = error if isinstance(error, Exception) else Exception(str(error))
        self.original_message = str(self.original_error)
        self.errorData = errorData if isinstance(errorData, dict) else {}

        # Use custom message if provided, otherwise use default description
        self.custom_message = message if message else errorType.description

        # Extract traceback only if error is an exception
        tb = traceback.extract_tb(self.original_error.__traceback__) if hasattr(self.original_error, "__traceback__") else []

        # Capture only project-related traceback frames (exclude external libraries)
        self.traceback_info = [
            {"file": filename, "line": line, "function": func, "code": text}
            for filename, line, func, text in tb if "site-packages" not in filename and "/usr/lib/" not in filename
        ]

        # Preserve the natural execution order (first call to error)
        # Clean errorData to ensure JSON serializable (convert datetime, Decimal, etc.)
        cleaned_error_data = self._clean_for_json(self.errorData) if self.errorData else {}
        
        self.message = {
            "type": self.errorType.name,
            "code": self.errorType.code,
            "description": self.custom_message,
            "solution": self.errorType.solution,
            "details": {
                "originalError": self.original_message,
                "traceback": self.traceback_info,
                "additionalData": cleaned_error_data
            }
        }

    def _clean_for_json(self, obj):
        """Recursively clean objects to be JSON serializable."""
        if isinstance(obj, dict):
            return {k: self._clean_for_json(v) for k, v in obj.items()}
        elif isinstance(obj, (list, tuple)):
            return [self._clean_for_json(item) for item in obj]
        elif isinstance(obj, (datetime, date)):
            return obj.isoformat()
        elif isinstance(obj, Decimal):
            return float(obj)
        elif hasattr(obj, '__dict__'):
            return self._clean_for_json(obj.__dict__)
        else:
            return obj

    def to_dict(self):
        """Convert error details to a structured dictionary."""
        return self.message

    def to_json(self):
        """Convert error details to JSON format."""
        return json.dumps(self.to_dict(), indent=4)

    def __str__(self):
        return self.to_json()
