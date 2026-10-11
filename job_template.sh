#!/usr/bin/env bash
# Slurm job template.
# Copy it into your project folder, edit the lines marked EDIT, then submit with:
#   sbatch job_template.sh
# Lines starting with #SBATCH are read by Slurm. Keep them above the first command.
# More details: ~/cluster-onboarding/guides/jobs.md

# EDIT: a short name (shown in squeue and used in the log file name)
#SBATCH --job-name=my-job

# EDIT: your course account (mlops_2026_fall, dl_2026_fall or gpu_2026_fall)
#SBATCH --account=CHANGE_ME

# Number of GPUs. Delete this line for CPU-only work (then it uses no GPU budget).
#SBATCH --gres=gpu:1

# CPU cores (e.g. for DataLoader workers) and system RAM (not GPU memory).
# 6G fits on every machine; most machines only have 7-20 GB in total.
#SBATCH --cpus-per-task=4
#SBATCH --mem=6G

# EDIT: maximum run time, HH:MM:SS or D-HH:MM:SS (max 1-00:00:00). The job is stopped when it runs out.
# Required. The job only starts if time x GPUs fits into your remaining GPU budget.
#SBATCH --time=01:00:00

# Log file for everything the job prints. %x = job name, %j = job ID.
# Written in the directory you run sbatch from.
#SBATCH --output=%x-%j.out

echo "Job ${SLURM_JOB_ID} started on $(hostname) at $(date)"
echo "GPUs visible to this job: ${CUDA_VISIBLE_DEVICES:-none}"

# Load conda and activate your environment
source /shared/anaconda/anaconda/bin/activate
# EDIT: your environment name
conda activate myenv

# Make print() output appear in the log right away
export PYTHONUNBUFFERED=1

# Relative paths in your code start from the folder you submitted from
cd "$SLURM_SUBMIT_DIR"

# EDIT: what to run
python train.py

status=$?
echo "Job finished at $(date) with exit code ${status}"
exit ${status}
