"""
StencilCV - Traditional Computer Vision Approach to Stencil Generation

This module uses classical computer vision techniques (edge detection, contours,
thresholding) to convert images into clean stencils. No AI required - fast,
deterministic, and reliable.

Approaches:
1. Edge detection (Canny) - creates outline stencils
2. Contour extraction - creates filled silhouette stencils
3. Threshold-based - converts to binary black/white
"""

import cv2
import numpy as np
from PIL import Image
from typing import Union, Literal
import os


class StencilCV:
    """
    Computer vision-based stencil generator.

    Converts any input image (photo, drawing, etc.) into a clean stencil
    using traditional image processing techniques.
    """

    def __init__(self):
        """Initialize the StencilCV processor."""
        pass

    def load_image(self, image_path: str) -> np.ndarray:
        """
        Load an image from file.

        Args:
            image_path: Path to input image

        Returns:
            Image as numpy array (BGR format)
        """
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Could not load image from {image_path}")
        return img

    def from_pil(self, pil_image: Image.Image) -> np.ndarray:
        """
        Convert PIL Image to OpenCV format.

        Args:
            pil_image: PIL Image object

        Returns:
            Image as numpy array (BGR format)
        """
        # Convert PIL (RGB) to OpenCV (BGR)
        return cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)

    def to_pil(self, cv_image: np.ndarray) -> Image.Image:
        """
        Convert OpenCV image to PIL Image.

        Args:
            cv_image: OpenCV image (BGR or grayscale)

        Returns:
            PIL Image object
        """
        if len(cv_image.shape) == 2:  # Grayscale
            return Image.fromarray(cv_image)
        else:  # BGR to RGB
            return Image.fromarray(cv2.cvtColor(cv_image, cv2.COLOR_BGR2RGB))

    def edge_stencil(
        self,
        image: Union[str, np.ndarray, Image.Image],
        blur_kernel: int = 5,
        canny_low: int = 50,
        canny_high: int = 150,
        line_thickness: int = 2,
        invert: bool = False
    ) -> Image.Image:
        """
        Create outline stencil using Canny edge detection.
        Perfect for line art, coloring book style stencils.

        Args:
            image: Input image (path, numpy array, or PIL Image)
            blur_kernel: Gaussian blur kernel size (reduces noise)
            canny_low: Canny edge detection low threshold
            canny_high: Canny edge detection high threshold
            line_thickness: Thickness of edge lines
            invert: If True, white lines on black; if False, black lines on white

        Returns:
            PIL Image with edge-based stencil
        """
        # Load image
        if isinstance(image, str):
            img = self.load_image(image)
        elif isinstance(image, Image.Image):
            img = self.from_pil(image)
        else:
            img = image.copy()

        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (blur_kernel, blur_kernel), 0)

        # Apply Canny edge detection
        edges = cv2.Canny(blurred, canny_low, canny_high)

        # Dilate edges to make them thicker if requested
        if line_thickness > 1:
            kernel = np.ones((line_thickness, line_thickness), np.uint8)
            edges = cv2.dilate(edges, kernel, iterations=1)

        # Invert if needed (black on white by default)
        if not invert:
            edges = cv2.bitwise_not(edges)

        # Convert to RGB
        result = cv2.cvtColor(edges, cv2.COLOR_GRAY2RGB)

        return self.to_pil(result)

    def silhouette_stencil(
        self,
        image: Union[str, np.ndarray, Image.Image],
        threshold_method: Literal['otsu', 'adaptive', 'simple'] = 'otsu',
        threshold_value: int = 127,
        blur_kernel: int = 5,
        fill_holes: bool = True,
        remove_small_objects: int = 500,
        smooth_edges: bool = True
    ) -> Image.Image:
        """
        Create filled silhouette stencil using thresholding and contours.
        Perfect for solid stencils, like spray paint templates.

        Args:
            image: Input image (path, numpy array, or PIL Image)
            threshold_method: Method for thresholding ('otsu', 'adaptive', 'simple')
            threshold_value: Threshold value for 'simple' method (0-255)
            blur_kernel: Gaussian blur kernel size
            fill_holes: Fill holes in the silhouette
            remove_small_objects: Remove objects smaller than this (pixels)
            smooth_edges: Apply morphological smoothing to edges

        Returns:
            PIL Image with silhouette stencil
        """
        # Load image
        if isinstance(image, str):
            img = self.load_image(image)
        elif isinstance(image, Image.Image):
            img = self.from_pil(image)
        else:
            img = image.copy()

        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (blur_kernel, blur_kernel), 0)

        # Apply thresholding based on method
        if threshold_method == 'otsu':
            # Otsu's method automatically finds optimal threshold
            _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        elif threshold_method == 'adaptive':
            # Adaptive threshold - good for varying lighting
            binary = cv2.adaptiveThreshold(
                blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY, 11, 2
            )
        else:  # simple
            _, binary = cv2.threshold(blurred, threshold_value, 255, cv2.THRESH_BINARY)

        # Ensure we have black subject on white background
        # (Check if more white than black, invert if needed)
        if np.mean(binary) < 127:
            binary = cv2.bitwise_not(binary)

        # Remove small objects (noise)
        if remove_small_objects > 0:
            # Find contours
            contours, _ = cv2.findContours(
                cv2.bitwise_not(binary),
                cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE
            )

            # Filter contours by area and redraw
            mask = np.ones_like(binary) * 255
            for contour in contours:
                area = cv2.contourArea(contour)
                if area >= remove_small_objects:
                    cv2.drawContours(mask, [contour], -1, 0, -1)

            binary = mask

        # Fill holes in the silhouette
        if fill_holes:
            # Find contours
            contours, hierarchy = cv2.findContours(
                cv2.bitwise_not(binary),
                cv2.RETR_CCOMP,
                cv2.CHAIN_APPROX_SIMPLE
            )

            # Fill all contours (including holes)
            mask = np.ones_like(binary) * 255
            for i, contour in enumerate(contours):
                # Only draw external contours (fill holes)
                if hierarchy[0][i][3] == -1:  # External contour
                    cv2.drawContours(mask, [contour], -1, 0, -1)

            binary = mask

        # Smooth edges using morphological operations
        if smooth_edges:
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
            binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)
            binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel)

        # Convert to RGB
        result = cv2.cvtColor(binary, cv2.COLOR_GRAY2RGB)

        return self.to_pil(result)

    def hybrid_stencil(
        self,
        image: Union[str, np.ndarray, Image.Image],
        show_edges: bool = True,
        show_fill: bool = True,
        edge_thickness: int = 2
    ) -> Image.Image:
        """
        Create hybrid stencil with both edges and filled regions.
        Combines edge detection with silhouette for detailed stencils.

        Args:
            image: Input image (path, numpy array, or PIL Image)
            show_edges: Include edge lines
            show_fill: Include filled silhouette
            edge_thickness: Thickness of edge lines

        Returns:
            PIL Image with hybrid stencil
        """
        # Load image
        if isinstance(image, str):
            img = self.load_image(image)
        elif isinstance(image, Image.Image):
            img = self.from_pil(image)
        else:
            img = image.copy()

        # Start with white canvas
        result = np.ones_like(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)) * 255

        # Add filled silhouette if requested
        if show_fill:
            silhouette = self.silhouette_stencil(img)
            silhouette_cv = self.from_pil(silhouette)
            silhouette_gray = cv2.cvtColor(silhouette_cv, cv2.COLOR_BGR2GRAY)
            result = cv2.bitwise_and(result, silhouette_gray)

        # Add edges if requested
        if show_edges:
            edges = self.edge_stencil(img, line_thickness=edge_thickness, invert=True)
            edges_cv = self.from_pil(edges)
            edges_gray = cv2.cvtColor(edges_cv, cv2.COLOR_BGR2GRAY)
            result = cv2.bitwise_and(result, edges_gray)

        # Convert to RGB
        result_rgb = cv2.cvtColor(result, cv2.COLOR_GRAY2RGB)

        return self.to_pil(result_rgb)

    def auto_stencil(
        self,
        image: Union[str, np.ndarray, Image.Image],
        style: Literal['outline', 'filled', 'hybrid'] = 'filled'
    ) -> Image.Image:
        """
        Automatically create a stencil with sensible defaults.

        Args:
            image: Input image (path, numpy array, or PIL Image)
            style: Style of stencil ('outline', 'filled', 'hybrid')

        Returns:
            PIL Image with stencil
        """
        if style == 'outline':
            return self.edge_stencil(image)
        elif style == 'filled':
            return self.silhouette_stencil(image)
        else:  # hybrid
            return self.hybrid_stencil(image)

    def save(self, image: Image.Image, output_path: str):
        """
        Save stencil image to file.

        Args:
            image: PIL Image to save
            output_path: Path to save image
        """
        os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
        image.save(output_path)
        print(f"Saved stencil to: {output_path}")


