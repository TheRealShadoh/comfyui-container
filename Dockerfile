# Build stage
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3-pip \
    python3-dev \
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
    && rm -rf /var/lib/apt/lists/*

# Create symlink for python3
RUN ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/python3.10 /usr/bin/python3

# Upgrade pip
RUN python -m pip install --upgrade pip setuptools wheel

# Final stage
FROM base

# Set working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/comfyui \
    && mkdir -p /app/models \
    && mkdir -p /app/output \
    && mkdir -p /app/custom_nodes

# Clone ComfyUI repository (will be updated if already exists)
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /app/comfyui || true

# Install ComfyUI requirements
RUN cd /app/comfyui && \
    python -m pip install --upgrade -r requirements.txt || echo "Warning: Some requirements may have failed to install"

# Install additional useful packages
RUN python -m pip install --upgrade \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu124

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
