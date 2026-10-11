#!/usr/bin/env bash
#SBATCH --job-name=hello-cluster
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:02:00
#SBATCH --gres=gpu:1
#SBATCH --output=hello_cluster-%j.out

set -u

echo "Hello from the cluster."
echo "Job ID: ${SLURM_JOB_ID:-unknown}"
echo "Node: ${SLURMD_NODENAME:-unknown}"
echo "Account: ${SLURM_JOB_ACCOUNT:-unknown}"

if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "nvidia-smi is not available on this node."
fi