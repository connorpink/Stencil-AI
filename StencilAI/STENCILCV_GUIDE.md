# StencilCV Guide - Traditional Computer Vision Approach

## Overview

**StencilCV** uses classical computer vision techniques to convert existing images into stencils. Unlike the AI approach (Stencil.py), this is:
- **Deterministic** - same input always produces same output
- **Fast** - processes in milliseconds, not seconds
- **No training required** - pure algorithms
- **Works with any input** - photos, drawings, clipart

## Installation

```bash
pip install opencv-python numpy pillow
```

Or use the full requirements:
```bash
pip install -r requirements.txt
```

## Quick Start

```python
from StencilCV import StencilCV

# Initialize processor
processor = StencilCV()

# Convert any image to a stencil
stencil = processor.auto_stencil('photo.jpg', style='filled')
processor.save(stencil, 'output_stencil.png')
```

## Three Stencil Styles

### 1. **Outline Stencil** (Edge Detection)

Creates line-art style stencils using Canny edge detection. Perfect for:
- Coloring books
- Outline drawings
- Wire-frame style
- Detailed line art

```python
processor = StencilCV()

# Basic usage
outline = processor.edge_stencil('photo.jpg')

# With custom parameters
outline = processor.edge_stencil(
    'photo.jpg',
    blur_kernel=5,        # Noise reduction (odd number, 3-9)
    canny_low=50,         # Lower threshold for edge detection
    canny_high=150,       # Upper threshold for edge detection
    line_thickness=2,     # Thickness of lines (1-5)
    invert=False          # False = black lines on white
)

processor.save(outline, 'outline.png')
```

**Parameters explained:**
- `canny_low/high`: Lower values = more edges detected (more detail, but noisier)
- `line_thickness`: Thicker lines = easier to see/cut, but less detail
- `blur_kernel`: Higher = smoother edges, less noise, but less detail

### 2. **Filled Silhouette Stencil** (Thresholding + Contours)

Creates solid filled stencils. Perfect for:
- Spray paint stencils
- Vinyl cutting
- Solid silhouettes
- Traditional stencil templates

```python
processor = StencilCV()

# Basic usage
filled = processor.silhouette_stencil('photo.jpg')

# With custom parameters
filled = processor.silhouette_stencil(
    'photo.jpg',
    threshold_method='otsu',     # 'otsu', 'adaptive', or 'simple'
    threshold_value=127,         # Only used with 'simple' method
    blur_kernel=5,               # Noise reduction
    fill_holes=True,             # Fill holes in the silhouette
    remove_small_objects=500,    # Remove noise (pixels)
    smooth_edges=True            # Smooth the edges
)

processor.save(filled, 'filled.png')
```

**Threshold methods:**
- `'otsu'`: **Best for most images** - automatically finds optimal threshold
- `'adaptive'`: Good for images with varying lighting
- `'simple'`: Manual threshold - you control the cutoff value (0-255)

**Parameters explained:**
- `fill_holes`: Removes interior holes (like eyes in a face becoming white)
- `remove_small_objects`: Removes specks/noise smaller than N pixels
- `smooth_edges`: Makes edges less jagged

### 3. **Hybrid Stencil** (Edges + Fill)

Combines edges and silhouette for detailed stencils. Perfect for:
- Maximum detail stencils
- Complex subjects
- When you want both outline and fill

```python
processor = StencilCV()

hybrid = processor.hybrid_stencil(
    'photo.jpg',
    show_edges=True,        # Include edge lines
    show_fill=True,         # Include filled silhouette
    edge_thickness=2        # Thickness of edge lines
)

processor.save(hybrid, 'hybrid.png')
```

## Complete Examples

### Example 1: Photo to Silhouette Stencil

```python
from StencilCV import StencilCV

processor = StencilCV()

# Take a photo of a cat and convert to stencil
stencil = processor.silhouette_stencil(
    'cat_photo.jpg',
    threshold_method='otsu',
    fill_holes=True,
    remove_small_objects=1000,  # Aggressive noise removal
    smooth_edges=True
)

processor.save(stencil, 'cat_stencil.png')
```

