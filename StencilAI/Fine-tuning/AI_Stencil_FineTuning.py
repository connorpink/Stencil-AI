#!/usr/bin/env python3
"""
Stable Diffusion v1.5 Fine-tuning for Sketch Generation
Optimized for Compute Canada clusters with SLURM
"""

import os
import argparse
import torch
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
from pathlib import Path
from PIL import Image
from tqdm import tqdm
import json
from datetime import datetime

# Import diffusers components
from diffusers import (
    StableDiffusionPipeline,
    DDPMScheduler,
    UNet2DConditionModel,
    AutoencoderKL
)
from transformers import CLIPTextModel, CLIPTokenizer
from torchvision import transforms


class ImageNetSketchDataset(Dataset):
    """Dataset for ImageNet-Sketch images with proper synset label mapping"""
    
    def __init__(self, data_dir, resolution=512, max_samples=None, synset_mapping_file='imagenet_synset_to_label.json'):
        self.data_dir = Path(data_dir)
        self.resolution = resolution
        
        # Load or create synset to label mapping
        print(f"Loading synset to label mapping...")
        if os.path.exists(synset_mapping_file):
            with open(synset_mapping_file, 'r') as f:
                self.synset_to_label = json.load(f)
            print(f"✓ Loaded {len(self.synset_to_label)} mappings from {synset_mapping_file}")
        else:
            print(f"Mapping file not found. Creating from ImageNet class index...")
            self.synset_to_label = self._download_synset_mapping(synset_mapping_file)
        
        # Find all image files
        self.image_paths = []
        self.class_names = []
        
        print(f"\nLoading dataset from: {self.data_dir}")
        
        # Search for images in directory structure
        valid_extensions = {'.jpg', '.jpeg', '.png', '.JPEG', '.JPG', '.PNG'}
        
        # Track synset translations for display
        synset_translations = []
        
        for class_dir in sorted(self.data_dir.iterdir()):
            if class_dir.is_dir():
                synset_id = class_dir.name
                
                # Convert synset ID to human-readable label
                if synset_id in self.synset_to_label:
                    class_name = self.synset_to_label[synset_id]
                else:
                    # Fallback: use folder name with underscores replaced
                    class_name = synset_id.replace('_', ' ')
                    print(f"  Warning: No mapping found for {synset_id}, using raw name")
                
                # Store translation example
                if len(synset_translations) < 10:
                    synset_translations.append((synset_id, class_name))
                
                image_files = [f for f in class_dir.iterdir() 
                             if f.suffix in valid_extensions]
                
                for img_path in image_files:
                    self.image_paths.append(img_path)
                    self.class_names.append(class_name)
        
        # Limit dataset size if specified
        if max_samples and max_samples < len(self.image_paths):
            self.image_paths = self.image_paths[:max_samples]
            self.class_names = self.class_names[:max_samples]
        
        print(f"\nFound {len(self.image_paths)} images across {len(set(self.class_names))} classes")
        
        # Display sample translations
        print("\n" + "="*70)
        print("SYNSET ID → HUMAN-READABLE LABEL TRANSLATIONS")
        print("="*70)
        for synset_id, label in synset_translations:
            prompt = f"sketch of {label}"
            print(f"  {synset_id:12s} → {label:25s} → '{prompt}'")
        print("="*70 + "\n")
        
        # Transforms
        self.transforms = transforms.Compose([
            transforms.Resize(resolution, interpolation=transforms.InterpolationMode.BILINEAR),
            transforms.CenterCrop(resolution),
            transforms.ToTensor(),
            transforms.Normalize([0.5], [0.5])
        ])
    
    def _download_synset_mapping(self, output_file):
        """Download ImageNet synset to label mapping"""
        import urllib.request
        import json
        
        try:
            # Try to get from standard ImageNet class index
            url = "https://storage.googleapis.com/download.tensorflow.org/data/imagenet_class_index.json"
            print(f"  Downloading from: {url}")
            
            with urllib.request.urlopen(url) as response:
                data = json.loads(response.read().decode('utf-8'))
            
            # Convert to synset_id -> label mapping
            synset_to_label = {}
            for idx, (synset, label) in data.items():
                # Clean up label: replace underscores with spaces
                clean_label = label.replace('_', ' ')
                synset_to_label[synset] = clean_label
            
            # Save for future use
            with open(output_file, 'w') as f:
                json.dump(synset_to_label, f, indent=2)
            
            print(f"✓ Downloaded and saved {len(synset_to_label)} mappings to {output_file}")
            return synset_to_label
            
        except Exception as e:
            print(f"  Error downloading mapping: {e}")
            print(f"  You'll need to manually create {output_file}")
            return {}
    
    def __len__(self):
        return len(self.image_paths)
    
    def __getitem__(self, idx):
        img_path = self.image_paths[idx]
        class_name = self.class_names[idx]
        
        # Load and transform image
        try:
            image = Image.open(img_path).convert('RGB')
            image = self.transforms(image)
        except Exception as e:
            print(f"Error loading {img_path}: {e}")
            # Return a black image if loading fails
            image = torch.zeros(3, self.resolution, self.resolution)
        
        # Create prompt with human-readable class name
        prompt = f"sketch of {class_name}"
        
        return {
            "image": image,
            "prompt": prompt
        }


