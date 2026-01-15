# Noolva SaaS API Documentation

This document outlines the API endpoints available in the Noolva SaaS platform.

**Base URL**: `http://<host>:<port>` (Default: `http://localhost:9001`)

## Authentication (`/auth`)

### 1. Standard Login
Authenticate a user using their credentials (username, email, or phone) and password.

*   **URL**: `/auth/login`
*   **Method**: `POST`
*   **Content-Type**: `application/json`
*   **Body**:
    ```json
    {
      "identifier": "karan@example.com",
      "password": "securepassword123"
    }
    ```
*   **Response (200 OK)**:
    ```json
    {
      "user": {
        "user_id": 1,
        "username": "karan@example.com",
        "user_type": "saas_admin",
        "is_super_admin": true
      },
      "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
    ```
*   **Errors**:
    *   `400 Bad Request`: Validation failure.
    *   `401 Unauthorized`: Invalid credentials or inactive account.

### 2. Google OAuth Login
Initiate the Google OAuth flow.

*   **URL**: `/auth/google`
*   **Method**: `GET`
*   **Description**: Redirects the browser to Google's OAuth consent screen.
*   **Query Params**: None.
*   **Response**: `307 Temporary Redirect` -> Google.

### 3. Google OAuth Callback
Handle the callback from Google after user consent.

*   **URL**: `/auth/google-callback`
*   **Method**: `GET`
*   **Description**: Processes the auth code and logs the user in if they exist in the system.
*   **Response (200 OK)**: Same as `/auth/login`.

### 4. Get Current User Context
Retrieve the authenticated user's profile and permissible menu structure.

*   **URL**: `/auth/me`
*   **Method**: `GET`
*   **Headers**: `Authorization: Bearer <access_token>`
*   **Response (200 OK)**:
    ```json
    {
      "message": "Context endpoint ready. Middleware required." 
    }
    ```
    *(Note: Full implementation pending middleware integration)*

### 5. Create or Update User (`/auth/create-user`)
Administrative endpoint to upsert users with secure password hashing.

*   **URL**: `/auth/create-user`
*   **Method**: `POST`
*   **Body**:
    ```json
    {
      "username": "newuser",
      "password": "plain_text_password_to_encrypt",
      "email": "user@example.com",
      "user_type": "admin"
    }
    ```
*   **Logic**:
    *   If `username` exists -> Updates fields (hashes new password if provided).
    *   If new -> Creates user with hashed password.
