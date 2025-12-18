#!/bin/bash
set -e

# Sekha Local Installer (Tier 1)
# One-command local binary installation

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.sekha}"
DATA_DIR="${CONFIG_DIR}/data"

echo "🚀 Installing Sekha Controller (Local Binary)..."

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    arm64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "📋 Detected: $OS-$ARCH"

# Get latest release version
LATEST_VERSION=$(curl -s https://api.github.com/repos/sekha-ai/sekha-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    echo "❌ Failed to fetch latest version"
    exit 1
fi

echo "📦 Latest version: $LATEST_VERSION"

# Download URL
DOWNLOAD_URL="https://github.com/sekha-ai/sekha-controller/releases/download/${LATEST_VERSION}/sekha-controller-${OS}-${ARCH}"

# Download binary
echo "⬇️  Downloading..."
curl -L --progress-bar -o /tmp/sekha-controller "$DOWNLOAD_URL"
chmod +x /tmp/sekha-controller

# Create install directory
mkdir -p "$INSTALL_DIR"

# Move binary
mv /tmp/sekha-controller "$INSTALL_DIR/"
echo "✅ Binary installed to $INSTALL_DIR/sekha-controller"

# Create directories
mkdir -p "$CONFIG_DIR" "$DATA_DIR"
echo "✅ Created directories: $CONFIG_DIR, $DATA_DIR"

# Create default config if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.toml" ]; then
    echo "📝 Creating default configuration..."
    cat > "$CONFIG_DIR/config.toml" << 'EOF'
[server]
host = "127.0.0.1"
port = 8080

[database]
url = "sqlite:///.sekha/data/sekha.db"

[chroma]
url = "http://localhost:8000"

[ollama]
url = "http://localhost:11434"
embedding_model = "nomic-embed-text"
EOF
    echo "✅ Default config created: $CONFIG_DIR/config.toml"
else
    echo "⚠️  Config already exists: $CONFIG_DIR/config.toml"
fi

# Add to PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "📌 Add to PATH:"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    echo ""
    echo "💡 Add this line to your ~/.bashrc or ~/.zshrc"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "🔧 Configure Ollama and Chroma, then run:"
echo "   sekha-controller"
echo ""
echo "📖 View logs:"
echo "   tail -f ~/.sekha/logs/sekha-controller.log"
echo ""
echo "🌐 Access at: http://localhost:8080"