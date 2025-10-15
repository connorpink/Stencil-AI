from StencilCV import StencilCV
from Stencil import StencilGenerator
import os


def edgeDetection(processor, output_path, outline_path,):
    print("\n1. Creating outline stencil...")
    outline = processor.edge_stencil(output_path)
    processor.save(outline, outline_path)
    print(f"Outline stencil saved to: {outline_path}")

def main():
    """Example usage of the StencilGenerator with edge detection outlining"""

    # Initialize the generator
    generator = StencilGenerator(
        model_id="stabilityai/stable-diffusion-2-1-base",
        use_fp16=True  # Set to False if you don't have a CUDA GPU
    )
    processor = StencilCV()
    # Example prompts
    prompts = [
        "a cat sitting",
        "a tree with spreading branches",
        "a bicycle",
        "a coffee cup",
    ]
    NUM_IMAGES = 3
    # Generate stencils
    gen_output_dir = "output_stencils"
    outline_output_dir = "output_cv_stencils"

    os.makedirs(gen_output_dir, exist_ok=True)
    os.makedirs(outline_output_dir, exist_ok=True)

    for i, prompt in enumerate(prompts):
        print(f"\n{'='*50}")
        print(f"Generating stencil {i+1}/{len(prompts)}")

        output_path = os.path.join(gen_output_dir, f"stencil_{i+1}_{prompt.replace(' ', '_')[:20]}.png")

        generator.generate_and_save(
            prompt=prompt,
            output_path=output_path,
            num_images=NUM_IMAGES,
            num_inference_steps=25,
            guidance_scale=7.5,
            # seed=42 + i,  # Different seed for each image
            clean_background=True  # Enabled by default - converts to pure binary stencil
        )

        if NUM_IMAGES > 1:
            print(f"Generated {NUM_IMAGES} stencils saved to: {gen_output_dir}/stencil_{i+1}_{prompt.replace(' ', '_')[:20]}_*.png")
            for j in range(NUM_IMAGES):
                #define outline image path
                outline_path = os.path.join(outline_output_dir, f"outline_stencil_{i+1}_{prompt.replace(' ', '_')[:20]}_{j}.png")
                # run edge detection on each image
                edgeDetection(processor, output_path.replace(".png", f"_{j+1}.png"), outline_path)
        else:
            print(f"Generated stencil saved to: {output_path}")



    print(f"\n{'='*50}")
    print(f"All stencils saved to: {gen_output_dir}/")
    print(f"All outlines saved to: {outline_output_dir}/")



if __name__ == "__main__":
    main()
