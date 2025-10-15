# Stencil Generation Approach

## The Problem with Prompt Engineering

After extensive testing, we discovered that **Stable Diffusion 2.1 is not trained for stencil generation**. No amount of prompt decoration can reliably produce:
- Pure white backgrounds (model generates grays, patterns, scenery)
- Single subjects (model often generates multiple objects)
- Proper framing (subjects get cropped at edges)
- True binary images (model produces grayscale with shading)

### Why Prompt Engineering Failed

The model was trained on natural images from the internet. When you ask for a "stencil", it:
- Looks for images tagged "stencil" in training data (often photos OF stencils, not clean designs)
- Interprets "cat" as realistic cats with backgrounds, not silhouettes
- Doesn't understand "pure white background" because it never learned what that means
- Creates what looks like a cat to humans, not what a stencil machine needs

## The Attempted Solution: Aggressive Post-Processing

Instead of trying to force the model to generate perfect stencils, we:
1. Let the model generate a reasonable subject
2. **Aggressively convert it to binary** using computer vision techniques
3. Ensure **pure black (0,0,0) on pure white (255,255,255)**

### How the New Post-Processing Works

The `_clean_stencil_image()` method ([Stencil.py:104-196](Stencil.py#L104-L196)) performs:

#### 1. **Otsu's Thresholding**
- Automatically finds optimal threshold to separate foreground/background
- Works even on grayscale, colored, or patterned images
- Scientific method from image processing research

#### 2. **Binary Conversion**
- Every pixel becomes either pure black (0) or pure white (255)
- No grays, no colors, no in-between
- This is what stencil cutters/printers need

#### 3. **Auto-Inversion**
- Detects if the image is inverted (white on black)
- Automatically flips to black on white if needed
- Ensures consistent output

#### 4. **Noise Removal**
- Removes small artifacts (< 100 pixels)
- Cleans up speckles and background noise
- Uses connected component analysis

#### 5. **Morphological Closing**
- Fills small holes in the subject
- Smooths edges slightly
- Makes the stencil more printable

### Result

**Any image** (even with gray backgrounds, multiple cats, or partial color) gets converted to a clean binary stencil.

## Current Configuration

### Simplified Prompts ([Stencil.py:91-102](Stencil.py#L91-L102))

```python
stencil_suffix = "black silhouette, high contrast, simple stencil design, centered in frame, complete object visible, isolated subject"
```

Why simple?
- The model doesn't understand complex instructions anyway
- Post-processing handles the rest
- Less prompt engineering = more predictable results

### Framing Enhancement ([Stencil.py:192-220](Stencil.py#L192-L220))

Automatically adds framing hints for commonly-cropped subjects:
- `"bicycle"` → `"full bicycle with both wheels visible, bicycle"`
- `"tree"` → `"full tree from trunk to top, tree"`
- Etc.

This doesn't guarantee success(the bicycle issue does persist).

### Default Parameters

- **guidance_scale**: 7.5 (balanced - not too strict, not too loose)
- **num_inference_steps**: 25 (good quality/speed tradeoff)
- **clean_background**: True (ESSENTIAL - this does the real work)

## Known Limitations

### 1. Subject Framing (The Bicycle Problem)

**Issue**: The model may still crop subjects at frame edges.

**Why**: Stable Diffusion 2.1 was trained on photos where subjects are often cropped. It thinks a cropped bicycle is a valid "bicycle" image.

**Mitigation Attempts**:
- Added framing hints ("full bicycle with both wheels visible")
- Added negative prompts ("cropped, cut off, partial")
- These help but don't guarantee success

**Potential Solutions**:
1. **Try different seeds** - some seeds frame better than others
2. **Use wider aspect ratios** - e.g., 640x512 for bicycles
3. **Generate multiple images** - pick the best one
4. **Use a different model** (see recommendations below)

### 2. Multiple Subjects (The Two Cats Problem)

**Issue**: Model sometimes generates multiple subjects (e.g., two cats instead of one).

**Why**: Training data has many images with multiple subjects. The model doesn't understand "one" vs "many".

**Mitigation**:
- Added negative prompt: `"multiple subjects, duplicate"`
- Post-processing doesn't fix this (both cats become black silhouettes)

**Solutions**:
1. **Try different seeds**
2. **Be more specific** in prompt: "a single cat sitting alone"
3. **Use object detection** to extract largest subject (future enhancement)

### 3. Grayscale/Color Outputs

**Issue**: Model sometimes generates grayscale or colored images despite prompts.

**Status**: **SOLVED** by binary post-processing. Even if the model generates a colored or gray image, it's converted to pure black and white.

### 4. Background Artifacts

**Issue**: Model generates backgrounds, patterns, grids, scenery.

**Status**: **SOLVED** by binary post-processing. Backgrounds become pure white.

## Recommendations for Better Results

### Short-Term (Current Setup)

1. **Generate multiple images** with different seeds:
   ```python
   for seed in range(42, 52):  # Try 10 different seeds
       image = generator.generate("a bicycle", seed=seed)
       # Pick the best one
   ```

2. **Adjust aspect ratio** for the subject:
   ```python
   # For wide subjects (bicycle, car)
   generator.generate("a bicycle", width=640, height=512)

   # For tall subjects (tree, person)
   generator.generate("a tree", width=512, height=640)
   ```

3. **Use simple, direct prompts**:
   - Good: `"a cat"`, `"a bicycle"`, `"a tree"`
   - Bad: `"a majestic feline creature sitting regally"`

4. **Keep clean_background=True** - this is essential

### Medium-Term (Better Models)

Consider using models specifically designed for similar tasks:

#### Option 1: ControlNet + Stable Diffusion
- Use edge detection or depth maps as input
- More control over composition
- Requires additional setup

#### Option 2: Specialized Models
- **SD-XL with LoRA trained on stencils** - if available
- **MidJourney** (commercial, but better at following instructions)
- **DALL-E 3** (commercial, excellent at composition)

#### Option 3: Different Approach Entirely
- Start with clipart/icon datasets
- Use traditional computer vision (edge detection on photos)
- Train a custom model on stencil datasets

### Long-Term (Custom Training)

Train a model specifically for stencil generation:
1. Collect dataset of high-quality stencils
2. Fine-tune Stable Diffusion or train LoRA
3. Model learns what "stencil" actually means

## Testing the Current Implementation

### Install New Dependencies

```bash
pip install scipy scikit-image
```

### Test with Examples

```python
from Stencil import StencilGenerator

generator = StencilGenerator()

# This WILL produce pure black and white
cat = generator.generate("a cat sitting")
cat.save("cat_stencil.png")

# Try multiple seeds for the bicycle
for i in range(5):
    bike = generator.generate("a bicycle", seed=42+i)
    bike.save(f"bicycle_stencil_{i}.png")
# Pick the one with both wheels visible

# Try wider aspect ratio
bike_wide = generator.generate("a bicycle", width=640, height=512)
bike_wide.save("bicycle_wide.png")
```

## Debugging Post-Processing

If you want to see the before/after:

```python
# Generate without cleaning
raw = generator.generate("a cat", clean_background=False)
raw.save("cat_raw.png")

# Generate with cleaning
clean = generator.generate("a cat", clean_background=True)
clean.save("cat_clean.png")
```

You can also adjust post-processing parameters:

```python
# More aggressive noise removal
image_raw = generator.generate("a cat", clean_background=False)
image_clean = generator._clean_stencil_image(
    image_raw,
    min_object_size=200  # Remove anything smaller than 200 pixels
)
```

## Summary

**The new approach**:
- Stops fighting the model's limitations
- Uses computer vision to force binary output
- Guarantees clean backgrounds and pure black/white
- Still has framing limitations (inherent to the model)

**Best practices**:
- Generate multiple candidates with different seeds
- Adjust aspect ratios for subject type
- Use simple prompts
- Always keep clean_background=True

**For production use**, consider:
- Implementing batch generation with seed variation
- Adding manual selection step
- Using better models (ControlNet, commercial APIs)
- Training custom models on stencil datasets
