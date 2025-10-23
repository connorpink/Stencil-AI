# Stencil-AI

Generate clean, print-ready stencils using AI or traditional computer vision.

## Two Approaches

###  **Stencil.py** - AI-Powered Generation
Generate stencils from text descriptions using Stable Diffusion. Now supports **fine-tuned models** trained specifically on sketch-style images!

>  ***Test using "a Tree with spreading branches" prompt***
>  - ***text decoration*** vs ***fine-tuning***
>  ![Showing comparison of models](./StencilAI/Source%20Image%20Sample/Tree_SD_vs_fineTuned.png )


---
### Stencil AI-Gen with CV outline
![GenTree-Conversion](./StencilAI/stencilGen_to_stencilCV.excalidraw.png)

---

###  **StencilCV.py** - Computer Vision Approach 
Convert existing images to stencils using classical CV techniques. [More info here](./StencilAI/STENCILCV_GUIDE.md)

```python
from StencilCV import StencilCV

processor = StencilCV()
stencil = processor.auto_stencil("photo.jpg", style='outline')
processor.save(stencil, "output_stencil.png")
```
#### Sample
![Conversion Example](./StencilAI/Source%20Image%20Sample/cat%20raw_to_outline.excalidraw.png)

**Pros:**
-  Very fast (~0.1 seconds)
-  Deterministic - same input = same output
-  Guaranteed clean black/white output
-  No GPU required
- Full control over parameters

**Cons:**
- Requires input images
- Quality depends on input

**Best for:** Converting photos/drawings to stencils, batch processing
---

## AI Model Comparison

### Standard SD 2.1 vs Fine-Tuned Checkpoints

The project now includes fine-tuned models trained specifically on sketch-style images. Here's how they compare:

| Feature | Standard SD 2.1 | Fine-Tuned Checkpoint-1000 |
|---------|-----------------|----------------------------|
| **Prompt Style** | `"a cat, black silhouette, high contrast, simple stencil design..."` | `"a cat"` (auto: `"sketch of a cat"`) |
| **Negative Prompts** | Required for best results | Not needed |
| **Output Style** | Stencil-like (with post-processing) | Inherent sketch style |
| **Consistency** | Variable | Very consistent |
| **Training Data** | General internet images | 50,000+ ImageNet-Sketch images |
| **Best Use** | Maximum customization & control | Quick, reliable sketch generation |

### Visual Comparison


```python
from Stencil import StencilGenerator

# Option 1: Standard SD 2.1 (detailed prompt engineering)
generator = StencilGenerator()
stencil = generator.generate("a cat sitting")

# Option 2: Fine-tuned checkpoint (simple prompts, sketch-style)
generator = StencilGenerator(checkpoint_path="./Fine-tuning/checkpoint-1000")
stencil = generator.generate("a cat")  # Automatically becomes "sketch of a cat"
generator.save_image(stencil, "cat_sketch.png")
```

#### **Two Model Options:**

**Standard SD 2.1** (Default):
Standard StableDiffusion v1.5 text decoration
-  Results can be inconsistent
![MountainRangeSD2.1](./StencilAI/Source%20Image%20Sample/Mountains_TextDecorated.png)
**Fine-Tuned Model** :
-  Trained on 50,000+ sketch images (ImageNet-Sketch dataset)
-  Simple prompts work well (e.g., "a cat" → "sketch of a cat")
-  Consistent accurate sketch-style outputs
![MountainRangeFineTuned](./StencilAI/Source%20Image%20Sample/Mountains_fineTuned.png)



**See [Fine-tuning/FINE_TUNING.md](./StencilAI/Fine-tuning/FINE_TUNING.md) for complete documentation on the fine-tuning process, training details, and model selection.**

---

## Installation

```bash
# Clone the repository
git clone <repo-url>
cd Stencil-AI

# Install dependencies
pip install -r requirements.txt
```

### Minimal Install (CV only)
If you only want StencilCV (no AI):
```bash
pip install opencv-python numpy pillow
```

### Full Install (AI + CV)
For both approaches:
```bash
pip install -r requirements.txt
```

## Quick Start

### StencilCV (Traditional CV) 

```python
from StencilCV import StencilCV

processor = StencilCV()

# Three stencil styles:

# 1. Filled silhouette (most common)
filled = processor.auto_stencil('photo.jpg', style='filled')
processor.save(filled, 'filled.png')

# 2. Outline/edges (line art)
outline = processor.auto_stencil('photo.jpg', style='outline')
processor.save(outline, 'outline.png')

# 3. Hybrid (edges + fill)
hybrid = processor.auto_stencil('photo.jpg', style='hybrid')
processor.save(hybrid, 'hybrid.png')
```

**See [STENCILCV_GUIDE.md](./StencilAI/STENCILCV_GUIDE.md) for complete documentation**

### Stencil.py (AI Generation)

