"""
Gradio Web Interface for Stencil Image Generator

This module provides a web-based UI for the Stencil Generator using Gradio.
Run this file to launch the interactive web interface.
"""

import gradio as gr
from Stencil import StencilGenerator
from StencilCV import StencilCV
import torch
from typing import Optional
import numpy as np

MAX_IMAGES = 4

class StencilApp:
    """Wrapper class for the Gradio application."""

    def __init__(self):
        """Initialize the Stencil Generator."""
        self.generator = None
        self.current_model_type = None
        self.original_images = []  # Store original images for toggling
        self.outlined_status = []  # Track which images have outline applied

    def load_model(self, model_type: str = "Standard SD 2.1"):
        """
        Lazy load the model when first needed or reload if model type changed.

        Args:
            model_type: Type of model to load ("Standard SD 2.1", "Checkpoint-500", "Checkpoint-1000")
        """
        # Reload if model type changed or first load
        if self.generator is None or self.current_model_type != model_type:
            print(f"Initializing Stencil Generator with {model_type}...")

            # Determine checkpoint path based on model type
            checkpoint_path = None
            if model_type == "Checkpoint-500":
                checkpoint_path = "./Fine-tuning/checkpoint-500"
            elif model_type == "Checkpoint-1000":
                checkpoint_path = "./Fine-tuning/checkpoint-1000"

            self.generator = StencilGenerator(
                model_id="stabilityai/stable-diffusion-2-1-base",
                checkpoint_path=checkpoint_path,
                use_fp16=torch.cuda.is_available()
            )
            self.current_model_type = model_type

        return self.generator

    def generate_stencil(
        self,
        prompt: str,
        model_type: str,
        negative_prompt: Optional[str],
        num_images: int,
        num_inference_steps: int,
        guidance_scale: float,
        width: int,
        height: int,
        seed: int,
        use_seed: bool,
        add_stencil_suffix: bool,
        clean_background: bool
    ):
        """
        Generate stencil images based on user inputs.

        This is the main function called by the Gradio interface.
        """
        if not prompt or prompt.strip() == "":
            return [], "Please enter a prompt!"

        try:
            # Load model (will reload if model type changed)
            generator = self.load_model(model_type)

            # Generate the image(s)
            images = generator.generate(
                prompt=prompt,
                negative_prompt=negative_prompt if negative_prompt else None,
                num_images=num_images,
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                width=width,
                height=height,
                seed=seed if use_seed else None,
                add_stencil_suffix=add_stencil_suffix,
                clean_background=clean_background
            )

            # Ensure images is a list
            if not isinstance(images, list):
                images = [images]

            # Store original images and reset outlined status
            self.original_images = [img.copy() for img in images]
            self.outlined_status = [False] * len(images)

            return images, f"Generation successful! Created {len(images)} image(s)."

        except Exception as e:
            return [], f"Error: {str(e)}"

    def apply_outline(self, gallery_data, selected_index):
        """
        Toggle outline processing on a selected image using StencilCV.
        If the image has outline applied, revert to original. Otherwise, apply outline.

        Args:
            gallery_data: Gallery data from Gradio (list of images or tuples)
            selected_index: Index of the selected image (from gr.Gallery select event)

        Returns:
            Updated gallery and status message
        """
        # print(f"DEBUG: apply_outline called")
        # print(f"DEBUG: gallery_data type: {type(gallery_data)}")
        # print(f"DEBUG: gallery_data length: {len(gallery_data) if gallery_data else 0}")
        # print(f"DEBUG: selected_index: {selected_index}")

        if not gallery_data:
            return gallery_data, "No images to process!"

        # If there's only 1 image and no selection, default to index 0
        if selected_index is None:
            if len(self.original_images) == 1:
                selected_index = 0
            else:
                return gallery_data, "Please select an image first by clicking on it!"

        if selected_index >= len(self.original_images):
            return gallery_data, "Error: Image index out of range!"

        try:
            # Create a copy of the gallery data
            updated_gallery = list(gallery_data)

            # Check if this image already has outline applied
            if self.outlined_status[selected_index]:
                # Revert to original
                # print(f"DEBUG: Reverting image {selected_index} to original")
                updated_gallery[selected_index] = self.original_images[selected_index].copy()
                self.outlined_status[selected_index] = False
                return updated_gallery, f"Reverted image {selected_index + 1} to original."
            else:
                # Apply outline
                # print(f"DEBUG: Applying outline to image {selected_index}")

                # Initialize StencilCV processor
                processor = StencilCV()

                # Get the original image (not the gallery one, to ensure consistency)
                original_img = self.original_images[selected_index]

                # print(f"DEBUG: Applying edge_stencil...")
                # Apply outline to the original image
                outlined = processor.edge_stencil(original_img)
                # print(f"DEBUG: Outline applied successfully!")

                # Update gallery with outlined version
                updated_gallery[selected_index] = outlined
                self.outlined_status[selected_index] = True

                return updated_gallery, f"Applied outline to image {selected_index + 1}. Click again to revert."

        except Exception as e:
            import traceback
            print("DEBUG: Exception occurred:")
            traceback.print_exc()
            return gallery_data, f"Error applying outline: {str(e)}"