def main():
    """Example usage demonstrating different stencil styles."""

    print("StencilCV - Computer Vision Stencil Generator")
    print("=" * 60)

    # Note: You'll need input images to test this
    # For now, let's create a simple example

    # Create a sample image (circle)
    print("\nCreating sample image...")
    sample = np.ones((512, 512, 3), dtype=np.uint8) * 255
    cv2.circle(sample, (256, 256), 100, (0, 0, 0), -1)
    sample_path = "sample_input.png"
    cv2.imwrite(sample_path, sample)
    print(f"Created sample image: {sample_path}")

    # Initialize processor
    processor = StencilCV()

    # Create output directory
    output_dir = "output_cv_stencils"
    os.makedirs(output_dir, exist_ok=True)

    # Example 1: Edge/Outline stencil
    print("\n1. Creating outline stencil...")
    outline = processor.edge_stencil(sample_path)
    processor.save(outline, f"{output_dir}/outline_stencil.png")

    # Example 2: Filled silhouette stencil
    print("2. Creating filled silhouette stencil...")
    filled = processor.silhouette_stencil(sample_path)
    processor.save(filled, f"{output_dir}/filled_stencil.png")

    # Example 3: Hybrid stencil
    print("3. Creating hybrid stencil...")
    hybrid = processor.hybrid_stencil(sample_path)
    processor.save(hybrid, f"{output_dir}/hybrid_stencil.png")

    print(f"\n{'=' * 60}")
    print(f"All stencils saved to: {output_dir}/")
    print("\nTo use with your own images:")
    print("  processor = StencilCV()")
    print("  stencil = processor.auto_stencil('your_image.jpg', style='filled')")
    print("  processor.save(stencil, 'output.png')")


if __name__ == "__main__":
    main()
