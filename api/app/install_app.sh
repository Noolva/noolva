#!/bin/bash
# Cross-Platform Installation Script for Noolva ERP API
# Supports: macOS, Ubuntu/Linux, Windows (via WSL/Git Bash)
# Requires: Python 3.9 (strictly)
# Note: Uses remote PostgreSQL database - does not install PostgreSQL locally

set -e

# Initialize variables
INSTALL_SUCCESS=false
OS_TYPE=""
PYTHON_CMD=""
PIP_CMD=""
OPENSSL_LIB=""
OPENSSL_INCLUDE=""
LIBPQ_LIB=""
LIBPQ_INCLUDE=""

# Colors for output (if supported)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        echo -e "${BLUE}🖥️  Detected: macOS${NC}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        echo -e "${BLUE}🖥️  Detected: Linux/Ubuntu${NC}"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS_TYPE="windows"
        echo -e "${BLUE}🖥️  Detected: Windows (Git Bash/Cygwin)${NC}"
    else
        echo -e "${RED}❌ Unsupported operating system: $OSTYPE${NC}"
        exit 1
    fi
}

# Verify Python 3.9 is installed
verify_python() {
    echo ""
    echo -e "${BLUE}🐍 Checking Python version...${NC}"
    
    # Try different Python commands
    for cmd in python3.9 python3 python; do
        if command -v $cmd &> /dev/null; then
            PYTHON_VERSION=$($cmd --version 2>&1 | awk '{print $2}')
            PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
            PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
            
            if [ "$PYTHON_MAJOR" == "3" ] && [ "$PYTHON_MINOR" == "9" ]; then
                PYTHON_CMD=$cmd
                PIP_CMD="${cmd} -m pip"
                echo -e "${GREEN}✅ Found Python ${PYTHON_VERSION} at: $(which $cmd)${NC}"
                return 0
            fi
        fi
    done
    
    echo -e "${RED}❌ Python 3.9 is required but not found${NC}"
    echo ""
    echo "Please install Python 3.9:"
    case $OS_TYPE in
        macos)
            echo "  brew install python@3.9"
            echo "  or download from https://www.python.org/downloads/"
            ;;
        linux)
            echo "  sudo apt-get update"
            echo "  sudo apt-get install python3.9 python3.9-venv python3.9-dev"
            ;;
        windows)
            echo "  Download from https://www.python.org/downloads/"
            echo "  Make sure to check 'Add Python to PATH' during installation"
            ;;
    esac
    exit 1
}

# Setup macOS dependencies
setup_macos() {
    echo ""
    echo -e "${BLUE}🍎 Setting up macOS dependencies...${NC}"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}❌ Homebrew is not installed.${NC}"
        echo "   Please install it first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    echo -e "${GREEN}✅ Homebrew found${NC}"
    
    # Install/check OpenSSL
    if ! brew list openssl@3 &> /dev/null && ! brew list openssl &> /dev/null; then
        echo "   Installing OpenSSL..."
        brew install openssl
    else
        echo -e "${GREEN}   ✅ OpenSSL already installed${NC}"
    fi
    
    # Install/check libpq
    if ! brew list libpq &> /dev/null; then
        echo "   Installing libpq..."
        brew install libpq
    else
        echo -e "${GREEN}   ✅ libpq already installed${NC}"
    fi
    
    # Get Homebrew prefix
    BREW_PREFIX=$(brew --prefix)
    
    # Use brew --prefix to get exact paths (most reliable method)
    OPENSSL_PREFIX=$(brew --prefix openssl@3 2>/dev/null || brew --prefix openssl 2>/dev/null || echo "")
    LIBPQ_PREFIX=$(brew --prefix libpq 2>/dev/null || echo "")
    
    # If brew --prefix doesn't work, try common locations
    if [ -z "$OPENSSL_PREFIX" ]; then
        for openssl_path in "${BREW_PREFIX}/opt/openssl@3" "${BREW_PREFIX}/opt/openssl"; do
            if [ -d "${openssl_path}/lib" ]; then
                OPENSSL_PREFIX="$openssl_path"
                break
            fi
        done
    fi
    
    if [ -z "$LIBPQ_PREFIX" ]; then
        if [ -d "${BREW_PREFIX}/opt/libpq/lib" ]; then
            LIBPQ_PREFIX="${BREW_PREFIX}/opt/libpq"
        fi
    fi
    
    # Set library paths
    if [ -n "$OPENSSL_PREFIX" ] && [ -d "${OPENSSL_PREFIX}/lib" ]; then
        OPENSSL_LIB="${OPENSSL_PREFIX}/lib"
        OPENSSL_INCLUDE="${OPENSSL_PREFIX}/include"
        echo "   ✅ Found OpenSSL at: $OPENSSL_LIB"
    fi
    
    if [ -n "$LIBPQ_PREFIX" ] && [ -d "${LIBPQ_PREFIX}/lib" ]; then
        LIBPQ_LIB="${LIBPQ_PREFIX}/lib"
        LIBPQ_INCLUDE="${LIBPQ_PREFIX}/include"
        echo "   ✅ Found libpq at: $LIBPQ_LIB"
    fi
    
    if [ -z "$OPENSSL_LIB" ] || [ -z "$LIBPQ_LIB" ]; then
        echo -e "${RED}❌ Could not find OpenSSL or libpq libraries${NC}"
        if [ -z "$OPENSSL_LIB" ]; then
            echo "   OpenSSL not found. Try: brew install openssl"
        fi
        if [ -z "$LIBPQ_LIB" ]; then
            echo "   libpq not found. Try: brew install libpq"
        fi
        exit 1
    fi
    
    # Set environment variables
    export LDFLAGS="-L${OPENSSL_LIB} -L${LIBPQ_LIB}"
    export CPPFLAGS="-I${OPENSSL_INCLUDE} -I${LIBPQ_INCLUDE}"
    export PKG_CONFIG_PATH="${OPENSSL_LIB}/pkgconfig:${LIBPQ_LIB}/pkgconfig"
    
    echo -e "${GREEN}   ✅ Library paths configured${NC}"
    echo "   OpenSSL: $OPENSSL_LIB"
    echo "   libpq: $LIBPQ_LIB"
}

