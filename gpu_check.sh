#!/usr/bin/env bash
#SBATCH --job-name=gpu_check
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:05:00
#SBATCH --gres=gpu:1
#SBATCH --output=gpu_check-%j.out

# Checks that your conda environment can use the GPU.
# Usage (from your home directory):
#   sbatch --account=<your_account> onboarding/gpu_check.sh <conda_env_name>

ENV_NAME="${1:-}"
if [ -z "$ENV_NAME" ]; then
    echo "ERROR: give your conda environment name, e.g.:"
    echo "  sbatch --account=<your_account> onboarding/gpu_check.sh dl"
    exit 1
fi

echo "Job ${SLURM_JOB_ID:-?} on node ${SLURMD_NODENAME:-?}, account ${SLURM_JOB_ACCOUNT:-?}"

source /shared/anaconda/anaconda/bin/activate
if ! conda activate "$ENV_NAME"; then
    echo "ERROR: could not activate conda environment '$ENV_NAME' (see: conda env list)"
    exit 1
fi
echo "Python: $(which python)"

nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv

python - <<'EOF'
import sys
try:
    import torch
except ImportError:
    print("ERROR: PyTorch is not installed in this environment (see guides/environment.md)")
    sys.exit(1)

print("PyTorch:", torch.__version__, "| built for CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())
if not torch.cuda.is_available():
    sys.exit(1)
print("GPU:", torch.cuda.get_device_name(0))
x = torch.randn(4096, 4096, device="cuda")
y = x @ x
torch.cuda.synchronize()
print("Matrix multiply on GPU: OK")
EOF
