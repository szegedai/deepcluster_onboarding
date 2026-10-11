# Running jobs with Slurm

You tell Slurm **what you need** (GPUs, CPU cores, memory, time) and **what to run**.
Slurm puts the job in a queue and starts it on a free compute node once both the resources and your budget allow it.
The job keeps running after you log out or close your laptop.

## The job script

Start from [`job_template.sh`](../job_template.sh): copy it into your project folder and edit the lines marked `EDIT`.
The `#SBATCH` lines are read by Slurm and must come before the first command in the script.

```bash
mkdir -p ~/projects/myproject && cd ~/projects/myproject
cp ~/onboarding/job_template.sh train.sh
nano train.sh
sbatch train.sh
```

Any option can also be given on the command line, where it overrides the script for that one run:
`sbatch --time=00:10:00 train.sh`

## The GPUs

The cluster is a mix of smaller machines, most with a single GPU:

| GPU type | GPU memory | How many | Machines | RAM per machine |
|---|---|---|---|---|
| `rtx2080ti` | 11 GB | 10 | deep1, deep3 (3 each), deep23, deep27–29 | 7–256 GB |
| `rtx3060` | 12 GB | 5 | deep05, deep09, deep11, deep24, deep30 | 7–20 GB |
| `rtx2080` | 8 GB | 4 | deep01–04 | 15–19 GB |
| `titanx` | 12 GB | 3 | deep22, deep25, deep26 | 7–12 GB |
| `a2000` | 6–12 GB | 2 | deep19, deep20 | 12–19 GB |
| `a5000` | 24 GB | 1 | deep1 | 125 GB |

* `--gres=gpu:1` gives you **any** free GPU. That is the fastest way to get started.
* If your model needs more GPU memory, ask for a type: `--gres=gpu:rtx3060:1`.
  There is only one `a5000`, so expect to wait for it.
* Most machines have only 7–20 GB of system RAM and 4–12 CPU cores. Large `--mem` or `--cpus-per-task` requests can only run on a few machines, so they wait longer.

## Choosing resources

| Option | What it means | Good starting point |
|---|---|---|
| `--account=<your_account>` | which course pays for the job | always set it |
| `--time=01:00:00` | longest the job may run (`HH:MM:SS` or `D-HH:MM:SS`). The job is stopped when the time is up | **always set it.** Use your best estimate plus ~20%, at most `1-00:00:00` (24 h) |
| `--gres=gpu:1` | number of GPUs | `1`. Remove the line for CPU-only work such as data preprocessing; that doesn't use GPU budget |
| `--cpus-per-task=4` | CPU cores, e.g. for data loading | `4`. Set PyTorch `DataLoader(num_workers=...)` to this number or lower |
| `--mem=6G` | system RAM (**not** GPU memory). Without this you get 2 GB per CPU core | `6G` fits on every machine. Increase it only if the job ends with `OUT_OF_MEMORY` |
| `--job-name=...` | name shown in `squeue` and in the log file name | something short you'll recognise |
| `--output=%x-%j.out` | log file: `%x` = job name, `%j` = job ID | keep the default |

**Limits** (these count all your courses together, unlike the GPU budget, which is separate for each course):

* At most **24 hours** per job.
* At most **2 of your jobs running** at the same time. Further jobs wait in the queue.
* At most **8 CPU cores** in total across your running jobs.

**`--time` and your budget.** A job only starts if `--time` × number of GPUs fits into the GPU budget you have left.
For example, with 3 GPU-hours left, a 1-GPU job with `--time=04:00:00` will wait forever, while `--time=02:30:00` starts.
A job **without** `--time` never starts. You are still only charged for the time the job **actually runs**.

## Submit, watch, cancel

```bash
sbatch train.sh                       # -> Submitted batch job 12345
squeue --me                           # ST column: PD = pending, R = running
tail -f train-12345.out               # follow the log live (Ctrl+C stops following, not the job)
srun --jobid=12345 --overlap --pty nvidia-smi   # see GPU usage of your running job
scancel 12345                         # cancel it
sacct -j 12345 --format=JobID,JobName,State,Elapsed,ExitCode,MaxRSS    # after it has ended
```

Common final states in `sacct`: `COMPLETED` (finished normally), `FAILED` (your program exited with an error, so check the log),
`TIMEOUT` (it ran out of `--time`), `OUT_OF_MEMORY` (raise `--mem`), `CANCELLED`.

## Where are my results?

* **The log file** (`--output`) is written **relative to the directory you ran `sbatch` from**.
  If you use a subfolder such as `--output=logs/%x-%j.out`, create the folder first (`mkdir -p logs`), because Slurm won't create it and the job fails without telling you.
* Errors go into the same log file, unless you also set `--error`.
* **Files your code writes** use paths relative to that same submission directory (also available as `$SLURM_SUBMIT_DIR`).
  A tidy pattern is to give every run its own folder, e.g. `runs/$SLURM_JOB_ID/`.
* If `print()` output only shows up when the job ends, Python is buffering it.
  The template sets `PYTHONUNBUFFERED=1` to fix this; otherwise use `python -u`.

## Interactive sessions (for debugging)

```bash
srun --account=<your_account> --gres=gpu:1 --cpus-per-task=4 --mem=6G --time=00:30:00 --pty bash
# ... you now have a shell on a GPU node: activate conda, run python, check nvidia-smi ...
exit      # gives the GPU back. Do this as soon as you're done
```

The session uses your GPU budget the whole time it is open, even if you're doing nothing. Use batch jobs for real training runs.

## Running several things

**Several scripts in one job.** They share the job's GPU, CPUs and memory, so watch the memory:

```bash
python run_a.py &
python run_b.py &
wait
```

**Job arrays.** Use these to run the same script with different settings, e.g. a hyperparameter sweep.
Each array task is a separate job and uses its own GPU time. Because of the per-person limit, at most 2 run at once:

```bash
#SBATCH --array=0-3
#SBATCH --output=%x-%A_%a.out
LRS=(0.1 0.01 0.001 0.0001)
python train.py --lr ${LRS[$SLURM_ARRAY_TASK_ID]}
```

## Save checkpoints

Save a checkpoint (model + optimizer + epoch) regularly, and make your script able to resume from it.
Then a job that reaches its time limit or fails doesn't lose all its work, and you don't spend your GPU budget a second time.
