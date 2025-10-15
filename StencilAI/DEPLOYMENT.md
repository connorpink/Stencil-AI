# Deployment Guide

This guide explains how to deploy the Stencil Image Generator with Gradio.

## Local Deployment

### Prerequisites

1. Install the required dependencies:
```bash
pip install -r requirements.txt
```

2. Ensure you have sufficient disk space (the Stable Diffusion model is ~5GB)

### Running Locally

Simply run the app.py file:

```bash
python app.py
```

The web interface will be available at:
- Local: `http://localhost:7860`
- Network: `http://0.0.0.0:7860` (accessible from other devices on your network)

### Creating a Public Share Link

To create a temporary public URL (useful for demos):

```bash
python -c "from app import launch; launch(share=True)"
```

Or modify [app.py:267](app.py#L267) to set `share=True` by default.

## Cloud Deployment

### Hugging Face Spaces

1. Create a new Space at [huggingface.co/spaces](https://huggingface.co/spaces)
2. Choose "Gradio" as the SDK
3. Upload these files:
   - `app.py`
   - `Stencil.py`
   - `requirements.txt`
4. The Space will automatically deploy

### Google Colab

Create a notebook with:

```python
!pip install -r requirements.txt

from app import launch
launch(share=True)
```

### Docker Deployment

Create a `Dockerfile`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY Stencil.py .
COPY app.py .

# Expose port
EXPOSE 7860

# Run the application
CMD ["python", "app.py"]
```

Build and run:

```bash
docker build -t stencil-generator .
docker run -p 7860:7860 stencil-generator
```

For GPU support, use `nvidia/cuda` base image and add `--gpus all` to docker run.

## Configuration Options

### Custom Port

```python
from app import launch
launch(server_port=8080)
```

### Authentication

Add password protection:

```python
from app import launch
launch(auth=("username", "password"))
```

### Custom Model

Modify `Stencil.py` to use a different model:

```python
generator = StencilGenerator(
    model_id="your-model-name"
)
```

## Performance Optimization

### For CPU-only systems:
- Set `use_fp16=False` in [app.py:20](app.py#L20)
- Expect slower generation times (30-60 seconds per image)

### For GPU systems:
- Enable additional optimizations in [Stencil.py:85](Stencil.py#L85)
- Consider enabling `xformers` for faster inference

### Memory Management:
- For low VRAM (<8GB), enable VAE slicing in [Stencil.py:85](Stencil.py#L85)
- Reduce max resolution in the Gradio interface

## Troubleshooting

### Model Download Issues
- The first run will download ~5GB of model files
- Ensure stable internet connection
- Check disk space availability

### CUDA Out of Memory
- Reduce image resolution
- Enable VAE slicing
- Use smaller batch sizes

### Import Errors
- Verify all dependencies are installed: `pip install -r requirements.txt`
- Check Python version (3.8+ required)

## Security Considerations

- The default configuration exposes the app on all network interfaces (0.0.0.0)
- For production, add authentication or restrict network access
- Consider rate limiting for public deployments
- Monitor GPU usage and set resource limits

## API Access

Gradio automatically provides an API endpoint. After launching, visit:
- `http://localhost:7860/?view=api` for API documentation

Use the API programmatically:

```python
from gradio_client import Client

client = Client("http://localhost:7860")
result = client.predict("a cat sitting", api_name="/predict")
```

## Additional Resources

- [Gradio Documentation](https://gradio.app/docs/)
- [Stable Diffusion Guide](https://huggingface.co/docs/diffusers/)
- [Deployment Best Practices](https://gradio.app/guides/sharing-your-app/)