# Setup Linux/Ubuntu dependencies
setup_linux() {
    echo ""
    echo -e "${BLUE}🐧 Setting up Linux/Ubuntu dependencies...${NC}"
    
    # Check if running as root (for apt-get)
    if [ "$EUID" -eq 0 ]; then
        SUDO=""
    else
        SUDO="sudo"
        echo "   Note: Some commands may require sudo privileges"
    fi
    
    # Update package list
    echo "   Updating package list..."
    $SUDO apt-get update -qq || true
    
    # Install build dependencies
    echo "   Installing build dependencies..."
    $SUDO apt-get install -y \
        build-essential \
        libpq-dev \
        python3.9-dev \
        pkg-config \
        libssl-dev \
        || {
            echo -e "${YELLOW}⚠️  Some packages may have failed to install${NC}"
            echo "   You may need to install manually:"
            echo "   sudo apt-get install build-essential libpq-dev python3.9-dev pkg-config libssl-dev"
        }
    
    echo -e "${GREEN}   ✅ System dependencies installed${NC}"
}

# Setup Windows dependencies (via WSL/Git Bash)
setup_windows() {
    echo ""
    echo -e "${BLUE}🪟 Setting up Windows (Git Bash/Cygwin) dependencies...${NC}"
    echo -e "${YELLOW}⚠️  Windows native installation is limited${NC}"
    echo ""
    echo "For best results on Windows, consider:"
    echo "  1. Using WSL (Windows Subsystem for Linux)"
    echo "  2. Using a pre-built wheel for psycopg2-binary"
    echo ""
    
    # Check if we're in WSL
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        echo -e "${GREEN}✅ Detected WSL - using Linux setup${NC}"
        setup_linux
        return
    fi
    
    # For Git Bash/Cygwin, try to use system libraries if available
    echo "   Attempting to use system libraries..."
    # Windows typically has OpenSSL in system paths or via Git for Windows
}

# Check virtual environment
check_venv() {
    if [[ "$VIRTUAL_ENV" != "" ]]; then
        echo -e "${GREEN}✅ Virtual environment detected: $VIRTUAL_ENV${NC}"
    else
        echo -e "${YELLOW}⚠️  No virtual environment detected.${NC}"
        echo "   It's strongly recommended to use a virtual environment."
        read -p "   Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "   Please create and activate a virtual environment first:"
            echo "   ${PYTHON_CMD} -m venv venv"
            if [ "$OS_TYPE" == "windows" ]; then
                echo "   source venv/Scripts/activate  # Git Bash"
                echo "   or venv\\Scripts\\activate.bat  # CMD"
            else
                echo "   source venv/bin/activate"
            fi
            exit 1
        fi
    fi
}