```python
from Stencil import StencilGenerator

# Option 1: Standard SD 2.1 (default)
generator = StencilGenerator()
stencil = generator.generate("a bicycle")
generator.save_image(stencil, "bicycle.png")

# Option 2: Fine-tuned checkpoint (sketch-style)
generator_ft = StencilGenerator(checkpoint_path="./Fine-tuning/checkpoint-1000")
sketch = generator_ft.generate("a bicycle")  # Auto: "sketch of a bicycle"
generator_ft.save_image(sketch, "bicycle_sketch.png")

# Multiple images with different seeds
for i in range(5):
    stencil = generator_ft.generate("a cat", seed=42+i)
    generator_ft.save_image(stencil, f"cat_sketch_{i}.png")
```

**See [APPROACH.md](./StencilAI/APPROACH.md) for limitations and best practices**
**See [Fine-tuning/FINE_TUNING.md](./StencilAI/Fine-tuning/FINE_TUNING.md) for fine-tuned model documentation**

## Hybrid Workflow (Best Results)

Combine both for best results: AI generates, CV perfects.

```python
from Stencil import StencilGenerator
from StencilCV import StencilCV

# Generate with AI
ai_gen = StencilGenerator()
ai_image = ai_gen.generate("a tree", clean_background=False)

# Perfect with CV
cv_proc = StencilCV()
final_stencil = cv_proc.silhouette_stencil(ai_image)
cv_proc.save(final_stencil, "tree_perfect.png")
```

## Which Approach Should I Use?

### Use **StencilCV** when:
-  You have existing images to convert
-  You need fast, batch processing
-  You want predictable, consistent results
-  You don't have a GPU
-  Quality and precision matter

### Use **Stencil.py (AI)** when:
-  You need to generate from text descriptions
-  You don't have input images
-  You're exploring creative ideas
-  You have a GPU available

### Use **Both (Hybrid)** when:
-  You want the best quality
-  AI generates, CV perfects
-  You have time for two-step process

## Documentation

- **[STENCILCV_GUIDE.md](./StencilAI/STENCILCV_GUIDE.md)** - Complete guide for traditional CV approach
- **[APPROACH.md](./StencilAI/APPROACH.md)** - AI approach, limitations, and workarounds
- **[Fine-tuning/FINE_TUNING.md](./StencilAI/Fine-tuning/FINE_TUNING.md)** - Fine-tuning process, training details, and checkpoint selection
- **[DEPLOYMENT.md](./StencilAI/DEPLOYMENT.md)** - Deploy the Gradio web interface

## Web Interface (AI Only)

Launch a web UI for the AI generator with model selection:

```bash
cd StencilAI
python app.py
```

Then open http://localhost:7860 in your browser.

**Features:**
- Choose between **Standard SD 2.1**, **Checkpoint-500**, or **Checkpoint-1000**
- Simple prompt input (fine-tuned models auto-add "sketch of" prefix)
- Generate multiple variations
- Post-processing options (background cleaning, outline generation)
- Download generated stencils

## Hardware Requirements

### For StencilCV:
- Any modern CPU
- 4GB+ RAM
- No GPU required

### For Stencil.py (AI):
- CPU: Works but slow (~2-5 minutes per image)
- GPU (CUDA): Recommended (~10-30 seconds per image)
  - Minimum 6GB VRAM for 512x512 images
  - 8GB+ VRAM recommended

## Examples

Run the example scripts:

```bash
# AI examples
python Stencil.py

# CV examples
python StencilCV.py
```

## Performance Comparison

| Operation | StencilCV | Stencil.py (AI) |
|-----------|-----------|-----------------|
| Single image | ~0.1s | ~10-30s |
| 100 images | ~10s | ~30-50 minutes |
| GPU required | No | Recommended |
| Memory usage | ~200MB | ~5GB+ |

## Tips for Best Results

### StencilCV Tips:
1. Use high-quality, well-lit input images
2. Simple backgrounds work best
3. Start with `auto_stencil()` then customize
4. Try different styles: 'filled', 'outline', 'hybrid'

### AI Tips:

**For Standard SD 2.1:**
1. Keep prompts descriptive but simple
2. Use negative prompts to avoid unwanted features
3. Always use `clean_background=True`
4. Generate multiple images (different seeds) to find best result

**For Fine-Tuned Checkpoints:**
1. Use very simple prompts: "a cat" not "a majestic feline creature"
2. No need for negative prompts
3. **Checkpoint-1000 recommended** for most use cases (best balance)
4. Checkpoint-500 for more experimental/varied results

**General:**
1. Use wider aspect ratios for wide subjects: `width=640, height=512`
2. Generate multiple images (different seeds) for variety
3. Consider using AI → CV hybrid workflow for best quality

## Troubleshooting

### Import errors
```bash
pip install --upgrade opencv-python numpy pillow
```

### AI model won't load
```bash
# Check GPU availability
python -c "import torch; print(torch.cuda.is_available())"
```

### StencilCV produces noisy output
```python
# Increase noise removal
stencil = processor.silhouette_stencil(
    'image.jpg',
    remove_small_objects=2000,  # Increase this
    smooth_edges=True
)
```

## License

This project uses open-source models and libraries. Check individual model licenses on Hugging Face for commercial use restrictions.

---

