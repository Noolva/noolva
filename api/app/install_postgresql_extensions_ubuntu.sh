#!/bin/bash
# Install PostgreSQL Extensions for Noolva ERP Database
# This script installs all required PostgreSQL extensions on Ubuntu
# Requires: PostgreSQL 16 (strictly)
# Run this script on your PostgreSQL server (requires sudo)

set -e

REQUIRED_PG_VERSION="16"
PG_VERSION=""
INSTALLED_EXTENSIONS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔧 PostgreSQL Extensions Installation for Noolva ERP"
echo "====================================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run with sudo privileges${NC}"
    echo "   Usage: sudo ./install_postgresql_extensions_ubuntu.sh"
    exit 1
fi

# Function to detect PostgreSQL version
detect_postgresql_version() {
    echo -e "${BLUE}🔍 Detecting PostgreSQL version...${NC}"
    
    # Try multiple methods to detect version
    if command -v psql &> /dev/null; then
        PG_VERSION=$(psql --version 2>&1 | grep -oE '[0-9]+' | head -1)
    fi
    
    # If still not found, try pg_config
    if [ -z "$PG_VERSION" ] && command -v pg_config &> /dev/null; then
        PG_VERSION=$(pg_config --version | grep -oE '[0-9]+' | head -1)
    fi
    
    # Try to find from installed packages
    if [ -z "$PG_VERSION" ]; then
        PG_VERSION=$(dpkg -l | grep -E '^ii.*postgresql-[0-9]+' | head -1 | grep -oE 'postgresql-[0-9]+' | grep -oE '[0-9]+' | head -1)
    fi
    
    if [ -z "$PG_VERSION" ]; then
        echo -e "${RED}❌ Could not detect PostgreSQL version${NC}"
        echo "   Please ensure PostgreSQL is installed and psql is in PATH"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Detected PostgreSQL version: ${PG_VERSION}${NC}"
    
    # Strictly validate version
    if [ "$PG_VERSION" != "$REQUIRED_PG_VERSION" ]; then
        echo -e "${RED}❌ PostgreSQL version ${REQUIRED_PG_VERSION} is required${NC}"
        echo -e "${RED}   Detected version: ${PG_VERSION}${NC}"
        echo ""
        echo "   This script is strictly configured for PostgreSQL ${REQUIRED_PG_VERSION}"
        echo "   Please install PostgreSQL ${REQUIRED_PG_VERSION} or update the script"
        exit 1
    fi
    
    echo -e "${GREEN}✅ PostgreSQL version ${PG_VERSION} matches requirement${NC}"
}

# Function to check if extension is available
check_extension_available() {
    local ext_name=$1
    sudo -u postgres psql -tAc "SELECT 1 FROM pg_available_extensions WHERE name = '$ext_name'" postgres 2>/dev/null | grep -q 1
}

# Function to install built-in extension
install_builtin_extension() {
    local ext_name=$1
    local ext_desc=$2
    
    echo ""
    echo -e "${BLUE}📦 Checking ${ext_name} (${ext_desc})...${NC}"
    
    if check_extension_available "$ext_name"; then
        echo -e "${GREEN}   ✅ ${ext_name} is available${NC}"
        INSTALLED_EXTENSIONS+=("$ext_name")
        return 0
    else
        echo -e "${YELLOW}   ⚠️  ${ext_name} is not available${NC}"
        echo "   This extension should be included with PostgreSQL ${PG_VERSION}"
        echo "   You may need to install the contrib package:"
        echo "   sudo apt-get install postgresql-contrib-${PG_VERSION}"
        return 1
    fi
}

