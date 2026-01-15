# Installation Guide

This guide covers installation of the Noolva ERP API dependencies for macOS, Ubuntu/Linux, and Windows.

## Quick Start

**For macOS/Linux (Bash):**
```bash
cd api/app
chmod +x install_app.sh
./install_app.sh
```

**For Windows (PowerShell):**
```powershell
cd api/app
.\install_app.ps1
```

The installation script will:
- ✅ Strictly verify Python 3.9 is installed
- ✅ Detect your operating system
- ✅ Install required system dependencies
- ✅ Set up environment variables (macOS)
- ✅ Install all Python packages

## Prerequisites

- **Python 3.9** (strictly required - script will verify)
- PostgreSQL database (running remotely - not installed locally)
- pip (Python package manager)

### System Requirements by Platform

**macOS:**
- Homebrew (will be checked/installed by script)
- OpenSSL and libpq (installed automatically by script)

**Ubuntu/Linux:**
- Build tools and development libraries (installed automatically by script)
- May require sudo privileges

**Windows:**
- Visual C++ Build Tools (for compiling packages)
- Or use WSL (Windows Subsystem for Linux) for best compatibility

## Installation Steps

### Automated Installation (Recommended)

The easiest way to install is using the provided installation script:

**macOS/Linux:**
```bash
cd api/app
chmod +x install_app.sh
./install_app.sh
```

**Windows (PowerShell):**
```powershell
cd api/app
.\install_app.ps1
```

The script will:
- Verify Python 3.9 is installed
- Detect your operating system
- Install system dependencies automatically
- Set up environment variables (macOS)
- Install all Python packages

### Manual Installation

If you prefer to install manually:

#### 1. Create Virtual Environment (Recommended)

```bash
cd api/app
python3.9 -m venv venv
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate  # On Windows
```

#### 2. Install Dependencies

#### Standard Installation (Linux/Windows)

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

#### macOS Installation (with psycopg2-binary fix)

If you encounter OpenSSL/library errors with `psycopg2-binary`, use these steps:

```bash
# Set environment variables for OpenSSL and libpq
export LDFLAGS="-L$(brew --prefix openssl)/lib -L$(brew --prefix libpq)/lib"
export CPPFLAGS="-I$(brew --prefix openssl)/include -I$(brew --prefix libpq)/include"
export PKG_CONFIG_PATH="$(brew --prefix openssl)/lib/pkgconfig:$(brew --prefix libpq)/lib/pkgconfig"

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

**Alternative: Use psycopg2 (non-binary)**

If `psycopg2-binary` continues to fail, you can use the non-binary version:

```bash
# Install PostgreSQL via Homebrew (includes libpq)
brew install postgresql

# Remove psycopg2-binary from requirements and use psycopg2 instead
pip install psycopg2==2.9.10
```

To make this permanent, you can modify `requirements.txt`:
- Replace `psycopg2-binary==2.9.10` with `psycopg2==2.9.10`

### 3. Verify Installation

```bash
# Check Python version
python --version  # Should be 3.9+

# Check pip version
pip --version

# Verify key packages
python -c "import fastapi; print(fastapi.__version__)"
python -c "import psycopg2; print(psycopg2.__version__)"
python -c "import asyncpg; print(asyncpg.__version__)"
```

## Troubleshooting

### psycopg2-binary Installation Fails on macOS

**Error**: `ld: library 'ssl' not found` or `clang: error: linker command failed`

**Solution 1**: Set environment variables (recommended)
```bash
export LDFLAGS="-L$(brew --prefix openssl)/lib -L$(brew --prefix libpq)/lib"
export CPPFLAGS="-I$(brew --prefix openssl)/include -I$(brew --prefix libpq)/include"
pip install psycopg2-binary==2.9.10
```

**Solution 2**: Use psycopg2 (non-binary)
```bash
brew install postgresql
pip install psycopg2==2.9.10
```

**Solution 3**: Install pre-compiled wheel (if available)
```bash
pip install --only-binary :all: psycopg2-binary==2.9.10
```

### Other Common Issues

#### "Command 'clang' failed"
- Install Xcode Command Line Tools: `xcode-select --install`
- Or install Xcode from the App Store

#### "Python.h: No such file or directory"
- Install Python development headers: `brew install python@3.9`

#### "Package not found" errors
- Upgrade pip: `pip install --upgrade pip`
- Clear pip cache: `pip cache purge`
- Try installing without cache: `pip install --no-cache-dir -r requirements.txt`

#### Virtual environment issues
- Ensure you're in the virtual environment: `which python` should point to `venv/bin/python`
- Recreate virtual environment if corrupted: `rm -rf venv && python3 -m venv venv`

## Environment Configuration

After installation, configure your environment:

1. Copy `.env.example` to `.env` (if available)
2. Set required environment variables (see [CLI Documentation](./cli.md#environment-variables))
3. Validate configuration: `python cli.py validate_env`

## Next Steps

1. **Validate Environment**: `python cli.py validate_env`
2. **Setup Database**: `python cli.py setup`
3. **Start Server**: `python cli.py runserver`

For more details, see the [CLI Documentation](./cli.md).
