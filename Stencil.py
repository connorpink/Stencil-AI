"""
Stencil Image Generator using Stable Diffusion

This module provides a simple interface to generate drawing stencil images
using pretrained Stable Diffusion models with prompt engineering.
"""

import torch
from diffusers import StableDiffusionPipeline, DPMSolverMultistepScheduler
from PIL import Image
from typing import Optional, List, Union
import os


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
        device: Optional[str] = None,
        use_fp16: bool = True
    ):
        """
        Initialize the Stencil Generator.

        Args:
            model_id: HuggingFace model ID for Stable Diffusion model
            device: Device to run on ('cuda', 'cpu', or None for auto-detect)
            use_fp16: Whether to use half precision (FP16) for faster inference
        """
        self.model_id = model_id
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.use_fp16 = use_fp16 and self.device == "cuda"

        # Apply monkey-patch to fix transformers version compatibility
        _patch_clip_init()

        print(f"Loading model {model_id} on {self.device}...")

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

        print("Model loaded successfully!")

        # Default stencil prompt suffix
        self.stencil_suffix = (
            "drawing stencil, black and white, high contrast, simple lines, "
            "silhouette style, clean edges, no shading, flat design, "
            "vector art style, suitable for cutting"
        )

        # Default negative prompt to avoid unwanted features
        self.default_negative_prompt = (
            "color, colorful, shading, gradient, complex details, "
            "photorealistic, 3d, blurry, low quality, watermark"
        )

    def generate(
        self,
        prompt: str,
        negative_prompt: Optional[str] = None,
        num_images: int = 1,
        num_inference_steps: int = 25,
        guidance_scale: float = 7.5,
        width: int = 512,
        height: int = 512,
        seed: Optional[int] = None,
        add_stencil_suffix: bool = True,
    ) -> Union[Image.Image, List[Image.Image]]:
        """
        Generate stencil images based on the prompt.

        Args:
            prompt: Base text prompt describing what to draw
            negative_prompt: Things to avoid in the generation
            num_images: Number of images to generate
            num_inference_steps: Number of denoising steps (higher = better quality, slower)
            guidance_scale: How strongly to follow the prompt (7-8.5 recommended)
            width: Image width in pixels (must be divisible by 8)
            height: Image height in pixels (must be divisible by 8)
            seed: Random seed for reproducibility (None for random)
            add_stencil_suffix: Whether to automatically add stencil styling to prompt

        Returns:
            Single PIL Image if num_images=1, otherwise list of PIL Images
        """
        # Construct full prompt
        full_prompt = prompt
        if add_stencil_suffix:
            full_prompt = f"{prompt}, {self.stencil_suffix}"

        # Use default negative prompt if none provided
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
                negative_prompt=full_negative_prompt,
                num_images_per_prompt=num_images,
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                width=width,
                height=height,
                generator=generator,
            )

        images = result.images

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
        image = self.generate(prompt, num_images=1, **kwargs)
        self.save_image(image, output_path)
        return image


def main():
    """Example usage of the StencilGenerator"""

    # Initialize the generator
    generator = StencilGenerator(
        model_id="stabilityai/stable-diffusion-2-1-base",
        use_fp16=True  # Set to False if you don't have a CUDA GPU
    )

    # Example prompts
    prompts = [
        "a cat sitting",
        "a tree with spreading branches",
        "a bicycle",
        "a coffee cup",
    ]

    # Generate stencils
    output_dir = "output_stencils"
    os.makedirs(output_dir, exist_ok=True)

    for i, prompt in enumerate(prompts):
        print(f"\n{'='*50}")
        print(f"Generating stencil {i+1}/{len(prompts)}")

        output_path = os.path.join(output_dir, f"stencil_{i+1}_{prompt.replace(' ', '_')[:20]}.png")

        generator.generate_and_save(
            prompt=prompt,
            output_path=output_path,
            num_inference_steps=25,
            guidance_scale=7.5,
            seed=42 + i  # Different seed for each image
        )

    print(f"\n{'='*50}")
    print(f"All stencils saved to: {output_dir}/")


if __name__ == "__main__":
    main()
