# Cross-Platform Installation Script for Noolva ERP API (Windows PowerShell)
# Requires: Python 3.9 (strictly)
# Note: Uses remote PostgreSQL database - does not install PostgreSQL locally

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Cyan "🚀 Noolva ERP API - Windows Installation"
Write-ColorOutput Cyan "========================================="
Write-Output ""

# Verify Python 3.9
Write-ColorOutput Cyan "🐍 Checking Python version..."

$pythonFound = $false
$pythonCmd = $null

# Try different Python commands
$pythonCommands = @("python3.9", "python3", "python", "py -3.9", "py")

foreach ($cmd in $pythonCommands) {
    try {
        $versionOutput = & $cmd --version 2>&1
        if ($LASTEXITCODE -eq 0 -or $versionOutput) {
            $version = ($versionOutput -split " ")[1]
            $major = ($version -split "\.")[0]
            $minor = ($version -split "\.")[1]
            
            if ($major -eq "3" -and $minor -eq "9") {
                $pythonCmd = $cmd
                $pythonFound = $true
                $pythonPath = (Get-Command $cmd).Source
                Write-ColorOutput Green "✅ Found Python $version at: $pythonPath"
                break
            }
        }
    } catch {
        continue
    }
}

if (-not $pythonFound) {
    Write-ColorOutput Red "❌ Python 3.9 is required but not found"
    Write-Output ""
    Write-Output "Please install Python 3.9 from:"
    Write-Output "  https://www.python.org/downloads/"
    Write-Output ""
    Write-Output "Make sure to:"
    Write-Output "  1. Check 'Add Python to PATH' during installation"
    Write-Output "  2. Restart your terminal after installation"
    exit 1
}

# Check virtual environment
Write-Output ""
if ($env:VIRTUAL_ENV) {
    Write-ColorOutput Green "✅ Virtual environment detected: $env:VIRTUAL_ENV"
} else {
    Write-ColorOutput Yellow "⚠️  No virtual environment detected."
    Write-Output "   It's strongly recommended to use a virtual environment."
    $response = Read-Host "   Continue anyway? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Output "   Please create and activate a virtual environment first:"
        Write-Output "   $pythonCmd -m venv venv"
        Write-Output "   .\venv\Scripts\Activate.ps1"
        exit 1
    }
}

# Upgrade pip
Write-Output ""
Write-ColorOutput Cyan "📥 Upgrading pip..."
& $pythonCmd -m pip install --upgrade pip --quiet

# Install dependencies
Write-Output ""
Write-ColorOutput Cyan "📦 Installing Python dependencies..."
Write-Output "   This may take a few minutes..."

# Try to install psycopg2-binary
Write-Output "   Attempting to install psycopg2-binary..."
try {
    & $pythonCmd -m pip install psycopg2-binary==2.9.10
    Write-ColorOutput Green "   ✅ psycopg2-binary installed successfully"
    
    Write-Output ""
    Write-Output "📦 Installing remaining dependencies..."
    # Ensure bcrypt is the correct version (3.2.2) for passlib 1.7.4 compatibility
    Write-Output "   Ensuring bcrypt compatibility (3.2.2)..."
    & $pythonCmd -m pip uninstall -y bcrypt 2>&1 | Out-Null
    & $pythonCmd -m pip install bcrypt==3.2.2
    & $pythonCmd -m pip install -r requirements.txt
    
    Write-Output ""
    Write-ColorOutput Green "✅ Installation complete!"
    Write-Output ""
    Write-Output "📋 Next steps:"
    Write-Output "   1. Configure your .env file with remote database credentials"
    Write-Output "   2. Validate environment: $pythonCmd cli.py validate_env"
    Write-Output "   3. Setup database: $pythonCmd cli.py setup"
    Write-Output "   4. Start server: $pythonCmd cli.py runserver"
    Write-Output ""
} catch {
    Write-Output ""
    Write-ColorOutput Red "   ❌ Installation failed: $_"
    Write-Output ""
    Write-Output "   Troubleshooting steps:"
    Write-Output "   1. Make sure you have Visual C++ Build Tools installed:"
    Write-Output "      https://visualstudio.microsoft.com/visual-cpp-build-tools/"
    Write-Output "   2. Try installing pre-built wheel:"
    Write-Output "      $pythonCmd -m pip install --only-binary :all: psycopg2-binary==2.9.10"
    Write-Output "   3. Consider using WSL (Windows Subsystem for Linux) for better compatibility"
    Write-Output ""
    exit 1
}