# Install Python dependencies
install_dependencies() {
    echo ""
    echo -e "${BLUE}📥 Upgrading pip...${NC}"
    $PIP_CMD install --upgrade pip --quiet
    
    echo ""
    echo -e "${BLUE}🧪 Testing environment setup for psycopg2-binary...${NC}"
    
    # Verify library paths on macOS
    if [ "$OS_TYPE" == "macos" ]; then
        # Verify the paths we found earlier still exist
        if [ -n "$OPENSSL_LIB" ] && [ -d "$OPENSSL_LIB" ] && [ -n "$LIBPQ_LIB" ] && [ -d "$LIBPQ_LIB" ]; then
            echo -e "${GREEN}   ✅ Library paths verified${NC}"
            echo "      OpenSSL: $OPENSSL_LIB"
            echo "      libpq: $LIBPQ_LIB"
        else
            echo -e "${RED}❌ Library directories not found${NC}"
            if [ -z "$OPENSSL_LIB" ] || [ ! -d "$OPENSSL_LIB" ]; then
                echo "   OpenSSL not found. Try: brew install openssl"
            fi
            if [ -z "$LIBPQ_LIB" ] || [ ! -d "$LIBPQ_LIB" ]; then
                echo "   libpq not found. Try: brew install libpq"
            fi
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${BLUE}📦 Installing Python dependencies...${NC}"
    echo "   This may take a few minutes..."
    
    # Try to install psycopg2-binary
    echo "   Attempting to install psycopg2-binary..."
    set +e  # Temporarily disable exit on error
    $PIP_CMD install psycopg2-binary==2.9.10
    PIP_EXIT_CODE=$?
    set -e  # Re-enable exit on error
    
    if [ $PIP_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}   ✅ psycopg2-binary installed successfully${NC}"
        echo ""
        echo "📦 Installing remaining dependencies..."
        set +e
        # Ensure bcrypt is the correct version (3.2.2) for passlib 1.7.4 compatibility
        echo "   Ensuring bcrypt compatibility (3.2.2)..."
        $PIP_CMD uninstall -y bcrypt 2>/dev/null || true
        $PIP_CMD install bcrypt==3.2.2
        # Install all dependencies
        $PIP_CMD install -r requirements.txt
        REQUIREMENTS_EXIT_CODE=$?
        set -e
        
        if [ $REQUIREMENTS_EXIT_CODE -eq 0 ]; then
            INSTALL_SUCCESS=true
        else
            echo -e "${YELLOW}   ⚠️  Some dependencies failed to install${NC}"
            INSTALL_SUCCESS=false
        fi
    else
        echo ""
        echo -e "${RED}   ❌ psycopg2-binary installation failed${NC}"
        echo ""
        echo "   Troubleshooting steps:"
        
        case $OS_TYPE in
            macos)
                echo "   1. Verify environment variables:"
                echo "      echo \$LDFLAGS"
                echo "      echo \$CPPFLAGS"
                echo "   2. Try installing manually:"
                echo "      export LDFLAGS=\"-L\$(brew --prefix openssl)/lib -L\$(brew --prefix libpq)/lib\""
                echo "      export CPPFLAGS=\"-I\$(brew --prefix openssl)/include -I\$(brew --prefix libpq)/include\""
                echo "      pip install psycopg2-binary==2.9.10"
                echo "   3. Install Xcode Command Line Tools:"
                echo "      xcode-select --install"
                ;;
            linux)
                echo "   1. Install missing build dependencies:"
                echo "      sudo apt-get install build-essential libpq-dev python3.9-dev libssl-dev"
                echo "   2. Try installing manually:"
                echo "      pip install psycopg2-binary==2.9.10"
                ;;
            windows)
                echo "   1. Consider using WSL for better compatibility"
                echo "   2. Or try installing pre-built wheel:"
                echo "      pip install --only-binary :all: psycopg2-binary==2.9.10"
                ;;
        esac
        echo ""
        INSTALL_SUCCESS=false
    fi
}

# Main execution
main() {
    echo "🚀 Noolva ERP API - Cross-Platform Installation"
    echo "================================================"
    echo ""
    
    # Detect OS
    detect_os
    
    # Verify Python 3.9
    verify_python
    
    # Setup OS-specific dependencies
    case $OS_TYPE in
        macos)
            setup_macos
            ;;
        linux)
            setup_linux
            ;;
        windows)
            setup_windows
            ;;
    esac
    
    # Check virtual environment
    check_venv
    
    # Install dependencies
    install_dependencies
    
    # Final message
    if [ "$INSTALL_SUCCESS" = true ]; then
        echo ""
        echo -e "${GREEN}✅ Installation complete!${NC}"
        echo ""
        echo "📋 Next steps:"
        echo "   1. Configure your .env file with remote database credentials"
        echo "   2. Validate environment: ${PYTHON_CMD} cli.py validate_env"
        echo "   3. Setup database: ${PYTHON_CMD} cli.py setup"
        echo "   4. Start server: ${PYTHON_CMD} cli.py runserver"
        echo ""
        
        if [ "$OS_TYPE" == "macos" ]; then
            echo "💡 Note: If you close this terminal, you may need to set environment"
            echo "   variables again. Add these to your ~/.zshrc or ~/.bash_profile:"
            echo ""
            echo "   export LDFLAGS=\"-L\$(brew --prefix openssl)/lib -L\$(brew --prefix libpq)/lib\""
            echo "   export CPPFLAGS=\"-I\$(brew --prefix openssl)/include -I\$(brew --prefix libpq)/include\""
            echo ""
        fi
    else
        echo ""
        echo -e "${RED}❌ Installation incomplete. Please fix the issues above and try again.${NC}"
        exit 1
    fi
}

# Run main function
main