### Example 2: Detailed Outline from Drawing

```python
from StencilCV import StencilCV

processor = StencilCV()

# Convert a detailed drawing to clean line art
outline = processor.edge_stencil(
    'drawing.jpg',
    blur_kernel=3,          # Less blur = more detail
    canny_low=30,           # Lower = detect more edges
    canny_high=100,
    line_thickness=1        # Thin lines for detail
)

processor.save(outline, 'outline_detailed.png')
```

### Example 3: Batch Processing

```python
from StencilCV import StencilCV
import os

processor = StencilCV()

# Process all images in a folder
input_dir = 'input_photos'
output_dir = 'output_stencils'
os.makedirs(output_dir, exist_ok=True)

for filename in os.listdir(input_dir):
    if filename.endswith(('.jpg', '.png', '.jpeg')):
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, f"stencil_{filename}")

        print(f"Processing {filename}...")
        stencil = processor.auto_stencil(input_path, style='filled')
        processor.save(stencil, output_path)

print("Batch processing complete!")
```

### Example 4: Integration with Stable Diffusion

```python
from Stencil import StencilGenerator
from StencilCV import StencilCV

# Generate with AI, then clean with CV
ai_generator = StencilGenerator()
cv_processor = StencilCV()

# Generate base image with AI
ai_image = ai_generator.generate("a bicycle", clean_background=False)

# Convert to perfect stencil with CV
stencil = cv_processor.silhouette_stencil(ai_image)
cv_processor.save(stencil, 'bicycle_stencil.png')
```

## Comparison: StencilCV vs Stencil.py

| Feature | StencilCV (CV) | Stencil.py (AI) |
|---------|----------------|-----------------|
| **Input** | Existing images | Text prompts |
| **Speed** | Very fast (~0.1s) | Slow (~10-30s) |
| **Quality** | Depends on input | Unpredictable |
| **Deterministic** | Yes | No |
| **Framing** | As good as input | Often crops subjects |
| **GPU Required** | No | Recommended |
| **Use Case** | Clean existing images | Generate new designs |

## Best Practices

### For Photos of Objects

```python
# Good settings for object photos (products, items, etc.)
stencil = processor.silhouette_stencil(
    'object_photo.jpg',
    threshold_method='otsu',
    blur_kernel=5,
    fill_holes=True,
    remove_small_objects=1000,
    smooth_edges=True
)
```

### For Drawings/Illustrations

```python
# Good settings for drawings with clean lines
stencil = processor.edge_stencil(
    'drawing.jpg',
    blur_kernel=3,
    canny_low=50,
    canny_high=150,
    line_thickness=2
)
```

### For Complex Scenes

```python
# Use adaptive threshold for varying lighting
stencil = processor.silhouette_stencil(
    'complex_photo.jpg',
    threshold_method='adaptive',
    fill_holes=True,
    smooth_edges=True
)
```

### For Print-Ready Stencils

```python
# Maximum quality for printing
stencil = processor.silhouette_stencil(
    'input.jpg',
    threshold_method='otsu',
    blur_kernel=7,           # Smoother
    fill_holes=True,
    remove_small_objects=500,
    smooth_edges=True
)
```

## Troubleshooting

### Problem: Too much noise/specks

**Solution:** Increase `remove_small_objects`:
```python
stencil = processor.silhouette_stencil(
    'image.jpg',
    remove_small_objects=2000  # Increase this
)
```

### Problem: Important details lost

**Solution:** Decrease `blur_kernel` and adjust thresholds:
```python
stencil = processor.edge_stencil(
    'image.jpg',
    blur_kernel=3,      # Less blur
    canny_low=30,       # Lower threshold
    canny_high=100
)
```

### Problem: Edges too thin/thick