def collate_fn(batch):
    """Custom collate function for dataloader"""
    images = torch.stack([item["image"] for item in batch])
    prompts = [item["prompt"] for item in batch]
    return {"image": images, "prompt": prompts}


def encode_prompts(prompts, tokenizer, text_encoder, device):
    """Encode text prompts to embeddings"""
    text_inputs = tokenizer(
        prompts,
        padding="max_length",
        max_length=tokenizer.model_max_length,
        truncation=True,
        return_tensors="pt",
    )
    
    with torch.no_grad():
        text_embeddings = text_encoder(
            text_inputs.input_ids.to(device)
        )[0]
    
    return text_embeddings


def train(args):
    """Main training function"""
    
    # Setup device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")
    if torch.cuda.is_available():
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Save configuration
    config_path = os.path.join(args.output_dir, "training_config.json")
    with open(config_path, 'w') as f:
        json.dump(vars(args), f, indent=2)
    print(f"Saved config to {config_path}")
    
    # Load dataset
    print("\nLoading dataset...")
    dataset = ImageNetSketchDataset(
        data_dir=args.data_dir,
        resolution=args.resolution,
        max_samples=args.max_samples
    )
    
    dataloader = DataLoader(
        dataset,
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.num_workers,
        collate_fn=collate_fn,
        pin_memory=True
    )
    
    # Load models
    print("\nLoading models...")
    tokenizer = CLIPTokenizer.from_pretrained(args.model_id, subfolder="tokenizer")
    text_encoder = CLIPTextModel.from_pretrained(args.model_id, subfolder="text_encoder")
    vae = AutoencoderKL.from_pretrained(args.model_id, subfolder="vae")
    unet = UNet2DConditionModel.from_pretrained(args.model_id, subfolder="unet")
    noise_scheduler = DDPMScheduler.from_pretrained(args.model_id, subfolder="scheduler")
    
    # Enable memory optimizations
    if args.gradient_checkpointing:
        unet.enable_gradient_checkpointing()
        print("✓ Gradient checkpointing enabled")
    
    if args.use_xformers:
        try:
            unet.enable_xformers_memory_efficient_attention()
            print("✓ xFormers enabled")
        except Exception as e:
            print(f"Warning: Could not enable xFormers: {e}")
    
    # Freeze VAE and text encoder
    vae.requires_grad_(False)
    text_encoder.requires_grad_(False)
    
    # Move models to device
    vae = vae.to(device)
    text_encoder = text_encoder.to(device)
    unet = unet.to(device)
    
    # Use mixed precision
    if args.mixed_precision:
        vae = vae.half()
        text_encoder = text_encoder.half()
    
    vae.eval()
    text_encoder.eval()
    
    # Setup optimizer
    optimizer = torch.optim.AdamW(
        unet.parameters(),
        lr=args.learning_rate,
        betas=(0.9, 0.999),
        weight_decay=args.weight_decay,
        eps=1e-8
    )
    
    # Training loop
    print(f"\nStarting training for {args.num_epochs} epochs...")
    print(f"Total steps per epoch: {len(dataloader)}")
    print(f"Batch size: {args.batch_size}")
    print(f"Gradient accumulation steps: {args.gradient_accumulation_steps}")
    print(f"Effective batch size: {args.batch_size * args.gradient_accumulation_steps}\n")
    
    global_step = 0
    unet.train()
    
    for epoch in range(args.num_epochs):
        print(f"\n{'='*60}")
        print(f"Epoch {epoch + 1}/{args.num_epochs}")
        print(f"{'='*60}")
        
        epoch_loss = 0.0
        progress_bar = tqdm(dataloader, desc=f"Epoch {epoch+1}")
        
        for step, batch in enumerate(progress_bar):
            # Get batch
            images = batch["image"].to(device)
            prompts = batch["prompt"]
            
            # Encode images to latents
            with torch.no_grad():
                if args.mixed_precision:
                    with torch.cuda.amp.autocast():
                        latents = vae.encode(images).latent_dist.sample()
                else:
                    latents = vae.encode(images).latent_dist.sample()
                latents = latents * vae.config.scaling_factor
            
            # Encode prompts
            encoder_hidden_states = encode_prompts(prompts, tokenizer, text_encoder, device)
            
            # Sample noise
            noise = torch.randn_like(latents)
            bsz = latents.shape[0]
            
            # Sample timesteps
            timesteps = torch.randint(
                0, noise_scheduler.config.num_train_timesteps,
                (bsz,), device=device
            ).long()
            
            # Add noise to latents
            noisy_latents = noise_scheduler.add_noise(latents, noise, timesteps)
            
            # Predict noise
            if args.mixed_precision:
                with torch.cuda.amp.autocast():
                    model_pred = unet(noisy_latents, timesteps, encoder_hidden_states).sample
            else:
                model_pred = unet(noisy_latents, timesteps, encoder_hidden_states).sample
            
            # Compute loss
            if noise_scheduler.config.prediction_type == "epsilon":
                target = noise
            elif noise_scheduler.config.prediction_type == "v_prediction":
                target = noise_scheduler.get_velocity(latents, noise, timesteps)
            else:
                raise ValueError(f"Unknown prediction type {noise_scheduler.config.prediction_type}")
            
            loss = F.mse_loss(model_pred.float(), target.float(), reduction="mean")
            
            # Backward pass with gradient accumulation
            loss = loss / args.gradient_accumulation_steps
            loss.backward()
            
            if (step + 1) % args.gradient_accumulation_steps == 0:
                # Gradient clipping
                torch.nn.utils.clip_grad_norm_(unet.parameters(), args.max_grad_norm)
                
                # Optimizer step
                optimizer.step()
                optimizer.zero_grad()
                
                global_step += 1
            
            # Update metrics
            epoch_loss += loss.item() * args.gradient_accumulation_steps
            progress_bar.set_postfix({
                "loss": f"{loss.item() * args.gradient_accumulation_steps:.4f}",
                "step": global_step
            })
            
            # Save checkpoint
            if global_step % args.save_steps == 0 and global_step > 0:
                checkpoint_dir = os.path.join(args.output_dir, f"checkpoint-{global_step}")
                os.makedirs(checkpoint_dir, exist_ok=True)
                
                unet_save = unet
                unet_save.save_pretrained(os.path.join(checkpoint_dir, "unet"))
                
                print(f"\n✓ Saved checkpoint to {checkpoint_dir}")
            
            # Clear cache periodically
            if step % 100 == 0:
                torch.cuda.empty_cache()
        
        avg_epoch_loss = epoch_loss / len(dataloader)
        print(f"\nEpoch {epoch + 1} completed - Average loss: {avg_epoch_loss:.4f}")
        
        # Save epoch checkpoint
        epoch_checkpoint_dir = os.path.join(args.output_dir, f"epoch-{epoch+1}")
        os.makedirs(epoch_checkpoint_dir, exist_ok=True)
        unet.save_pretrained(os.path.join(epoch_checkpoint_dir, "unet"))
        print(f"✓ Saved epoch checkpoint to {epoch_checkpoint_dir}")
    
    # Save final model
    print("\n" + "="*60)
    print("Training completed! Saving final model...")
    print("="*60)
    
    # Create full pipeline
    pipeline = StableDiffusionPipeline.from_pretrained(
        args.model_id,
        unet=unet,
        text_encoder=text_encoder,
        tokenizer=tokenizer,
        vae=vae,
    )
    
    final_output_dir = os.path.join(args.output_dir, "final_model")
    pipeline.save_pretrained(final_output_dir)
    print(f"✓ Final model saved to {final_output_dir}")
    
    # Generate sample images
    if args.generate_samples:
        print("\nGenerating sample images...")
        pipeline = pipeline.to(device)
        
        validation_prompts = [
            "sketch of a cat",
            "sketch of a dog", 
            "sketch of a car",
            "sketch of a bird",
            "sketch of a tree"
        ]
        
        samples_dir = os.path.join(args.output_dir, "samples")
        os.makedirs(samples_dir, exist_ok=True)
        
        for i, prompt in enumerate(validation_prompts):
            image = pipeline(
                prompt,
                num_inference_steps=50,
                guidance_scale=7.5,
                generator=torch.Generator(device=device).manual_seed(42)
            ).images[0]
            
            image.save(os.path.join(samples_dir, f"sample_{i}_{prompt.replace(' ', '_')}.png"))
            print(f"  Generated: {prompt}")
        
        print(f"✓ Samples saved to {samples_dir}")
    
    print("\n" + "="*60)
    print("ALL DONE!")
    print("="*60)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fine-tune Stable Diffusion on ImageNet-Sketch")
    
    # Model arguments
    parser.add_argument("--model_id", type=str, default="runwayml/stable-diffusion-v1-5",
                       help="Pretrained model ID")
    parser.add_argument("--resolution", type=int, default=512,
                       help="Image resolution")
    
    # Data arguments
    parser.add_argument("--data_dir", type=str, required=True,
                       help="Path to ImageNet-Sketch dataset")
    parser.add_argument("--max_samples", type=int, default=None,
                       help="Maximum number of samples to use (for testing)")
    
    # Training arguments
    parser.add_argument("--output_dir", type=str, default="./output",
                       help="Output directory for checkpoints")
    parser.add_argument("--batch_size", type=int, default=1,
                       help="Training batch size")
    parser.add_argument("--gradient_accumulation_steps", type=int, default=8,
                       help="Gradient accumulation steps")
    parser.add_argument("--num_epochs", type=int, default=3,
                       help="Number of training epochs")
    parser.add_argument("--learning_rate", type=float, default=5e-6,
                       help="Learning rate")
    parser.add_argument("--weight_decay", type=float, default=0.01,
                       help="Weight decay")
    parser.add_argument("--max_grad_norm", type=float, default=1.0,
                       help="Max gradient norm for clipping")
    parser.add_argument("--save_steps", type=int, default=1000,
                       help="Save checkpoint every N steps")
    
    # Optimization arguments
    parser.add_argument("--mixed_precision", action="store_true",
                       help="Use mixed precision (FP16)")
    parser.add_argument("--gradient_checkpointing", action="store_true",
                       help="Enable gradient checkpointing")
    parser.add_argument("--use_xformers", action="store_true",
                       help="Use xformers for memory efficient attention")
    
    # Other arguments
    parser.add_argument("--num_workers", type=int, default=4,
                       help="Number of dataloader workers")
    parser.add_argument("--generate_samples", action="store_true",
                       help="Generate sample images after training")
    parser.add_argument("--seed", type=int, default=42,
                       help="Random seed")
    
    args = parser.parse_args()
    
    # Set random seed
    torch.manual_seed(args.seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(args.seed)
    
    # Run training
    train(args)