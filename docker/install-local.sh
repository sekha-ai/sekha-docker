#!/bin/bash
set -e

# ============================================
# Sekha Local Binary Installer (Tier 1)
# ============================================

INSTALL_DIR="${SEKHA_INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${SEKHA_CONFIG_DIR:-$HOME/.sekha}"
VERSION="${SEKHA_VERSION:-latest}"
ARCH="$(uname -m)"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

echo "🔧 Installing Sekha Controller locally..."

# Detect architecture
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/data"

# Download binary
BINARY_URL="https://github.com/sekha-ai/sekha-controller/releases/download/${VERSION}/sekha-controller-${OS}-${ARCH}"
echo "⬇️  Downloading from $BINARY_URL..."

if command -v curl >/dev/null 2>&1; then
    curl -sSL "$BINARY_URL" -o "$INSTALL_DIR/sekha-controller"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$BINARY_URL" -O "$INSTALL_DIR/sekha-controller"
else
    echo "❌ curl or wget required"
    exit 1
fi

# Make executable
chmod +x "$INSTALL_DIR/sekha-controller"

# Create config if not exists
CONFIG_FILE="$CONFIG_DIR/config.toml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "📄 Creating config at $CONFIG_FILE..."
    cat > "$CONFIG_FILE" << EOF
[server]
host = "127.0.0.1"
port = 8080

[database]
url = "sqlite:///$CONFIG_DIR/data/sekha.db"

[chroma]
url = "http://localhost:8000"

[ollama]
url = "http://localhost:11434"
embedding_model = "nomic-embed-text"

[redis]
url = "redis://localhost:6379/0"
EOF
fi

# Create systemd service (optional)
if command -v systemctl >/dev/null 2>&1; then
    echo ""
    read -p "🚀 Create systemd service for auto-start? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo tee /etc/systemd/system/sekha.service > /dev/null << EOF
[Unit]
Description=Sekha Memory Controller
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=$INSTALL_DIR/sekha-controller
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        echo "✅ Systemd service created: sudo systemctl enable --now sekha"
    fi
fi

# Add to PATH if not already
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "⚠️  Add this to your shell profile (.bashrc, .zshrc, etc.):"
    echo "export PATH=\"$INSTALL_DIR:\\$PATH\""
fi

echo ""
echo "✅ Sekha Controller installed successfully!"
echo "📍 Binary location: $INSTALL_DIR/sekha-controller"
echo "⚙️  Config location: $CONFIG_FILE"
echo ""
echo "🚀 Quick start:"
echo "   1. Start Ollama: ollama serve"
echo "   2. Pull models: ollama pull nomic-embed-text llama3.1:8b"
echo "   3. Start Sekha: $INSTALL_DIR/sekha-controller"
echo "   4. Test: curl http://localhost:8080/health"
echo ""