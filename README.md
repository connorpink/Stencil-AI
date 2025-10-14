# Stencil-AI: Drawing Stencil Image Generator

Generate black and white drawing stencil images using pretrained Stable Diffusion models with prompt engineering.

## Overview

This project uses open-source Stable Diffusion models to generate stencil-style images. By automatically appending stencil-specific prompt decorations like "drawing stencil black and white", it guides the model to produce high-contrast, simple line drawings suitable for stenciling.

## Installation

1. **Clone or navigate to this repository**

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

   Note: This will download PyTorch, Hugging Face Diffusers, and other required packages. If you have a CUDA-capable GPU, PyTorch will automatically use it for faster generation.

## Quick Start

### Basic Usage

```python
from Stencil import StencilGenerator

# Initialize the generator
generator = StencilGenerator()

# Generate a stencil image
image = generator.generate("a cat sitting")

# Save the image
generator.save_image(image, "cat_stencil.png")
```

### Generate and Save in One Step

```python
from Stencil import StencilGenerator

generator = StencilGenerator()

# Generate and save directly
generator.generate_and_save(
    prompt="a tree with spreading branches",
    output_path="tree_stencil.png",
    seed=42  # For reproducible results
)
```

### Run the Example Script

The module includes example usage that generates multiple stencils:

```bash
python Stencil.py
```

This will create an `output_stencils/` directory with sample stencil images.

## Features

### Automatic Prompt Enhancement

The generator automatically appends stencil-specific styling to your prompts:
- "drawing stencil, black and white, high contrast"
- "simple lines, silhouette style, clean edges"
- "no shading, flat design, vector art style"

### Negative Prompts

Automatically excludes unwanted features:
- Color and shading
- Photorealistic details
- Gradients and complexity

### Customization Options

```python
generator = StencilGenerator(
    model_id="stabilityai/stable-diffusion-2-1-base",  # Different SD model
    device="cuda",  # or "cpu"
    use_fp16=True   # Half precision for faster inference
)

image = generator.generate(
    prompt="a bicycle",
    num_images=4,              # Generate multiple variations
    num_inference_steps=30,    # More steps = better quality (slower)
    guidance_scale=7.5,        # How strongly to follow prompt (7-8.5 recommended)
    width=512,                 # Image dimensions
    height=512,
    seed=42,                   # For reproducibility
    add_stencil_suffix=True    # Enable/disable automatic prompt enhancement
)
```

## Hardware Requirements

- **CPU**: Works but slow (~2-5 minutes per image)
- **GPU (CUDA)**: Recommended (~10-30 seconds per image)
  - Minimum 6GB VRAM for 512x512 images
  - 8GB+ VRAM recommended for larger images

### Memory Optimizations

If you encounter out-of-memory errors, uncomment this line in [Stencil.py:63](Stencil.py#L63):

```python
self.pipe.enable_vae_slicing()
```

## Model Options

The default model is `stabilityai/stable-diffusion-2-1-base`. You can use other Stable Diffusion models from Hugging Face:

```python
# Stable Diffusion 1.5 (lighter, faster)
generator = StencilGenerator(model_id="runwayml/stable-diffusion-v1-5")

# Stable Diffusion 2.1 (higher quality)
generator = StencilGenerator(model_id="stabilityai/stable-diffusion-2-1")

# Other community models
generator = StencilGenerator(model_id="prompthero/openjourney")
```

## Output Examples

The generator produces:
- High contrast black and white images
- Simple, clean line art suitable for cutting stencils
- Flat designs without shading or gradients
- Various subjects: objects, animals, plants, etc.

## Tips for Better Results

1. **Keep prompts simple**: "a cat" works better than "a detailed photorealistic cat with fur texture"
2. **Describe the subject clearly**: Focus on the main object/shape
3. **Adjust guidance_scale**:
   - Lower (5-7): More creative, varied results
   - Higher (7.5-10): Stricter adherence to prompt
4. **Generate multiple images**: Set `num_images=4` to get variations and pick the best
5. **Use seeds**: Save the seed value of good results for consistency

## Troubleshooting

**Import warnings in IDE**: These warnings appear because packages aren't installed yet. Run:
```bash
pip install -r requirements.txt
```

**CUDA out of memory**: Reduce image size or enable VAE slicing (see Memory Optimizations above)

**Slow generation on CPU**: Consider using a cloud GPU service like Google Colab or reducing `num_inference_steps`

## License

This project uses open-source models and libraries. Check individual model licenses on Hugging Face for commercial use restrictions.

## Next Steps

To improve results further, consider:
1. Fine-tuning the model on actual stencil images
2. Adding post-processing (edge detection, thresholding)
3. Experimenting with different SD models
4. Creating a web interface for easier generation
