#!/bin/bash
set -e

# Sekha Local Installer (Tier 1 - Single Binary)
# Installs Rust core only (for SDK development)

INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.sekha"
DATA_DIR="$HOME/.sekha/data"
ARCHIVE_DIR="$HOME/.sekha/import"
IMPORTED_DIR="$HOME/.sekha/imported"

echo "🚀 Installing Sekha Controller (Local Binary)..."

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Check dependencies
echo "🔍 Checking dependencies..."
if ! command -v curl &> /dev/null; then
    echo "❌ curl is required but not installed"
    exit 1
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$DATA_DIR" "$ARCHIVE_DIR" "$IMPORTED_DIR"

# Download latest release
echo "📥 Downloading latest release..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/sekha-ai/sekha-controller/releases/latest | grep '"tag_name":' | cut -d'"' -f4)

if [ -z "$LATEST_VERSION" ]; then
    echo "❌ Failed to fetch latest version"
    exit 1
fi

echo "📦 Version: $LATEST_VERSION"
DOWNLOAD_URL="https://github.com/sekha-ai/sekha-controller/releases/download/${LATEST_VERSION}/sekha-controller-${OS}-${ARCH}"

# Download binary
curl -L --progress-bar -o /tmp/sekha-controller "$DOWNLOAD_URL"
chmod +x /tmp/sekha-controller

# Install binary
mv /tmp/sekha-controller "$INSTALL_DIR/"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "�� Adding $INSTALL_DIR to PATH..."
    
    SHELL_NAME=$(basename "$SHELL")
    case $SHELL_NAME in
        bash)
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.bashrc
            echo "✅ Added to ~/.bashrc"
            ;;
        zsh)
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> ~/.zshrc
            echo "✅ Added to ~/.zshrc"
            ;;
        *)
            echo "⚠️ Add this to your shell profile:"
            echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
            ;;
    esac
fi

# Create default config if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.toml" ]; then
    echo "⚙️ Creating default config..."
    cat > "$CONFIG_DIR/config.toml" << CONFIGEOF
[server]
port = 8080
host = "127.0.0.1"

[database]
url = "sqlite:///$HOME/.sekha/data/sekha.db"

[chroma]
url = "http://localhost:8000"

[redis]
url = "redis://localhost:6379"

[ollama]
url = "http://localhost:11434"

[logging]
level = "info"
CONFIGEOF
fi

# Create .env file if it doesn't exist
if [ ! -f "$CONFIG_DIR/.env" ]; then
    echo "⚙️ Creating .env file..."
    cat > "$CONFIG_DIR/.env" << ENVEOF
# Sekha API Keys (add your keys here)
OPENAI_API_KEY=your_openai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here

# Optional: Custom Ollama host
# OLLAMA_HOST=http://localhost:11434
ENVEOF
    chmod 600 "$CONFIG_DIR/.env"
fi

# Verify installation
echo ""
echo "✅ Sekha installed successfully!"
echo ""
echo "📦 Binary: $INSTALL_DIR/sekha-controller"
echo "⚙️ Config: $CONFIG_DIR/config.toml"
echo "📁 Data: $DATA_DIR"
echo "📥 Import: $ARCHIVE_DIR"
echo ""
echo "🔧 Next steps:"
echo "   1. Install Ollama: https://ollama.ai"
echo "   2. Pull models: ollama pull nomic-embed-text && ollama pull llama3.1:8b"
echo "   3. Edit config: nano $CONFIG_DIR/config.toml"
echo "   4. Add API keys: nano $CONFIG_DIR/.env"
echo "   5. Start: sekha-controller"
echo ""
echo "📚 Documentation: https://sekha-ai.dev/docs"
echo "💬 Support: https://github.com/sekha-ai/sekha-controller/discussions"
