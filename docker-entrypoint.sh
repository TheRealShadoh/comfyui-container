#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[ComfyUI Container]${NC} Initializing..."

# Update ComfyUI if UPDATE_ON_START is enabled (default: true)
if [ "${UPDATE_ON_START:-true}" = "true" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Checking for ComfyUI updates..."
    if [ -d "/app/comfyui/.git" ]; then
        cd /app/comfyui
        git fetch origin
        git reset --hard origin/master || git reset --hard origin/main
        echo -e "${GREEN}[ComfyUI Container]${NC} ComfyUI updated to latest version"
    fi
fi

# Install/update custom node requirements if file exists
if [ -f "/app/custom_nodes/requirements.txt" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Installing custom node requirements..."
    python -m pip install --upgrade -r /app/custom_nodes/requirements.txt || true
fi

# Create necessary symlinks for models and outputs if they don't exist
cd /app/comfyui

if [ ! -L "models" ] && [ ! -d "models" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Linking models directory..."
    ln -s /app/models models
fi

if [ ! -L "output" ] && [ ! -d "output" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Linking output directory..."
    ln -s /app/output output
fi

if [ ! -L "custom_nodes" ] && [ ! -d "custom_nodes" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Linking custom_nodes directory..."
    ln -s /app/custom_nodes custom_nodes
fi

# Print GPU information
echo -e "${GREEN}[ComfyUI Container]${NC} GPU Information:"
nvidia-smi --query-gpu=index,name,driver_version,memory.total --format=csv,noheader || echo "Warning: nvidia-smi not available"

echo -e "${GREEN}[ComfyUI Container]${NC} Starting ComfyUI..."
echo -e "${GREEN}[ComfyUI Container]${NC} Web UI will be available at http://0.0.0.0:8188"

# Execute the main command
exec "$@"