# Function to install pgvector
install_pgvector() {
    echo ""
    echo -e "${BLUE}📦 Installing pgvector extension...${NC}"
    
    # Check if already installed
    if check_extension_available "vector"; then
        echo -e "${GREEN}   ✅ pgvector is already available${NC}"
        INSTALLED_EXTENSIONS+=("vector")
        return 0
    fi
    
    echo "   Installing build dependencies..."
    apt-get update -qq
    apt-get install -y \
        build-essential \
        postgresql-server-dev-${PG_VERSION} \
        git \
        || {
            echo -e "${RED}   ❌ Failed to install dependencies${NC}"
            return 1
        }
    
    echo "   Cloning pgvector repository..."
    cd /tmp
    if [ -d "pgvector" ]; then
        rm -rf pgvector
    fi
    
    # Use latest stable version
    git clone --branch v0.7.2 https://github.com/pgvector/pgvector.git
    cd pgvector
    
    echo "   Building pgvector..."
    make || {
        echo -e "${RED}   ❌ Failed to build pgvector${NC}"
        cd /
        rm -rf /tmp/pgvector
        return 1
    }
    
    echo "   Installing pgvector..."
    make install || {
        echo -e "${RED}   ❌ Failed to install pgvector${NC}"
        cd /
        rm -rf /tmp/pgvector
        return 1
    }
    
    echo -e "${GREEN}   ✅ pgvector installed successfully${NC}"
    cd /
    rm -rf /tmp/pgvector
    INSTALLED_EXTENSIONS+=("vector")
    return 0
}

# Main execution
main() {
    # Detect PostgreSQL version (strictly)
    detect_postgresql_version
    
    echo ""
    echo -e "${BLUE}📋 Required extensions for Noolva ERP:${NC}"
    echo "   1. pgcrypto - Cryptographic functions (usually built-in)"
    echo "   2. uuid-ossp - UUID generation (usually built-in)"
    echo "   3. vector - Vector similarity search (pgvector - needs installation)"
    echo ""
    
    # Check and install contrib package if needed
    if ! dpkg -l | grep -q "postgresql-contrib-${PG_VERSION}"; then
        echo -e "${YELLOW}⚠️  postgresql-contrib package not found${NC}"
        echo "   Installing postgresql-contrib-${PG_VERSION}..."
        apt-get update -qq
        apt-get install -y postgresql-contrib-${PG_VERSION} || {
            echo -e "${RED}❌ Failed to install postgresql-contrib${NC}"
            exit 1
        }
        echo -e "${GREEN}✅ postgresql-contrib installed${NC}"
    else
        echo -e "${GREEN}✅ postgresql-contrib package is installed${NC}"
    fi
    
    # Check built-in extensions
    echo ""
    echo -e "${BLUE}🔍 Checking built-in extensions...${NC}"
    
    # pgcrypto
    if ! install_builtin_extension "pgcrypto" "Cryptographic functions"; then
        echo -e "${YELLOW}   Installing postgresql-contrib...${NC}"
        apt-get install -y postgresql-contrib-${PG_VERSION}
    fi
    
    # uuid-ossp
    install_builtin_extension "uuid-ossp" "UUID generation"
    
    # Install pgvector
    install_pgvector
    
    # Summary
    echo ""
    echo "====================================================="
    echo -e "${GREEN}✅ Installation Summary${NC}"
    echo "====================================================="
    echo ""
    echo "PostgreSQL version: ${PG_VERSION}"
    echo ""
    echo "Extensions status:"
    
    for ext in "${INSTALLED_EXTENSIONS[@]}"; do
        if check_extension_available "$ext"; then
            echo -e "  ${GREEN}✅${NC} $ext - Available"
        else
            echo -e "  ${RED}❌${NC} $ext - Not available"
        fi
    done
    
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo ""
    echo "1. Connect to your database:"
    echo "   sudo -u postgres psql your_database_name"
    echo ""
    echo "2. Enable the extensions:"
    echo "   CREATE EXTENSION IF NOT EXISTS pgcrypto;"
    echo "   CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
    echo "   CREATE EXTENSION IF NOT EXISTS vector;"
    echo ""
    echo "3. Verify installation:"
    echo "   SELECT extname, extversion FROM pg_extension WHERE extname IN ('pgcrypto', 'uuid-ossp', 'vector');"
    echo ""
    echo "   Or run your database setup:"
    echo "   python cli.py setup"
    echo ""
}

# Run main function
main
