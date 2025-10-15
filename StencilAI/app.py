"""
Gradio Web Interface for Stencil Image Generator

This module provides a web-based UI for the Stencil Generator using Gradio.
Run this file to launch the interactive web interface.
"""

import gradio as gr
from Stencil import StencilGenerator
import torch
from typing import Optional
import numpy as np


class StencilApp:
    """Wrapper class for the Gradio application."""

    def __init__(self):
        """Initialize the Stencil Generator."""
        self.generator = None

    def load_model(self):
        """Lazy load the model when first needed."""
        if self.generator is None:
            print("Initializing Stencil Generator...")
            self.generator = StencilGenerator(
                model_id="stabilityai/stable-diffusion-2-1-base",
                use_fp16=torch.cuda.is_available()
            )
        return self.generator

    def generate_stencil(
        self,
        prompt: str,
        negative_prompt: Optional[str],
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
        Generate a stencil image based on user inputs.

        This is the main function called by the Gradio interface.
        """
        if not prompt or prompt.strip() == "":
            return None, "Please enter a prompt!"

        try:
            # Load model if not already loaded
            generator = self.load_model()

            # Generate the image
            image = generator.generate(
                prompt=prompt,
                negative_prompt=negative_prompt if negative_prompt else None,
                num_images=1,
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                width=width,
                height=height,
                seed=seed if use_seed else None,
                add_stencil_suffix=add_stencil_suffix,
                clean_background=clean_background
            )

            return image, "Generation successful!"

        except Exception as e:
            return None, f"Error: {str(e)}"


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

                with gr.Accordion("Advanced Settings", open=False):
                    negative_prompt = gr.Textbox(
                        label="Negative Prompt (optional)",
                        placeholder="Things to avoid in the generation...",
                        lines=2
                    )

                    add_stencil_suffix = gr.Checkbox(
                        label="Add stencil styling (recommended)",
                        value=True,
                        info="Automatically adds stencil-specific styling to your prompt"
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
                # Output
                output_image = gr.Image(
                    label="Generated Stencil",
                    type="pil",
                    height=512
                )
                status_text = gr.Textbox(
                    label="Status",
                    interactive=False,
                    lines=1
                )

                gr.Markdown(
                    """
                    ### Tips for Best Results:
                    - Keep prompts simple and descriptive
                    - The AI automatically adds stencil styling
                    - Use negative prompts to avoid unwanted features
                    - Higher inference steps = better quality (but slower)
                    - Images are 512x512 by default (good balance of quality and speed)
                    """
                )

        # Connect the generate button
        generate_btn.click(
            fn=app.generate_stencil,
            inputs=[
                prompt,
                negative_prompt,
                num_inference_steps,
                guidance_scale,
                width,
                height,
                seed,
                use_seed,
                add_stencil_suffix,
                clean_background
            ],
            outputs=[output_image, status_text]
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
    launch(share=False)
