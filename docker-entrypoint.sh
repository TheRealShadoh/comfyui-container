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

# Ensure model subdirectories exist
echo -e "${YELLOW}[ComfyUI Container]${NC} Ensuring model directories exist..."
mkdir -p /app/models/checkpoints
mkdir -p /app/models/loras
mkdir -p /app/models/vae
mkdir -p /app/models/controlnet
mkdir -p /app/models/clip
mkdir -p /app/models/embeddings
mkdir -p /app/models/upscale_models

# Create necessary symlinks for models and outputs
cd /app/comfyui

# Handle models directory - remove existing and create symlink
if [ -d "models" ] && [ ! -L "models" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Replacing models directory with symlink..."
    rm -rf models
fi
if [ ! -L "models" ]; then
    ln -s /app/models models
fi

# Handle output directory
if [ -d "output" ] && [ ! -L "output" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Replacing output directory with symlink..."
    rm -rf output
fi
if [ ! -L "output" ]; then
    ln -s /app/output output
fi

# Handle custom_nodes directory
if [ -d "custom_nodes" ] && [ ! -L "custom_nodes" ]; then
    echo -e "${YELLOW}[ComfyUI Container]${NC} Replacing custom_nodes directory with symlink..."
    rm -rf custom_nodes
fi
if [ ! -L "custom_nodes" ]; then
    ln -s /app/custom_nodes custom_nodes
fi

# Print GPU information
echo -e "${GREEN}[ComfyUI Container]${NC} GPU Information:"
nvidia-smi --query-gpu=index,name,driver_version,memory.total --format=csv,noheader || echo "Warning: nvidia-smi not available"

echo -e "${GREEN}[ComfyUI Container]${NC} Starting ComfyUI..."
echo -e "${GREEN}[ComfyUI Container]${NC} Web UI will be available at http://0.0.0.0:8188"

# Execute the main command
exec "$@"
