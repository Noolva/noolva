#!/bin/bash

# Infer paths
PROJECT_DIR="$(pwd)"
VENV_PATH="$PROJECT_DIR/venv"

# Validate paths
if [ ! -f "$PROJECT_DIR/cli.py" ]; then
    echo "❌ Error: cli.py not found in $PROJECT_DIR"
    exit 1
fi
if [ ! -d "$VENV_PATH/bin" ]; then
    echo "❌ Error: venv not found at $VENV_PATH"
    exit 1
fi

# Target install location
INSTALL_DIR="/usr/local/bin"
INSTALL_PATH="$INSTALL_DIR/nvn"

# Generate launcher script
cat << EOF | sudo tee "$INSTALL_PATH" > /dev/null
#!/bin/bash
source "$VENV_PATH/bin/activate"
"\$VIRTUAL_ENV/bin/python" "$PROJECT_DIR/cli.py" "\$@"
EOF

# Make it executable
sudo chmod +x "$INSTALL_PATH"
echo "✅ 'nvn' installed. You can now run it from anywhere!"
