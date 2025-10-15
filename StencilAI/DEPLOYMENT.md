# Deployment Guide

This guide explains how to deploy the Stencil Image Generator with Gradio.

## Features

The Stencil Generator web app includes:

- **AI-Powered Stencil Generation**: Generate black and white stencil images using Stable Diffusion
- **Multiple Image Variants**: Generate 1-4 image variations at once to choose from
- **Post-Processing Options**:
  - Toggle outline effect on individual images using computer vision (StencilCV)
  - Compare original and outlined versions side-by-side
- **Advanced Controls**: Adjust inference steps, guidance scale, image dimensions, seeds, and more
- **Clean UI**: Simple interface with collapsible advanced settings

## Local Deployment

### Prerequisites

1. Install the required dependencies:
```bash
pip install -r requirements.txt
```

2. Ensure you have sufficient disk space (the Stable Diffusion model is ~5GB)
3. Ensure OpenCV is installed for outline post-processing:
```bash
pip install opencv-python
```

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
   - `StencilCV.py`
   - `requirements.txt`
4. Ensure `opencv-python` is in requirements.txt
5. The Space will automatically deploy

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
COPY StencilCV.py .
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

## Using the Web Interface

### Generating Stencils

1. Enter a text prompt (e.g., "a cat sitting", "a tree with spreading branches")
2. Adjust the "Number of Images" slider (1-4) to generate multiple variations
3. Optionally expand "Advanced Settings" to fine-tune generation parameters
4. Click "Generate Stencil" and wait for the images to appear

### Post-Processing with Outline Effect

After generating images, you can apply an outline effect to individual images:

1. Click on an image in the gallery to select it
2. Expand "Post-Processing Options"
3. Click "Toggle Outline on Selected Image"
4. The selected image will be replaced with an outlined version
5. Click the button again to revert to the original
6. Repeat for other images to compare styles

**Tips:**
- The outline effect creates a line-art style using edge detection
- Works best on images with clear subjects and defined edges
- Each image can be toggled independently
- Original images are preserved, so you can always revert back

## API Access

Gradio automatically provides an API endpoint. After launching, visit:
- `http://localhost:7860/?view=api` for API documentation

Use the API programmatically:

```python
from gradio_client import Client

client = Client("http://localhost:7860")
# Generate stencil images
result = client.predict(
    "a cat sitting",  # prompt
    "",  # negative_prompt
    2,   # num_images
    25,  # num_inference_steps
    7.5, # guidance_scale
    512, # width
    512, # height
    42,  # seed
    False, # use_seed
    True,  # add_stencil_suffix
    True,  # clean_background
    api_name="/predict"
)
```

## Additional Resources

- [Gradio Documentation](https://gradio.app/docs/)
- [Stable Diffusion Guide](https://huggingface.co/docs/diffusers/)
- [Deployment Best Practices](https://gradio.app/guides/sharing-your-app/)
