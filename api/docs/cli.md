# Noolva ERP CLI Documentation

The Noolva ERP CLI provides a command-line interface for managing the ERP system, including server management, authentication, database setup, and system administration.

**Version**: 1.0.0

## Table of Contents

- [Installation & Setup](#installation--setup)
- [Authentication Commands](#authentication-commands)
- [Server Management](#server-management)
- [Database Setup](#database-setup)
- [System Administration](#system-administration)
- [System Information](#system-information)
- [Examples](#examples)

---

## Installation & Setup

### Prerequisites

- Python 3.9+
- PostgreSQL database
- Environment variables configured (see [validate_env](#validate-env))

### Running CLI Commands

All CLI commands are executed using:

```bash
python cli.py <command> [options]
```

Or from the `api/app` directory:

```bash
cd api/app
python cli.py <command> [options]
```

---

## Authentication Commands

### Login

Authenticate with the system and save your access token for subsequent commands.

**Command**: `login`

**Options**:
- `--username, -u`: Your username (will prompt if not provided)
- `--password, -p`: Your password (will prompt if not provided, hidden input)

**Examples**:

```bash
# Interactive login (will prompt for username and password)
python cli.py login

# Login with username provided
python cli.py login --username admin

# Login with both username and password
python cli.py login --username admin --password mypassword123
```

**Output**:
```
Login successful!
User: admin
Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

The token is automatically saved to `~/.fastapi_erp_token` for use in authenticated commands.

**Error Handling**:
- If login fails, you'll see: `Login failed: [error message]`
- Invalid credentials will display an appropriate error message

---

### Logout

Remove the saved authentication token from your system.

**Command**: `logout`

**Examples**:

```bash
# Logout (removes saved token)
python cli.py logout
```

**Output**:
```
Logged out.
```

If already logged out:
```
Already logged out.
```

---

## Server Management

### Run Server

Start the FastAPI development server with auto-reload enabled.

**Command**: `runserver`

**Options**:
- `--host, -h`: Host to bind to (default: `0.0.0.0`)
- `--port, -p`: Port to bind to (default: from `APPLICATION_PORT` env var or `9001`)

**Examples**:

```bash
# Start server with default settings
python cli.py runserver

# Start server on specific host and port
python cli.py runserver --host 127.0.0.1 --port 8080

# Using short flags
python cli.py runserver -h localhost -p 3000
```

**Output**:
```
INFO:     Uvicorn running on http://0.0.0.0:9001 (Press CTRL+C to quit)
INFO:     Started reloader process [12345] using WatchFiles
INFO:     Started server process [12346]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

The server runs with auto-reload enabled, so code changes will automatically restart the server.

---

## Database Setup

### Setup

Initialize the database schema and create default admin user. This command:
1. Creates all database tables from the SQL schema
2. Creates a system user (if not exists)
3. Creates or updates the admin user

**Command**: `setup`

**Options**:
- `--admin, -a`: Admin username (default: `admin`)
- `--password, -p`: Admin password (will prompt if not provided)
- `--force, -f`: Force setup even if database is already initialized

**Examples**:

```bash
# Interactive setup (will prompt for admin password)
python cli.py setup

# Setup with admin username specified
python cli.py setup --admin myadmin

# Setup with admin username and password
python cli.py setup --admin myadmin --password securepass123

# Force setup (reinitialize even if already set up)
python cli.py setup --force
```

**Output** (First time setup):
```
Initializing database schema...
✅ Schema created successfully.
Creating system user...
✅ System user created.
Creating admin user 'admin'...
✅ Admin user 'admin' created.

✅ Setup completed successfully!
   Admin username: admin
   You can now login using: python cli.py login -u admin
```

**Output** (If database already initialized):
```
✅ Database already initialized.
Do you want to continue with user creation? [y/N]:
```

**Prerequisites**:
The following environment variables must be set:
- `POSTGRES_HOST`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DATABASE`
- `POSTGRES_PORT`

**Error Handling**:
- Missing environment variables will show an error listing what's required
- SQL execution errors will display detailed error messages
- If admin user already exists, you'll be prompted to update the password

---

### Validate Environment

Validate your `.env` file configuration and test database connectivity.

**Command**: `validate_env`

**Examples**:

```bash
# Validate environment and database connection
python cli.py validate_env
```

**Output**:
```
Validating environment configuration...

✅ POSTGRES_HOST (PostgreSQL host): localhost
✅ POSTGRES_USER (PostgreSQL user): postgres
✅ POSTGRES_PASSWORD (PostgreSQL password): ***
✅ POSTGRES_DATABASE (PostgreSQL database name): noolva_db
✅ POSTGRES_PORT (PostgreSQL port): 5432
✅ JWT_SECRET (JWT secret key): ***

ℹ️  APPLICATION_PORT (Application server port): 9001
ℹ️  ENV (Environment (development/production)): development
⚠️  SESSION_SECRET (Session secret key): Not set (using default)

✅ Environment variables validated.

Testing database connection...
✅ Database connection successful.
   PostgreSQL 15.3 on x86_64-apple-darwin20.6.0
```

**What it checks**:
- **Required variables**: All must be set
  - `POSTGRES_HOST`
  - `POSTGRES_USER`
  - `POSTGRES_PASSWORD`
  - `POSTGRES_DATABASE`
  - `POSTGRES_PORT`
  - `JWT_SECRET`

- **Optional variables**: Recommended but not required
  - `APPLICATION_PORT`
  - `ENV`
  - `SESSION_SECRET`

- **Database connection**: Tests actual connectivity to PostgreSQL

**Error Handling**:
- Missing required variables will list what's missing and exit with error code 1
- Database connection failures will show the error message

---

## System Administration

### Reset Password

Reset a user's password. Requires root password authentication.

**Command**: `resetpass`

**Examples**:

```bash
# Reset password (will prompt for root password, username, and new password)
python cli.py resetpass
```

**Interactive Flow**:
```
Root password: [hidden input]
Username to reset password for: john_doe
New password: [hidden input]
Confirm password: [hidden input]
✅ Password reset successful for user: john_doe
```

**Prerequisites**:
- `APP_ROOT_PASSWORD` environment variable must be set
- User must exist in the database

**Error Handling**:
- Incorrect root password will exit with error
- Non-existent user will show error message
- Password mismatch will prompt again

---

### Reset Admin Password

Reset an admin user's password with additional validation. Requires root password authentication.

**Command**: `reset_admin_password`

**Options**:
- `--username, -u`: Admin username (default: `admin`)

**Examples**:

```bash
# Reset admin password (default username: admin)
python cli.py reset_admin_password

# Reset password for specific admin user
python cli.py reset_admin_password --username superadmin
```

**Interactive Flow**:
```
Root password: [hidden input]
New password: [hidden input]
Confirm password: [hidden input]
✅ Password reset successful for admin user: admin
```

**Validation**:
- Checks if user exists
- Warns if user is not of type `saas_admin` or `system`
- Prompts for confirmation if user type doesn't match

**Prerequisites**:
- `APP_ROOT_PASSWORD` environment variable must be set
- Admin user must exist in the database

**Error Handling**:
- Incorrect root password will exit with error
- Non-existent user will show error message
- Password mismatch will prompt again
- Non-admin users will require confirmation to proceed

---

## System Information

### Status

Check the current status of the ERP system, including database statistics.

**Command**: `status`

**Examples**:

```bash
# Check system status
python cli.py status
```

**Output** (System initialized):
```
Noolva ERP System Status

Version: 1.0.0
Environment: development

Database Statistics:
  Users: 5
  Tenants: 2
  Companies: 3
  Apps: 1
```

**Output** (Database not initialized):
```
Noolva ERP System Status

Version: 1.0.0
Environment: development

⚠️  Database not fully initialized.
   Run: python cli.py setup
```

**What it shows**:
- System version
- Current environment
- Database statistics:
  - User count
  - Tenant count
  - Company count
  - App count
- Database initialization status

**Error Handling**:
- Database connection errors will show appropriate error messages
- Uninitialized database will suggest running setup

---

### Version

Display version information about the CLI and Python environment.

**Command**: `version`

**Examples**:

```bash
# Show version information
python cli.py version
```

**Output**:
```
Noolva ERP version 1.0.0
Python version: 3.9.7
Environment: development
```

---

### Products

Fetch products from the API (requires authentication).

**Command**: `products`

**Examples**:

```bash
# Fetch products (requires login first)
python cli.py products
```

**Prerequisites**:
- Must be logged in (token saved from `login` command)
- User must have `saas-admin` or `saas-employees` role

**Output**:
```
✔ Welcome admin! Fetching products...
```

**Error Handling**:
- If not logged in: `Not logged in please login using : python cli.py login`
- If token is invalid/expired: `Authentication failed: [error]` with suggestion to login again

---

## Examples

### Complete Setup Workflow

```bash
# 1. Validate environment
python cli.py validate_env

# 2. Initialize database and create admin user
python cli.py setup --admin admin

# 3. Login with admin credentials
python cli.py login --username admin

# 4. Check system status
python cli.py status

# 5. Start the server
python cli.py runserver
```

### Daily Development Workflow

```bash
# Start development server
python cli.py runserver --host localhost --port 9001

# In another terminal, check status
python cli.py status

# Fetch products (if logged in)
python cli.py products
```

### Password Management

```bash
# Reset a regular user's password
python cli.py resetpass
# Follow prompts: root password → username → new password

# Reset admin password
python cli.py reset_admin_password --username admin
# Follow prompts: root password → new password → confirm
```

### Troubleshooting

```bash
# Check if environment is properly configured
python cli.py validate_env

# Check system status and database statistics
python cli.py status

# Verify version information
python cli.py version
```

---

## Environment Variables

### Required Variables

These must be set in your `.env` file:

```bash
# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_DATABASE=noolva_db
POSTGRES_PORT=5432

# Security
JWT_SECRET=your_jwt_secret_key_here

# Root Password (for password reset commands)
APP_ROOT_PASSWORD=your_root_password
```

### Optional Variables

```bash
# Server Configuration
APPLICATION_PORT=9001

# Environment
ENV=development

# Session Security
SESSION_SECRET=your_session_secret
```

---

## Token Storage

Authentication tokens are stored in:
- **Location**: `~/.fastapi_erp_token`
- **Format**: Plain text JWT token
- **Permissions**: User read/write only (600)

The token is automatically used by authenticated commands like `products`.

---

## Error Codes

The CLI uses standard exit codes:
- `0`: Success
- `1`: Error (authentication failure, validation error, etc.)

---

## Tips & Best Practices

1. **Always validate environment first**: Run `python cli.py validate_env` before setup
2. **Use interactive prompts**: Most commands will prompt for missing information
3. **Secure your root password**: Keep `APP_ROOT_PASSWORD` secure and never commit it
4. **Check status regularly**: Use `status` command to monitor system health
5. **Logout when done**: Use `logout` to remove tokens from your system

---

## Troubleshooting

### "Not logged in" errors
- Run `python cli.py login` first
- Check if `~/.fastapi_erp_token` exists and is readable

### Database connection errors
- Verify PostgreSQL is running
- Check environment variables with `validate_env`
- Ensure database exists and user has proper permissions

### Setup fails
- Ensure all required environment variables are set
- Check database user has CREATE TABLE permissions
- Verify SQL file exists at expected location
- Use `--force` flag carefully (will reinitialize database)

### Token authentication fails
- Token may have expired - run `login` again
- Check if user still exists and is active
- Verify JWT_SECRET matches between CLI and API

---

## Support

For issues or questions:
1. Check system status: `python cli.py status`
2. Validate environment: `python cli.py validate_env`
3. Review error messages for specific guidance
4. Check database connectivity and permissions