**Solution:** Adjust `line_thickness`:
```python
stencil = processor.edge_stencil(
    'image.jpg',
    line_thickness=3    # Thicker lines
)
```

### Problem: Subject has holes (e.g., white eyes)

**Solution:** Enable `fill_holes`:
```python
stencil = processor.silhouette_stencil(
    'image.jpg',
    fill_holes=True     # Fills interior holes
)
```

### Problem: Jagged/pixelated edges

**Solution:** Enable `smooth_edges` and increase `blur_kernel`:
```python
stencil = processor.silhouette_stencil(
    'image.jpg',
    blur_kernel=7,       # More smoothing
    smooth_edges=True
)
```

## Advanced Usage

### Custom Pipeline

```python
from StencilCV import StencilCV
import cv2
import numpy as np

processor = StencilCV()

# Load image
img = processor.load_image('input.jpg')

# Apply custom preprocessing
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
equalized = cv2.equalizeHist(gray)  # Improve contrast

# Convert back to color for processing
img_eq = cv2.cvtColor(equalized, cv2.COLOR_GRAY2BGR)

# Process with StencilCV
stencil = processor.silhouette_stencil(img_eq)
processor.save(stencil, 'output.png')
```

### Working with PIL Images

```python
from StencilCV import StencilCV
from PIL import Image

processor = StencilCV()

# Load with PIL
pil_image = Image.open('input.jpg')

# Process (StencilCV handles PIL images)
stencil = processor.auto_stencil(pil_image, style='filled')

# Result is PIL Image - can manipulate further
stencil = stencil.resize((1024, 1024))
stencil.save('output.png')
```

### Getting OpenCV Array

```python
from StencilCV import StencilCV

processor = StencilCV()

# Get result as PIL Image
stencil_pil = processor.auto_stencil('input.jpg')

# Convert to OpenCV format for further processing
stencil_cv = processor.from_pil(stencil_pil)

# Now you can use OpenCV functions
# ... custom OpenCV operations ...

# Convert back to PIL
result_pil = processor.to_pil(stencil_cv)
```

## Recommended Workflow

### Workflow 1: StencilCV Only (Best for Existing Images)

```
Input Photo → StencilCV → Clean Stencil
```

**Use when:**
- You have good photos/images to start with
- You want fast, predictable results
- You need batch processing

### Workflow 2: AI + CV Hybrid (Best for New Designs)

```
Text Prompt → Stable Diffusion → StencilCV → Perfect Stencil
```

**Use when:**
- You need to generate new designs from text
- You want the best of both worlds
- Quality matters more than speed

```python
from Stencil import StencilGenerator
from StencilCV import StencilCV

# Generate with AI
ai_gen = StencilGenerator()
ai_image = ai_gen.generate("a tree", clean_background=False)

# Perfect with CV
cv_proc = StencilCV()
final_stencil = cv_proc.silhouette_stencil(ai_image)
cv_proc.save(final_stencil, 'tree_stencil.png')
```

## Performance Tips

1. **Resize large images first** - CV processes faster on smaller images:
   ```python
   from PIL import Image

   img = Image.open('large_photo.jpg')
   img = img.resize((1024, 1024))  # Resize before processing
   stencil = processor.auto_stencil(img)
   ```

2. **Batch processing** - Process multiple images in one script
3. **Use 'otsu' threshold** - Usually fastest and best results
4. **Adjust only when needed** - Default parameters work well for most cases

## Summary

**StencilCV is perfect for:**
-  Converting existing photos to stencils
-  Fast, batch processing
-  Predictable, consistent results
-  No GPU required
-  Post-processing AI-generated images

**Start simple:**
```python
from StencilCV import StencilCV

processor = StencilCV()
stencil = processor.auto_stencil('your_image.jpg', style='filled')
processor.save(stencil, 'output.png')
```

**Experiment with styles:**
- `'outline'` - Line art, edges only
- `'filled'` - Solid silhouette
- `'hybrid'` - Both edges and fill

That's it! Traditional computer vision is often the best tool for the job.
