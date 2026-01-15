from enum import Enum

class ErrorType(Enum):
    VALIDATION_ERROR = 1001, "Validation failed for input data.", "Ensure the input meets all validation rules."
    AUTHENTICATION_ERROR = 1002, "Invalid credentials provided.", "Check the username and password."
    AUTHORIZATION_ERROR = 1003, "User lacks permission.", "Request appropriate access rights."
    DATABASE_ERROR = 1004, "A generic database error occurred.", "Check database logs for details."
    DATABASE_CONNECTION_FAILED = 10041, "Database connection failed.", "Verify database server availability."
    DATABASE_QUERY_EXECUTION_FAILED = 10042, "Query execution failed.", "Check SQL syntax and constraints."
    DATABASE_DEADLOCK_DETECTED = 10043, "Deadlock detected in database.", "Optimize query execution order."
    DATABASE_TIMEOUT = 10044, "Database operation timed out.", "Optimize query or increase timeout settings."
    DATABASE_CONSTRAINT_VIOLATION = 10045, "Database constraint violation.", "Ensure data integrity rules are met."
    DATABASE_TRANSACTION_FAILED = 10046, "Transaction rollback occurred.", "Check for conflicting operations."
    SERVER_ERROR = 1005, "Internal server error.", "Check server logs for root cause."
    NETWORK_ERROR = 1006, "Network connectivity issue.", "Check internet connection and server availability."
    FILE_NOT_FOUND = 1007, "Requested file was not found.", "Verify file path and existence."
    CONFIG_ERROR = 1008, "Configuration issue detected.", "Ensure system configurations are correct."
    PAYMENT_FAILURE = 1009, "Payment transaction failed.", "Verify payment details and retry."
    DATA_INTEGRITY_ERROR = 1010, "Data integrity check failed.", "Ensure data consistency."
    NOT_FOUND = 1011, "Resource not found.", "Verify the resource identifier."
    ENCRYPTION_ERROR = 1012, "Encryption or decryption failed.", "Check encryption key and data format."
    UNKNOWN_ERROR = 1099, "An unknown error occurred.", "Investigate further for root cause."

    def __init__(self, code, description, solution):
        self.code = code
        self.description = description
        self.solution = solution

    def to_dict(self):
        return {
            "type": self.name,
            "code": self.code,
            "description": self.description,
            "solution": self.solution
        }
