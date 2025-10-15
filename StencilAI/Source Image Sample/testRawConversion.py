import sys
import os
module_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if module_dir not in sys.path:
    sys.path.append(module_dir)
from StencilCV import StencilCV
from rich.console import Console

console = Console()
def edgeDetection(processor, input_image, outline_path, method='outline'):
    if (method not in ['outline', 'filled', 'hybrid']):
        console.print(f"Invalid method '{method}'. Defaulting to 'outline'.")
        method = 'outline'
    console.print("\n1. Creating outline stencil...")
    outline = processor.auto_stencil(input_image, style=method)
    processor.save(outline, outline_path)
    console.print(f"Outline stencil saved to: {outline_path}")

def main():
    """Example usage of the StencilGenerator with edge detection outlining"""

    processor = StencilCV()
    
    edgeDetection(processor, "./Cat_raw.png", "./Cat_filled_Outline.png", method='filled')




if __name__ == "__main__":
    main()
