# GPU budget and accounting

## Your accounts

Each course is a Slurm **account**. You can use the accounts of the courses you ticked in the access form.
Always charge your work to the course it belongs to.

```bash
sacctmgr show assoc user=$USER format=Account%20,GrpTRESMins%30
```

## How GPU time is counted

You have **20 GPU-hours (1200 GPU-minutes) in each course account** you belong to.
The budget is personal (it is not shared with your classmates) and **does not refill** during the semester.

```text
GPU-hours used = number of GPUs × time the job actually ran
```

| Job | Uses |
|---|---|
| 1 GPU, ran 3 h | 3 GPU-hours |
| 2 GPUs, ran 3 h | 6 GPU-hours |
| 1 GPU, crashed after 2 min | 0.03 GPU-hours |
| interactive `srun` session with 1 GPU, left open and idle for 4 h | **4 GPU-hours** |
| CPU-only job (no `--gres=gpu`) | 0 GPU-hours |

You are charged for the time the GPU is **allocated** to you, whether or not your code uses it.

## The `--time` rule

Before Slurm starts a job, it checks that the job **could** run to its full `--time` without going over your budget:

```text
job starts only if   --time × GPUs  ≤  GPU budget you have left
```

* A job **without `--time`** never starts. It doesn't count as fitting into any budget.
* As your budget runs low, long `--time` requests stop starting. With 3 h left, `--time=04:00:00` waits forever, while `--time=02:30:00` starts.
* You are still only **charged** for the time the job actually runs. A job with `--time=05:00:00` that finishes after 1 h costs 1 GPU-hour.

## Check your usage

```bash
bash ~/onboarding/my_gpu_usage.sh                 # GPU-hours used, per account, since the start of term
bash ~/onboarding/my_gpu_usage.sh 2026-10-01      # ...or since a date you choose

# Slurm's own view of your limit and usage: GrpTRESMins=gres/gpu=<limit>(<used>), in minutes
scontrol show assoc_mgr users=$USER flags=assoc | grep -o 'GrpTRESMins=[^ ]*'
```

## Why is my job still pending?

`squeue --me` shows the reason in the last column:

| Reason | Meaning | What to do |
|---|---|---|
| `Priority` | other jobs are ahead of yours | wait |
| `Resources` | no GPU is free right now | wait. Your job starts as soon as one is |
| `AssocGrpGRESMinutes` (or another `...Minutes` reason) | the job's `--time` × GPUs is more than you have left, no `--time` was set, or your budget is used up | `scancel` the job and resubmit it with a shorter `--time`. If the budget is used up, contact your instructor |
| `QOSMaxJobsPerUserLimit` | you already have 2 jobs running | wait for one to finish |
| `QOSMaxCpuPerUserLimit` | your running jobs already use 8 CPU cores | wait, or ask for fewer `--cpus-per-task` |
| `QOSMaxWallDurationPerJobLimit` | `--time` is over 24 h | lower `--time` |
| `ReqNodeNotAvail` | you asked for a specific node that isn't available | remove `--nodelist` |

## Making your 20 hours last

* **Test small first.** Use a few minutes and a small part of the data with `--time=00:10:00` to catch bugs before a long run.
* **Never leave an interactive session open while idle.** Type `exit`.
* **Cancel** jobs that are clearly broken (loss is NaN, wrong config): `scancel <jobid>`.
* **Check that the GPU is actually busy**: `srun --jobid=<jobid> --overlap --pty nvidia-smi`. If utilisation stays near 0%, your code is probably running on the CPU or waiting on data loading.
* **Do preprocessing in CPU-only jobs** (remove the `--gres` line).
* **Save checkpoints**, so a crash or timeout doesn't mean starting again from zero.
* Ask for **1 GPU** unless your code really uses more than one.
