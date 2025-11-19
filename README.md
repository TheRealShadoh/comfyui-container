# ComfyUI Container

A containerized deployment of [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with NVIDIA GPU support for easy setup and fast inference.

## Overview

This repository provides a Docker container setup for running ComfyUI with the following features:

- ✅ **NVIDIA GPU Support** - Full CUDA 12.4 and cuDNN support for fast inference
- ✅ **Auto-Update** - Automatically pulls the latest ComfyUI release on container start
- ✅ **Easy Deployment** - Docker Compose configuration for one-command startup
- ✅ **Persistent Storage** - Volume mounts for models, outputs, and custom nodes
- ✅ **Production Ready** - Health checks, logging, and resource management included

## Prerequisites

### Required
- **Docker** - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** - [Install Docker Compose](https://docs.docker.com/compose/install/)
- **NVIDIA GPU** - Compatible NVIDIA GPU
- **NVIDIA Container Toolkit** - [Install NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

### Verify Prerequisites

```bash
# Check Docker installation
docker --version

# Check Docker Compose installation
docker compose version

# Check NVIDIA GPU drivers
nvidia-smi

# Check NVIDIA Container Toolkit
docker run --rm --runtime=nvidia nvidia/cuda:12.4.1-runtime-ubuntu22.04 nvidia-smi
```

## Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url> comfyui-container
cd comfyui-container
```

### 2. Create Directory Structure

```bash
mkdir -p models output custom_nodes
```

These directories will store:
- `models/` - Model files (checkpoints, LORA, VAE, etc.)
- `output/` - Generated images from ComfyUI
- `custom_nodes/` - Custom node extensions

### 3. Build and Start Container

```bash
# Build the Docker image
docker compose build

# Start ComfyUI
docker compose up -d

# View logs
docker compose logs -f comfyui
```

### 4. Access ComfyUI

Open your browser and navigate to:
```
http://localhost:8188
```

### 5. Stop Container

```bash
docker compose down
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Available options:

| Variable | Default | Description |
|----------|---------|-------------|
| `UPDATE_ON_START` | `true` | Auto-update ComfyUI on startup |
| `CUDA_VISIBLE_DEVICES` | `0` | GPU index to use (0, 1, 2, etc.) |
| `MEMORY_LIMIT` | `16G` | Container memory limit |
| `PYTHONUNBUFFERED` | `1` | Real-time log output |

### Multiple GPUs

To use multiple GPUs, edit `docker-compose.yml`:

```yaml
environment:
  - CUDA_VISIBLE_DEVICES=0,1,2  # Use first three GPUs
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 3  # Use 3 GPUs
```

### Models and Checkpoints

Place model files in the `models/` directory:

```
models/
├── checkpoints/
│   ├── model.safetensors
│   └── model.ckpt
├── loras/
├── vae/
├── controlnet/
└── ...
```

All models are persistent across container restarts.

### Custom Nodes

Add custom nodes to the `custom_nodes/` directory:

```
custom_nodes/
├── custom_node_1/
├── custom_node_2/
└── requirements.txt  # (optional) Will be installed on startup
```

If you add a `requirements.txt` file in `custom_nodes/`, it will be automatically installed on container start.

## Advanced Usage

### Building the Image

```bash
docker compose build --no-cache  # Force rebuild
```

### View Container Status

```bash
docker compose ps
docker compose logs
docker compose logs -f comfyui --tail 50
```

### Execute Commands in Running Container

```bash
docker compose exec comfyui bash
docker compose exec comfyui python -c "import torch; print(torch.cuda.is_available())"
```

### Disable Auto-Update

Create `.env` and set:

```
UPDATE_ON_START=false
```

Then restart:

```bash
docker compose up -d
```

### Resource Management

Adjust in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 32G  # Increase memory limit
    reservations:
      devices:
        - driver: nvidia
          count: 2  # Use 2 GPUs
```

### Rebuild ComfyUI Installation

To clean reinstall ComfyUI:

```bash
docker compose exec comfyui bash
cd /app && rm -rf comfyui
git clone https://github.com/comfyanonymous/ComfyUI.git /app/comfyui
cd comfyui && pip install -r requirements.txt
```

## Troubleshooting

### GPU Not Detected

**Error:** `CUDA not available` or `nvidia-smi` not found

**Solution:**
1. Verify NVIDIA drivers: `nvidia-smi`
2. Install NVIDIA Container Toolkit (see Prerequisites)
3. Restart Docker daemon:
   ```bash
   sudo systemctl restart docker
   ```
4. Test GPU access:
   ```bash
   docker compose exec comfyui nvidia-smi
   ```

### Container Crashes on Startup

**Check logs:**
```bash
docker compose logs comfyui
```

**Common issues:**
- Out of memory: Increase `MEMORY_LIMIT` in `.env`
- Model not found: Ensure models are in `models/` directory
- CUDA out of memory: Reduce image resolution or batch size in ComfyUI

### Port Already in Use

**Error:** `port 8188 is already allocated`

**Solution:** Change the port in `docker-compose.yml`:
```yaml
ports:
  - "8189:8188"  # Map to 8189 instead
```

### Slow Inference

**Optimization tips:**
- Ensure GPU is being used: Check `CUDA_VISIBLE_DEVICES`
- Monitor GPU usage: `nvidia-smi -l 1` (updates every 1 second)
- Use FP16 instead of FP32 (if model supports it)
- Check available VRAM: `nvidia-smi --query-gpu=memory.total,memory.free --format=csv`

### Connection Refused

**Error:** `http://localhost:8188 refused`

**Solution:**
1. Wait for container to start: `docker compose logs -f comfyui`
2. Verify container is running: `docker compose ps`
3. Check if the web UI is listening: `docker compose exec comfyui netstat -tulpn | grep 8188`

## Updating ComfyUI

ComfyUI is automatically updated on container start if `UPDATE_ON_START=true`.

**Manual update:**
```bash
docker compose restart comfyui
```

**Force rebuild with latest base image:**
```bash
docker compose build --no-cache
docker compose up -d
```

## Keeping in Sync with Upstream

This container automatically pulls from the latest `https://github.com/comfyanonymous/ComfyUI` release on startup.

To disable auto-updates:
```bash
# Create/edit .env
UPDATE_ON_START=false
docker compose up -d
```

## Performance Tips

1. **GPU Memory:** Monitor with `nvidia-smi` during inference
2. **CPU Threads:** Docker uses all available CPU cores by default
3. **Disk Speed:** Use SSD for models directory for faster load times
4. **Network:** If pulling models, use direct connection instead of VPN
5. **Temperature:** Ensure proper GPU cooling for sustained workloads

## Data Persistence

All data persists across container restarts:

- **Models** → `./models/` directory
- **Generated images** → `./output/` directory
- **Custom nodes** → `./custom_nodes/` directory
- **ComfyUI installation** → Can be persisted with named volume (see docker-compose.yml comments)

## Backup

Backup your persistent data:

```bash
# Backup models
tar -czf models_backup.tar.gz models/

# Backup outputs
tar -czf outputs_backup.tar.gz output/

# Backup custom nodes
tar -czf custom_nodes_backup.tar.gz custom_nodes/
```

## License

This container configuration is provided as-is. ComfyUI is licensed under its own license - see the [official ComfyUI repository](https://github.com/comfyanonymous/ComfyUI).

## Support & Issues

For issues related to:
- **ComfyUI** → [ComfyUI GitHub Issues](https://github.com/comfyanonymous/ComfyUI/issues)
- **This Container** → Open an issue in this repository

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Submit a pull request

## Roadmap

- [ ] Support for other model formats
- [ ] Web UI for model management
- [ ] Cloud deployment templates (AWS, GCP, Azure)
- [ ] Multi-GPU optimization guide
- [ ] Performance benchmarks
- [ ] Pre-built images on Docker Hub

---

**Happy generating!** 🎨
