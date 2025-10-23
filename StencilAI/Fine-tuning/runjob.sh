#!/bin/bash
# JOB HEADERS HERE
#SBATCH --output=/home/mrpink/job_output/stencil_%j.out
#SBATCH --error=/home/mrpink/job_output/stencil_%j.err
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=4 
#SBATCH --mem=16GB               # memory per node
#SBATCH --time=0-08:00
#SBATCH --mail-user=cpinkster2@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --account=def-sykes-ac_gpu
echo "Starting job"

# IMPORTANT: Create logs directory BEFORE job starts
# (This needs to be done manually once, or in a setup script)

# Record start time
START_TIME=$(date +%s)

echo "======================================"
echo "Starting job on $(hostname) at $(date)"
echo "Job ID: $SLURM_JOB_ID"
echo "Working directory: $(pwd)"
echo "======================================"

# Print SLURM variables for debugging
echo "SLURM_JOB_ID: $SLURM_JOB_ID"
echo "SLURM_JOB_NAME: $SLURM_JOB_NAME"
echo "SLURM_SUBMIT_DIR: $SLURM_SUBMIT_DIR"
echo "SLURM_TMPDIR: $SLURM_TMPDIR"
echo "======================================"

# Set cache directories to scratch or project space
export HF_HOME=$SLURM_TMPDIR/huggingface_cache
export TRANSFORMERS_CACHE=$SLURM_TMPDIR/transformers_cache
export HF_DATASETS_CACHE=$SLURM_TMPDIR/datasets_cache

echo "Cache directories set:"
echo "  HF_HOME: $HF_HOME"
echo "  TRANSFORMERS_CACHE: $TRANSFORMERS_CACHE"
echo "  HF_DATASETS_CACHE: $HF_DATASETS_CACHE"
echo "======================================"

# Set dataset path
DATA_DIR="/scratch/mrpink/Downloads/imagenet-sketch/sketch"

# Set output directory with timestamp
OUTPUT_DIR="/scratch/mrpink/output/sd_sketch_$(date +%Y%m%d_%H%M%S)"

# Create output directory
mkdir -p $OUTPUT_DIR
echo "Created output directory: $OUTPUT_DIR"

# Copy the synset mapping file to output directory for reference
if [ -f "imagenet_synset_to_label.json" ]; then
    cp imagenet_synset_to_label.json $OUTPUT_DIR/
    echo "Copied synset mapping to output directory"
fi

# Print dataset info
echo "======================================"
echo "Dataset: $DATA_DIR"
echo "Dataset size: $(du -sh $DATA_DIR 2>/dev/null || echo 'Unable to check')"
echo "Output: $OUTPUT_DIR"
echo "======================================"

# Check if dataset exists
if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: Dataset directory not found: $DATA_DIR"
    exit 1
fi

# Check if synset mapping exists
if [ ! -f "/home/mrpink/AI_Stencil_Project/imagenet_synset_to_label.json" ]; then
    echo "WARNING: imagenet_synset_to_label.json not found!"
    echo "Make sure you've created the synset mapping file first."
    exit 1
fi

# Count images in dataset (for verification)
echo "Counting images in dataset..."
NUM_IMAGES=$(find $DATA_DIR -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l)
echo "Found $NUM_IMAGES images in dataset"
echo "======================================"

# Print GPU info
echo "GPU Information:"
nvidia-smi
echo "======================================"

# Print Python/Container info
echo "Container: /home/mrpink/containers/hybridmedimage.sif"
echo "Script: /home/mrpink/AI_Stencil_Project/AI_Stencil_FineTuning.py"
echo "======================================"

# Test container access
echo "Testing container access..."
/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/apptainer/1.3.5/bin/apptainer exec --nv \
    --env PYTHONNOUSERSITE=1 \
    --env SSL_CERT_FILE=/opt/conda/ssl/cert.pem \
    --env REQUESTS_CA_BUNDLE=/opt/conda/ssl/cert.pem \
    --env CURL_CA_BUNDLE=/opt/conda/ssl/cert.pem \
    --bind /tmp:/tmp \
    --bind /run/user:/run/user \
    --bind /local/scratch:/local/scratch \
    --bind /scratch/mrpink:/scratch/mrpink \
    /home/mrpink/containers/hybridmedimage.sif \
    python --version

echo "======================================"
echo "IMPROVED HYPERPARAMETERS FOR RETRAIN:"
echo "  - num_epochs: 1 (was 3) - prevents overfitting"
echo "  - learning_rate: 1e-6 (was 5e-6) - more stable"
echo "  - save_steps: 500 (was 1000) - more checkpoints"
echo "======================================"
echo "Starting training..."
echo "======================================"

# Run training with IMPROVED hyperparameters
/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/apptainer/1.3.5/bin/apptainer exec --nv \
    --env PYTHONNOUSERSITE=1 \
    --env SSL_CERT_FILE=/opt/conda/ssl/cert.pem \
    --env REQUESTS_CA_BUNDLE=/opt/conda/ssl/cert.pem \
    --env CURL_CA_BUNDLE=/opt/conda/ssl/cert.pem \
    --env HF_HOME=$HF_HOME \
    --env TRANSFORMERS_CACHE=$TRANSFORMERS_CACHE \
    --env HF_DATASETS_CACHE=$HF_DATASETS_CACHE \
    --bind /tmp:/tmp \
    --bind /run/user:/run/user \
    --bind /local/scratch:/local/scratch \
    --bind /scratch/mrpink:/scratch/mrpink \
    /home/mrpink/containers/hybridmedimage.sif \
    python /home/mrpink/AI_Stencil_Project/AI_Stencil_FineTuning.py \
        --data_dir $DATA_DIR \
        --output_dir $OUTPUT_DIR \
        --batch_size 1 \
        --gradient_accumulation_steps 8 \
        --num_epochs 1 \
        --learning_rate 1e-6 \
        --resolution 512 \
        --save_steps 500 \
        --mixed_precision \
        --gradient_checkpointing \
        --num_workers 4 \
        --generate_samples \
        --seed 42 \
        2>&1 | tee /home/mrpink/job_output/stencil_retrain.txt

# Capture exit code
TRAIN_EXIT_CODE=$?

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))
SECONDS=$((ELAPSED % 60))

echo "======================================"
echo "Training completed with exit code: $TRAIN_EXIT_CODE"
echo "Job completed at $(date)"
echo "Total runtime: ${HOURS}h ${MINUTES}m ${SECONDS}s"
echo "======================================"

# Print output directory contents
echo "Output directory contents:"
ls -lah $OUTPUT_DIR
echo "======================================"

# Check if samples were generated
if [ -d "$OUTPUT_DIR/samples" ]; then
    echo "Sample images generated:"
    ls -lah $OUTPUT_DIR/samples
else
    echo "WARNING: No samples directory found"
fi
echo "======================================"

# Print disk usage
echo "Output size: $(du -sh $OUTPUT_DIR)"
echo "======================================"

# Print loss trajectory from log
echo "Loss trajectory (last 20 lines with 'loss'):"
grep "loss" /home/mrpink/job_output/stencil_retrain.txt | tail -20
echo "======================================"

# Exit with the training script's exit code
exit $TRAIN_EXIT_CODE