def create_interface():
    """Create and configure the Gradio interface."""

    app = StencilApp()

    # Define the interface
    with gr.Blocks(title="Stencil Image Generator", theme=gr.themes.Soft()) as interface:

        gr.Markdown(
            """
            # 🎨 Stencil Image Generator

            Generate black and white stencil-style images using AI. Perfect for creating
            cutting templates, vector art, and silhouette designs.
            """
        )

        with gr.Row():
            with gr.Column(scale=1):
                # Input controls
                prompt = gr.Textbox(
                    label="Prompt",
                    placeholder="e.g., a cat sitting, a tree with spreading branches...",
                    lines=3
                )

                model_selector = gr.Radio(
                    choices=["Standard SD 2.1", "Checkpoint-500", "Checkpoint-1000"],
                    value="Standard SD 2.1",
                    label="Model Type",
                    info="Choose between standard model or fine-tuned checkpoints (trained on sketch-style images)"
                )

                num_images = gr.Slider(
                    minimum=1,
                    maximum=MAX_IMAGES,
                    value=2,
                    step=1,
                    label="Number of Images",
                    info="Generate multiple variations to choose from"
                )

                with gr.Accordion("Advanced Settings", open=False):
                    negative_prompt = gr.Textbox(
                        label="Negative Prompt (optional)",
                        placeholder="Things to avoid in the generation...",
                        lines=2
                    )

                    add_stencil_suffix = gr.Checkbox(
                        label="Add stencil styling suffix(recommended)",
                        value=True,
                        info="Automatically adds stencil-specific styling to your prompt (prompt decorations)"
                    )

                    clean_background = gr.Checkbox(
                        label="Clean white background (recommended)",
                        value=True,
                        info="Post-process to ensure pure white background and remove artifacts"
                    )

                    num_inference_steps = gr.Slider(
                        minimum=10,
                        maximum=50,
                        value=25,
                        step=5,
                        label="Inference Steps",
                        info="Higher = better quality but slower"
                    )

                    guidance_scale = gr.Slider(
                        minimum=1,
                        maximum=15,
                        value=7.5,
                        step=0.5,
                        label="Guidance Scale",
                        info="How closely to follow the prompt (7-8 recommended)"
                    )

                    with gr.Row():
                        width = gr.Slider(
                            minimum=256,
                            maximum=1024,
                            value=512,
                            step=64,
                            label="Width"
                        )
                        height = gr.Slider(
                            minimum=256,
                            maximum=1024,
                            value=512,
                            step=64,
                            label="Height"
                        )

                    with gr.Row():
                        use_seed = gr.Checkbox(
                            label="Use fixed seed",
                            value=False,
                            info="Enable for reproducible results"
                        )
                        seed = gr.Number(
                            label="Seed",
                            value=42,
                            precision=0
                        )

                generate_btn = gr.Button("Generate Stencil", variant="primary", size="lg")

                # Example prompts
                gr.Examples(
                    examples=[
                        ["a cat sitting"],
                        ["a tree with spreading branches"],
                        ["a bicycle"],
                        ["a coffee cup"],
                        ["a bird in flight"],
                        ["a deer with antlers"],
                        ["a mountain landscape"],
                        ["a lighthouse by the sea"]
                    ],
                    inputs=prompt,
                    label="Example Prompts"
                )

            with gr.Column(scale=1):
                # Output - Gallery for multiple images
                output_gallery = gr.Gallery(
                    label="Generated Stencils (click to select)",
                    show_label=True,
                    columns=2,
                    rows=2,
                    height="auto",
                    object_fit="contain"
                )
                status_text = gr.Textbox(
                    label="Status",
                    interactive=False,
                    lines=1
                )

                # Hidden state to track selected image
                selected_image_index = gr.State(value=None)

                # Post-processing section
                with gr.Accordion("Post-Processing Options", open=False):
                    gr.Markdown(
                        """
                        **Outline Generation**: Click an image above to select it, then click the button below
                        to toggle outline processing. This creates a line-art effect and works best on images
                        with clear subjects. Click the button again to revert to the original.

                        You can toggle outline on/off for each image independently to compare styles.
                        """
                    )
                    apply_outline_btn = gr.Button("Toggle Outline on Selected Image", variant="secondary")

                gr.Markdown(
                    """
                    ### Tips for Best Results:
                    - Keep prompts simple and descriptive
                    - **Standard SD 2.1**: Best for general stencils with detailed prompt engineering
                    - **Checkpoint models**: Fine-tuned for sketch-style stencils (automatically adds "sketch of" prefix)
                    - Generate multiple images to see variations
                    - Use negative prompts to avoid unwanted features (works best with Standard SD 2.1)
                    - Try the outline option after generation for different styles
                    - Higher inference steps = better quality (but slower)
                    """
                )

        # Connect the generate button
        generate_btn.click(
            fn=app.generate_stencil,
            inputs=[
                prompt,
                model_selector,
                negative_prompt,
                num_images,
                num_inference_steps,
                guidance_scale,
                width,
                height,
                seed,
                use_seed,
                add_stencil_suffix,
                clean_background
            ],
            outputs=[output_gallery, status_text]
        )

        # Track when user selects an image in the gallery
        def update_selection(evt: gr.SelectData):
            print(f"DEBUG: Gallery selection event - index: {evt.index}")
            return evt.index

        output_gallery.select(
            fn=update_selection,
            outputs=selected_image_index
        )

        # Connect the outline button
        apply_outline_btn.click(
            fn=app.apply_outline,
            inputs=[output_gallery, selected_image_index],
            outputs=[output_gallery, status_text]
        )

        gr.Markdown(
            """
            ---
            Built with [Stable Diffusion](https://stability.ai/) and [Gradio](https://gradio.app/)
            """
        )

    return interface


def launch(
    share: bool = False,
    server_name: str = "0.0.0.0",
    server_port: int = 7860,
    **kwargs
):
    """
    Launch the Gradio interface.

    Args:
        share: Whether to create a public shareable link
        server_name: Server host (0.0.0.0 for public access)
        server_port: Port to run the server on
        **kwargs: Additional arguments passed to gradio.launch()
    """
    interface = create_interface()
    interface.launch(
        share=share,
        server_name=server_name,
        server_port=server_port,
        **kwargs
    )


if __name__ == "__main__":
    # Launch with default settings
    # Set share=True to create a public link
    launch(share=True, pwa=True)
