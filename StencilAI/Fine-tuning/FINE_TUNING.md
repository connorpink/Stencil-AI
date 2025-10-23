# Fine-Tuning Stable Diffusion for Sketch Stencil Generation

## Table of Contents
1. [What is Fine-Tuning?](#what-is-fine-tuning)
2. [Why Fine-Tune for Stencils?](#why-fine-tune-for-stencils)
3. [Dataset: ImageNet-Sketch](#dataset-imagenet-sketch)
4. [Training Process](#training-process)
5. [Hyperparameters](#hyperparameters)
6. [Selected Checkpoints](#selected-checkpoints)
7. [How to Use the Fine-Tuned Models](#how-to-use-the-fine-tuned-models)
8. [Results and Comparison](#results-and-comparison)

---

## What is Fine-Tuning?

Fine-tuning is the process of taking a pre-trained machine learning model and continuing to train it on a specialized dataset to adapt it for a specific task. Instead of training a model from scratch (which requires massive datasets and computational resources), fine-tuning leverages the knowledge already learned by the base model and refines it for your particular use case.

### What Actually Happens During Fine-Tuning?

In our case, we're fine-tuning **Stable Diffusion v1.5**, a text-to-image diffusion model. Here's what happens:

1. **Base Model**: We start with Stable Diffusion v1.5, which was trained on billions of text-image pairs from the internet
2. **Selective Training**: We only train the **UNet** component (the core denoising network), while freezing other components:
   -  **UNet**: Trained and updated (learns sketch-specific patterns)
   - L **VAE**: Frozen (keeps its ability to encode/decode images)
   - L **Text Encoder**: Frozen (keeps its language understanding)
3. **Specialized Learning**: The model learns to generate images in the style of our training data (sketches) when prompted with text

**Key Insight**: By training only the UNet and using a relatively small learning rate, we preserve the model's general image generation capabilities while teaching it to specialize in sketch-style outputs.

---

## Why Fine-Tune for Stencils?

The standard Stable Diffusion 2.1 model used in the main app requires extensive **prompt engineering** to produce stencil-style images:

```python
# Standard SD 2.1 approach
prompt = "a cat, black silhouette, high contrast, simple stencil design,
          centered in frame, complete object visible, isolated subject"
negative_prompt = "color, colorful, photograph, realistic, detailed, complex"
```

Even with careful prompting, results can be inconsistent and may include unwanted details, colors, or complexity.

### Benefits of Fine-Tuning

With a fine-tuned model:
-  **Simpler prompts**: Just `"sketch of a cat"` produces sketch-style results
-  **Consistency**: Every generation follows the sketch aesthetic learned from training
-  **No negative prompts needed**: The model inherently understands the desired style
-  **Better quality**: Model has learned the exact visual patterns we want

---

## Dataset: ImageNet-Sketch

### What is ImageNet-Sketch?

[ImageNet-Sketch](https://github.com/HaohanWang/ImageNet-Sketch) is a dataset consisting of **50,000+ sketch images** across **1,000 object categories**. These sketches are simplified, black-and-white line drawings that perfectly match our stencil generation goals.

### Dataset Characteristics

- **Size**: ~50,000 images
- **Categories**: 1,000 ImageNet classes (e.g., "golden retriever", "coffee mug", "bicycle")
- **Style**: Black and white sketch drawings
- **Resolution**: Variable, resized to 512x512 during training
- **Organization**: Organized by synset IDs (e.g., `n02102040` == "English springer spaniel")

### Dataset Preprocessing

The training script ([AI_Stencil_FineTuning.py](AI_Stencil_FineTuning.py)) includes intelligent preprocessing:

1. **Synset Mapping**: Converts ImageNet synset IDs to human-readable labels
   ```
   n02102040 -> 
   "English springer spaniel" -> "sketch of English springer spaniel"
   n07930864 -> "cup" -> "sketch of cup"
   ```

2. **Image Transformations**:
   - Resize to 512x512 (bilinear interpolation)
   - Center crop
   - Convert to tensor
   - Normalize to [-1, 1] range

3. **Prompt Generation**: Each image is paired with `"sketch of {class_name}"` prompt

---

## Training Process

### Overview

The training process is implemented in [AI_Stencil_FineTuning.py](AI_Stencil_FineTuning.py) and follows the standard diffusion model training procedure.

### What the Training Code Does

#### 1. **Model Setup**
```python
# Load base Stable Diffusion v1.5 components
tokenizer = CLIPTokenizer.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="tokenizer")
text_encoder = CLIPTextModel.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="text_encoder")
vae = AutoencoderKL.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="vae")
unet = UNet2DConditionModel.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="unet")
noise_scheduler = DDPMScheduler.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="scheduler")
```

#### 2. **Freeze Components**
```python
# Only train the UNet - freeze everything else
vae.requires_grad_(False)
text_encoder.requires_grad_(False)
```

#### 3. **Training Loop**
For each batch of images:

1. **Encode Image to Latent Space**:
   ```python
   latents = vae.encode(images).latent_dist.sample()
   ```
   - VAE compresses 512x512x3 image -> 64x64x4 latent representation
   - This saves memory and speeds up training

2. **Encode Text Prompt**:
   ```python
   encoder_hidden_states = encode_prompts(prompts, tokenizer, text_encoder, device)
   ```
   - Text encoder converts "sketch of cat" -> embedding vector

3. **Add Noise to Latents**:
   ```python
   timesteps = torch.randint(0, 1000, (batch_size,))
   noisy_latents = noise_scheduler.add_noise(latents, noise, timesteps)
   ```
   - Diffusion models learn by predicting noise at random timesteps

4. **Predict Noise with UNet**:
   ```python
   model_pred = unet(noisy_latents, timesteps, encoder_hidden_states).sample
   ```

5. **Compute Loss and Update**:
   ```python
   loss = F.mse_loss(model_pred, target)
   loss.backward()
   optimizer.step()
   ```
   - Model learns to predict the noise that was added
   - Gradients only update the UNet parameters



### Memory Optimizations

The training script includes several optimizations for GPU memory efficiency:

- **Gradient Checkpointing**: Trades computation for memory by recomputing activations
- **Mixed Precision (FP16)**: Uses half-precision floats for most operations
- **Gradient Accumulation**: Simulates larger batch sizes without OOM errors
- **Frozen Components**: VAE and text encoder don't store gradients

---

## Hyperparameters

The hyperparameters used for training are specified in [runjob.sh](runjob.sh) and were carefully tuned to prevent overfitting while achieving good sketch-style generation.

### Final Hyperparameters (Used for Selected Checkpoints)

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--batch_size` | 1 | Images per GPU per iteration (limited by memory) |
| `--gradient_accumulation_steps` | 8 | Effective batch size = 1 -> 8 = 8 |
| `--num_epochs` | 1 | Number of passes through dataset (prevents overfitting) |
| `--learning_rate` | 1e-6 | Step size for weight updates (conservative for stability) |
| `--resolution` | 512 | Image size (512x512 pixels) |
| `--save_steps` | 500 | Save checkpoint every 500 training steps |
| `--mixed_precision` | True | Use FP16 for memory efficiency |
| `--gradient_checkpointing` | True | Reduce memory usage |
| `--num_workers` | 4 | Parallel data loading threads |
| `--seed` | 42 | Random seed for reproducibility |

### Why These Values?

- **1 Epoch**: With 50,000+ images, one epoch provides sufficient exposure to the dataset. More epochs risk overfitting (model memorizes training data instead of learning general patterns)

- **Learning Rate 1e-6**: Very small to preserve base model capabilities while gently adapting to sketch style

- **Save Every 500 Steps**: With ~50,000 images and batch size 8, one epoch H 6,250 steps. Saving every 500 steps gives us multiple checkpoints to choose from

- **Effective Batch Size 8**: Balances training stability with memory constraints

### Training Environment

The model was trained on **Compute Canada's GPU cluster** using:
- **GPU**: 1x NVIDIA H100 with 80GB memory
- **Time**: ~8 hours maximum allocation
- **Container**: Custom [Apptainer/Singularity container](https://github.com/connorpink/SyntheticData_Diffusion_TB_CXR/pkgs/container/syntheticdata_diffusion_tb_cxr%2Fhybridmedimage/545628416?tag=v2025.10.24) with PyTorch + Diffusers 
- **Job Scheduler**: SLURM (resource allocation and management)

---



## How to Use the Fine-Tuned Models

The fine-tuned checkpoints are integrated into the main Stencil Generator app ([app.py](../app.py)) via modifications to [Stencil.py](../Stencil.py).

### Integration Architecture

#### 1. **Stencil.py Modifications**

The `StencilGenerator` class now supports checkpoint loading:

```python
# Initialize with checkpoint
generator = StencilGenerator(
    checkpoint_path="./Fine-tuning/checkpoint-1000",
    use_fp16=True
)

# Or use standard SD 2.1
generator = StencilGenerator(
    model_id="stabilityai/stable-diffusion-2-1-base",
    use_fp16=True
)
```

**What happens when `checkpoint_path` is provided:**

1. **Load Base Components** (from SD 1.5):
   ```python
   tokenizer = CLIPTokenizer.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="tokenizer")
   text_encoder = CLIPTextModel.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="text_encoder")
   vae = AutoencoderKL.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="vae")
   scheduler = PNDMScheduler.from_pretrained("runwayml/stable-diffusion-v1-5", subfolder="scheduler")
   ```

2. **Load Fine-Tuned UNet** (from checkpoint):
   ```python
   unet = UNet2DConditionModel.from_pretrained(f"{checkpoint_path}/unet")
   ```

3. **Assemble Pipeline**:
   ```python
   pipe = StableDiffusionPipeline(
       vae=vae,
       text_encoder=text_encoder,
       tokenizer=tokenizer,
       unet=unet,
       scheduler=scheduler,
       ...
   )
   ```

#### 2. **Prompt Decoration**

The generator automatically adjusts prompt decoration based on model type:

**Standard SD 2.1**:
```python
# User input: "a cat"
# Full prompt: "a cat, black silhouette, high contrast, simple stencil design, centered in frame, complete object visible, isolated subject"
# Negative prompt: "color, colorful, photograph, realistic, detailed, complex"
```

**Fine-Tuned Checkpoint**:
```python
# User input: "a cat"
# Full prompt: "sketch of a cat"
# Negative prompt: None (not needed)
```

This is handled automatically in `Stencil.py`:
```python
if self.is_checkpoint_model:
    # For fine-tuned checkpoints, add "sketch of" prefix
    if add_stencil_suffix and not prompt.lower().startswith("sketch of"):
        full_prompt = f"sketch of {prompt}"
else:
    # For standard models, use stencil suffix
    if add_stencil_suffix:
        full_prompt = f"{prompt}, {self.stencil_suffix}"
```

---

## Results and Comparison

### Example Comparison

**Prompt**: "a cat"

**Standard SD 2.1**:
- Full prompt: "a cat, black silhouette, high contrast, simple stencil design, centered in frame..."
- Result: Stencil-like but may include shading, details, or color remnants
- Requires post-processing for clean results

**Checkpoint-1000**:
- Full prompt: "sketch of a cat"
- Result: Clean sketch lines, minimal shading, inherently sketch-style
- Post-processing optional

### When to Use Each Model


---

## Technical Details

### Training Script Location
- **Script**: [AI_Stencil_FineTuning.py](AI_Stencil_FineTuning.py)
- **Job Script**: [runjob.sh](runjob.sh)

### Base Model
- **Model**: [runwayml/stable-diffusion-v1-5](https://huggingface.co/runwayml/stable-diffusion-v1-5)
- **License**: CreativeML Open RAIL-M

### Dependencies
- PyTorch 2.0+
- Diffusers 0.20+
- Transformers 4.30+
- Accelerate
- xFormers (optional, for memory efficiency)

### Checkpoint Sizes
- Each checkpoint: ~3.5 GB (UNet only)
- Plus base SD 1.5 components: ~4 GB (downloaded on first use)
- Total storage per checkpoint: ~7.5 GB

---

## Future Improvements

Potential areas for enhancement:

1. **Extended Training**: Try 2-3 epochs with careful monitoring for overfitting
2. **Learning Rate Scheduling**: Use cosine annealing or warmup for better convergence
3. **Dataset Augmentation**: Horizontal flips, slight rotations for better generalization
4. **Multi-Resolution Training**: Train on multiple resolutions for flexibility
5. **LoRA Fine-Tuning**: Use Low-Rank Adaptation for smaller checkpoint sizes
6. **Custom Dataset**: Mix ImageNet-Sketch with custom stencil images for specific styles

---

## References

- **ImageNet-Sketch Dataset**: [GitHub](https://github.com/HaohanWang/ImageNet-Sketch)
- **Stable Diffusion**: [Stability AI](https://stability.ai/)
- **Diffusers Library**: [HuggingFace](https://huggingface.co/docs/diffusers/)
- **Compute Canada**: [computecanada.ca](https://www.computecanada.ca/)

---

**Last Updated**: October 2025
