"""
Stencil Image Generator using Stable Diffusion

This module provides a simple interface to generate drawing stencil images
using pretrained Stable Diffusion models with prompt engineering.
"""

import torch
from diffusers import (
    StableDiffusionPipeline,
    DPMSolverMultistepScheduler,
    UNet2DConditionModel,
    AutoencoderKL,
    PNDMScheduler
)
from transformers import CLIPTextModel, CLIPTokenizer
from PIL import Image, ImageOps, ImageEnhance, ImageFilter
from typing import Optional, List, Union
import os
import numpy as np
from scipy import ndimage


def _patch_clip_init():
    """
    Monkey-patch CLIPTextModel.__init__ to ignore offload_state_dict parameter.
    This fixes compatibility issues between mismatched transformers versions.
    """
    try:
        from transformers import CLIPTextModel
        original_init = CLIPTextModel.__init__

        def patched_init(self, config, *args, **kwargs):
            # Remove the offload_state_dict parameter if it exists
            kwargs.pop('offload_state_dict', None)
            return original_init(self, config, *args, **kwargs)

        CLIPTextModel.__init__ = patched_init
    except ImportError:
        pass  # transformers not installed yet


class StencilGenerator:
    """
    A class to generate drawing stencil images using Stable Diffusion.

    This generator automatically appends stencil-specific prompt decorations
    to guide the model toward producing black and white stencil-style images.
    """

    def __init__(
        self,
        model_id: str = "stabilityai/stable-diffusion-2-1-base",
        # model_id: str = "runwayml/stable-diffusion-v1-5",
        checkpoint_path: Optional[str] = None,
        device: Optional[str] = None,
        use_fp16: bool = True
    ):
        """
        Initialize the Stencil Generator.

        Args:
            model_id: HuggingFace model ID for Stable Diffusion model (used if checkpoint_path is None)
            checkpoint_path: Path to fine-tuned checkpoint directory (e.g., "./checkpoint-1000")
                           If provided, loads fine-tuned model instead of pretrained model
            device: Device to run on ('cuda', 'cpu', or None for auto-detect)
            use_fp16: Whether to use half precision (FP16) for faster inference
        """
        self.model_id = model_id
        self.checkpoint_path = checkpoint_path
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.use_fp16 = use_fp16 and self.device == "cuda"
        self.is_checkpoint_model = checkpoint_path is not None

        # Apply monkey-patch to fix transformers version compatibility
        _patch_clip_init()

        # Load model based on whether checkpoint is provided
        if self.is_checkpoint_model:
            self._load_from_checkpoint(checkpoint_path)
        else:
            self._load_from_pretrained(model_id)

        print("Model loaded successfully!")

        # Set prompt decoration based on model type
        if self.is_checkpoint_model:
            # Fine-tuned models use simple "sketch of" prefix
            self.stencil_suffix = "Sketch of"
            self.default_negative_prompt = None
        else:
            # Standard SD 2.1 models use detailed stencil suffix
            self.stencil_suffix = (
                "black silhouette, high contrast, simple stencil design, "
                "centered in frame, complete object visible, isolated subject"
            )
            self.default_negative_prompt = (
                "color, colorful, photograph, realistic, detailed, complex, "
            )

    def _load_from_pretrained(self, model_id: str):
        """
        Load a pretrained model from HuggingFace.

        Args:
            model_id: HuggingFace model ID
        """
        print(f"Loading pretrained model {model_id} on {self.device}...")

        # Load the pipeline with version-compatible parameters
        dtype = torch.float16 if self.use_fp16 else torch.float32

        self.pipe = StableDiffusionPipeline.from_pretrained(
            model_id,
            torch_dtype=dtype,
            safety_checker=None,  # Disable for faster loading
        )

        # Use DPM-Solver for faster generation
        self.pipe.scheduler = DPMSolverMultistepScheduler.from_config(
            self.pipe.scheduler.config
        )

        self.pipe = self.pipe.to(self.device)

        # Enable memory optimizations
        if self.device == "cuda":
            self.pipe.enable_attention_slicing()
            # Uncomment if you have limited VRAM
            # self.pipe.enable_vae_slicing()

    def _load_from_checkpoint(self, checkpoint_path: str):
        """
        Load a fine-tuned model from checkpoint directory.

        Args:
            checkpoint_path: Path to checkpoint directory containing UNet
        """
        print(f"Loading fine-tuned checkpoint from {checkpoint_path} on {self.device}...")

        # Base model for standard components
        base_model = "runwayml/stable-diffusion-v1-5"

        print("Loading tokenizer...")
        tokenizer = CLIPTokenizer.from_pretrained(base_model, subfolder="tokenizer")

        print("Loading text encoder...")
        text_encoder = CLIPTextModel.from_pretrained(base_model, subfolder="text_encoder")

        print("Loading VAE...")
        vae = AutoencoderKL.from_pretrained(base_model, subfolder="vae")

        print("Loading scheduler...")
        scheduler = PNDMScheduler.from_pretrained(base_model, subfolder="scheduler")

        # Load fine-tuned UNet from checkpoint
        unet_path = f"{checkpoint_path}/unet"
        print(f"Loading fine-tuned UNet from {unet_path}...")
        unet = UNet2DConditionModel.from_pretrained(unet_path)

        # Assemble pipeline
        print("Assembling pipeline...")
        self.pipe = StableDiffusionPipeline(
            vae=vae,
            text_encoder=text_encoder,
            tokenizer=tokenizer,
            unet=unet,
            scheduler=scheduler,
            safety_checker=None,
            feature_extractor=None,
            requires_safety_checker=False
        )

        # Move to device with FP16 if enabled
        if self.device == "cuda":
            if self.use_fp16:
                self.pipe.vae = self.pipe.vae.to(self.device, dtype=torch.float16)
                self.pipe.text_encoder = self.pipe.text_encoder.to(self.device, dtype=torch.float16)
                self.pipe.unet = self.pipe.unet.to(self.device, dtype=torch.float16)
            else:
                self.pipe = self.pipe.to(self.device)
        else:
            self.pipe = self.pipe.to(self.device)

    def _clean_stencil_image(
        self,
        image: Image.Image,
        binary_threshold: int = 128,
        invert_if_needed: bool = True,
        remove_small_objects: bool = True,
        min_object_size: int = 100
    ) -> Image.Image:
        """
        Aggressively convert any image to a clean binary stencil.
        This uses Otsu's method and morphological operations to force
        a clean black silhouette on pure white background, regardless
        of what the model generated.

        Args:
            image: Input PIL Image
            binary_threshold: Threshold for binarization (0-255), 128 = middle
            invert_if_needed: Auto-detect if we need to invert (black on white vs white on black)
            remove_small_objects: Remove small noise/artifacts
            min_object_size: Minimum pixel area to keep (removes noise)

        Returns:
            Pure black and white stencil image
        """
        # Convert to grayscale first
        if image.mode != 'L':
            image = image.convert('L')

        # Convert to numpy array
        img_array = np.array(image)

        # Apply Otsu's method for automatic threshold detection
        # This finds the optimal threshold to separate foreground/background
        try:
            from skimage.filters import threshold_otsu
            binary_threshold = threshold_otsu(img_array)
        except ImportError:
            # Fall back to simple threshold if skimage not available
            binary_threshold = 128

        # Apply binary threshold - create stark black and white
        binary = img_array > binary_threshold

        # Decide if we need to invert (we want black subject on white background)
        if invert_if_needed:
            # Count pixels - if more white than black, we likely have black subject on white (correct)
            # If more black than white, we have white subject on black (need to invert)
            white_pixels = np.sum(binary)
            total_pixels = binary.size
            if white_pixels < total_pixels / 2:
                # More black than white - invert
                binary = ~binary

        # Remove small objects (noise/artifacts)
        if remove_small_objects:
            try:
                from scipy.ndimage import label, sum as ndi_sum
                # Label connected components
                labeled_array, num_features = label(~binary)  # Invert for labeling dark regions

                # Calculate size of each component
                component_sizes = ndi_sum(~binary, labeled_array, range(num_features + 1))

                # Remove small components
                mask_size = component_sizes < min_object_size
                remove_pixel = mask_size[labeled_array]
                binary[remove_pixel] = True  # Set to white (background)
            except ImportError:
                pass  # Skip if scipy not available

        # Apply slight morphological closing to fill small holes in the subject
        try:
            from scipy.ndimage import binary_closing
            binary = binary_closing(binary, structure=np.ones((3, 3)))
        except ImportError:
            pass

        # Convert boolean array to uint8 (True->255, False->0)
        result = (binary * 255).astype(np.uint8)

        # Convert back to PIL Image
        cleaned_image = Image.fromarray(result, mode='L').convert('RGB')

        return cleaned_image

    

    def generate(
        self,
        prompt: str,
        num_images: int = 1,
        negative_prompt: Optional[str] = None,
        num_inference_steps: int = 25,
        guidance_scale: float = 7.5,
        width: int = 512,
        height: int = 512,
        seed: Optional[int] = None,
        add_stencil_suffix: bool = True,
        clean_background: bool = True,
    ) -> Union[Image.Image, List[Image.Image]]:
        """
        Generate stencil images based on the prompt.

        Args:
            prompt: Base text prompt describing what to draw
            negative_prompt: Things to avoid in the generation
            num_images: Number of images to generate
            num_inference_steps: Number of denoising steps (higher = better quality, slower)
            guidance_scale: How strongly to follow the prompt (7-8 recommended)
            width: Image width in pixels (must be divisible by 8)
            height: Image height in pixels (must be divisible by 8)
            seed: Random seed for reproducibility (None for random)
            add_stencil_suffix: Whether to automatically add stencil styling to prompt
            clean_background: Whether to post-process into pure binary stencil (highly recommended)

        Returns:
            Single PIL Image if num_images=1, otherwise list of PIL Images
        """


        # Construct full prompt based on model type
        full_prompt = prompt
        if self.is_checkpoint_model:
            # For fine-tuned checkpoints, add "sketch of" prefix
            if add_stencil_suffix and not prompt.lower().startswith("sketch of"):
                full_prompt = f"sketch of {prompt}"
        else:
            # For standard models, use stencil suffix
            if add_stencil_suffix:
                full_prompt = f"{prompt}, {self.stencil_suffix}"

        # Use default negative prompt if none provided (None for checkpoint models)
        full_negative_prompt = negative_prompt or self.default_negative_prompt

        # Set seed if provided
        generator = None
        if seed is not None:
            generator = torch.Generator(device=self.device).manual_seed(seed)

        print(f"Generating {num_images} stencil image(s)...")
        print(f"Prompt: {full_prompt}")

        # Generate images
        with torch.autocast(self.device) if self.use_fp16 else torch.no_grad():
            result = self.pipe(
                prompt=full_prompt,
                num_images_per_prompt=num_images,
                negative_prompt=full_negative_prompt,
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                width=width,
                height=height,
                generator=generator,
            )

        images = result.images

        # Apply post-processing to clean background if enabled
        if clean_background:
            print("Cleaning background...")
            images = [self._clean_stencil_image(img) for img in images]

        print("Generation complete!")

        # Return single image or list
        return images[0] if num_images == 1 else images

    def save_image(
        self,
        image: Image.Image,
        output_path: str,
        create_dirs: bool = True
    ):
        """
        Save a generated image to disk.

        Args:
            image: PIL Image to save
            output_path: Path where to save the image
            create_dirs: Whether to create parent directories if they don't exist
        """
        if create_dirs:
            os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)

        image.save(output_path)
        print(f"Image saved to: {output_path}")

    def generate_and_save(
        self,
        prompt: str,
        output_path: str,
        num_images: int = 1,
        **kwargs
    ) -> Image.Image:
        """
        Generate a stencil image and save it to disk in one call.

        Args:
            prompt: Base text prompt describing what to draw
            output_path: Path where to save the image
            **kwargs: Additional arguments passed to generate()

        Returns:
            The generated PIL Image
        """
        image = self.generate(prompt, num_images, **kwargs)
        # Save single or multiple images
        # if numb images is 1, save directly, else save with index suffix
        if num_images == 1:
            self.save_image(image, output_path)
        else:
            for idx, img in enumerate(image):
                path = output_path.replace(".png", f"_{idx+1}.png")
                self.save_image(img, path)
        return image

