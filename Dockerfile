# Build stage
FROM nvidia/cuda:12.6.3-cudnn-devel-ubuntu22.04 AS base

# Set environment variables for performance
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/lib/python3.12/dist-packages/torch/lib:/usr/local/lib/python3.12/dist-packages/nvidia/nvjitlink/lib:${LD_LIBRARY_PATH}

# Install system dependencies with Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    git \
    wget \
    curl \
    build-essential \
    libssl-dev \
    libffi-dev \
    libopencv-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libharfbuzz0b \
    libwebp7 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Create symlink for python3.12 and install pip properly
RUN ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    python -m ensurepip --upgrade && \
    python -m pip install --upgrade pip setuptools wheel

# Final stage
FROM base

# Set working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/comfyui \
    && mkdir -p /app/models/checkpoints \
    && mkdir -p /app/models/loras \
    && mkdir -p /app/models/vae \
    && mkdir -p /app/models/controlnet \
    && mkdir -p /app/models/clip \
    && mkdir -p /app/models/embeddings \
    && mkdir -p /app/models/upscale_models \
    && mkdir -p /app/output \
    && mkdir -p /app/custom_nodes

# Clone ComfyUI repository (will be updated if already exists)
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /app/comfyui || true

# Install ComfyUI requirements
RUN cd /app/comfyui && \
    python -m pip install --upgrade -r requirements.txt || echo "Warning: Some requirements may have failed to install"

# Install PyTorch with CUDA 12.6 support (latest stable)
RUN python -m pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

# Create entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Expose port for web UI
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8188 || exit 1

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["python", "main.py", "--listen", "0.0.0.0"]
