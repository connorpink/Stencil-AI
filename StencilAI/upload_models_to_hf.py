"""
Script to upload StencilAI model checkpoints to HuggingFace Hub.

This script uploads the fine-tuned model checkpoints to HuggingFace Hub
so they can be loaded remotely without storing them in the GitHub repo.

Usage:
    python upload_models_to_hf.py --token YOUR_HF_TOKEN

Environment variable:
    HF_TOKEN: Your HuggingFace token (alternative to --token argument)
"""

import os
import argparse
from pathlib import Path
from huggingface_hub import HfApi, create_repo


def upload_checkpoint(checkpoint_path: str, repo_name: str, token: str):
    """
    Upload a checkpoint directory to HuggingFace Hub.

    Args:
        checkpoint_path: Local path to checkpoint directory
        repo_name: Name of the HuggingFace repo (e.g., "mrpink925/stencilai-checkpoint-500")
        token: HuggingFace API token
    """
    checkpoint_path = Path(checkpoint_path)

    if not checkpoint_path.exists():
        raise ValueError(f"Checkpoint path does not exist: {checkpoint_path}")

    print(f"Uploading {checkpoint_path} to {repo_name}...")

    # Initialize HuggingFace API
    api = HfApi()

    # Create repository if it doesn't exist
    try:
        create_repo(
            repo_id=repo_name,
            token=token,
            repo_type="model",
            exist_ok=True
        )
        print(f"✓ Repository {repo_name} ready")
    except Exception as e:
        print(f"Warning: Could not create repo: {e}")

    # Upload the entire checkpoint directory
    print("Uploading files...")
    api.upload_folder(
        folder_path=str(checkpoint_path),
        repo_id=repo_name,
        repo_type="model",
        token=token,
        commit_message=f"Upload checkpoint from {checkpoint_path.name}"
    )

    print(f"✓ Successfully uploaded to https://huggingface.co/{repo_name}")


def main():
    parser = argparse.ArgumentParser(
        description="Upload StencilAI checkpoints to HuggingFace Hub"
    )
    parser.add_argument(
        "--token",
        type=str,
        default=None,
        help="HuggingFace API token (or set HF_TOKEN environment variable)"
    )
    parser.add_argument(
        "--checkpoint-500",
        type=str,
        default="./Fine-tuning/checkpoint-500",
        help="Path to checkpoint-500 directory"
    )
    parser.add_argument(
        "--checkpoint-1000",
        type=str,
        default="./Fine-tuning/checkpoint-1000",
        help="Path to checkpoint-1000 directory"
    )
    parser.add_argument(
        "--username",
        type=str,
        default="mrpink925",
        help="HuggingFace username"
    )

    args = parser.parse_args()

    # Get token from args or environment
    token = args.token or os.environ.get("HF_TOKEN")
    if not token:
        raise ValueError(
            "HuggingFace token is required. "
            "Provide it via --token argument or HF_TOKEN environment variable."
        )

    # Upload checkpoint-500
    print("\n" + "="*60)
    print("UPLOADING CHECKPOINT-500")
    print("="*60)
    upload_checkpoint(
        checkpoint_path=args.checkpoint_500,
        repo_name=f"{args.username}/stencilai-checkpoint-500",
        token=token
    )

    # Upload checkpoint-1000
    print("\n" + "="*60)
    print("UPLOADING CHECKPOINT-1000")
    print("="*60)
    upload_checkpoint(
        checkpoint_path=args.checkpoint_1000,
        repo_name=f"{args.username}/stencilai-checkpoint-1000",
        token=token
    )

    print("\n" + "="*60)
    print("✓ ALL CHECKPOINTS UPLOADED SUCCESSFULLY!")
    print("="*60)
    print("\nYour models are now available at:")
    print(f"  - https://huggingface.co/{args.username}/stencilai-checkpoint-500")
    print(f"  - https://huggingface.co/{args.username}/stencilai-checkpoint-1000")
    print("\nUpdate your code to use these model IDs instead of local paths.")


if __name__ == "__main__":
    main()
