# GPU Cluster Onboarding

This guide takes you from "my account was created" to "my own training job runs on a GPU".
Work through the steps in order. Each one ends with a ✅ check, so you know it worked before moving on.
Plan for about 30–45 minutes.

## What you already have

Your account was created from the access request form you filled in.

| | |
|---|---|
| Login node | `deep21.inf.u-szeged.hu` |
| Username | your **Neptun ID in lowercase**, e.g. `abc123` |
| How you log in | with the SSH key you pasted into the form (`~/.ssh/id_ed25519`). No password needed for deep21 |
| Home directory | `/shared/<username>` (also called `~` or `$HOME`) |
| Slurm account(s) | one for each course you ticked (see the table below) |
| GPU budget | **20 GPU-hours per course** you are enrolled in (see [step 7](#step-7--resources-and-your-gpu-budget)) |

| Course | Slurm account |
|---|---|
| MLOps | `mlops_2026_fall` |
| Deep Learning | `dl_2026_fall` |
| GPU programming | `gpu_2026_fall` |

Wherever this guide says `<your_account>`, use the account for the course the work belongs to.

How the pieces fit together:

```text
your computer ──ssh──> kabinet ──ssh──> deep21 ──sbatch──> Slurm ──> GPU compute node
                     (jump host)     (login node)                    (your job runs here)
```

* **kabinet** (`linux.inf.u-szeged.hu`) is the university jump host. You log in to it with your **h-account** (`hXXXXXX`).
  You can only reach the cluster through kabinet.
* **deep21** is the login node. Use it to edit files, install packages and submit jobs.
  **Do not train models or run other heavy work directly on deep21.** Send that work to Slurm as a job.

---

## Step 1 — Connect (~10 min)

Add this to your SSH config file. On Linux/macOS it is `~/.ssh/config`; on Windows it is `C:\Users\<you>\.ssh\config`, with no file extension.
Replace `h649999` with your own h-account and `abc123` with your own Neptun ID:

```sshconfig
Host kabinet
    HostName linux.inf.u-szeged.hu
    User h649999
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    HostkeyAlgorithms +ssh-rsa

Host deep21
    HostName deep21.inf.u-szeged.hu
    User abc123
    ProxyJump kabinet
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Then run `ssh deep21`. The first time, type `yes` when asked to trust a host, and enter your h-account password when kabinet asks for it.

✅ Your prompt changes to `abc123@deep21`, and `pwd` prints `/shared/abc123`.

👉 The full guide covers Windows details, VS Code, how to stop typing the kabinet password, copying files and troubleshooting: **[guides/connect.md](guides/connect.md)**

## Step 2 — Get the onboarding files (~2 min)

The scripts used in the next steps are in this repository. Clone it into your home directory on deep21.
Get the HTTPS address from the green **Code** button at the top of the repository page, then run:

```bash
cd ~
git clone <repository-address> ~/cluster-onboarding
ls ~/cluster-onboarding          # README.md, guides/, hello_cluster.sh, gpu_check.sh, job_template.sh, ...
```

The rest of this guide expects the files in `~/cluster-onboarding`, so keep that folder name.
When we update the material, get the latest version with `cd ~/cluster-onboarding && git pull`.
Don't edit files inside this folder, because local changes can make `git pull` fail. Copy them to your own project folder first, as step 5 shows.

✅ `ls ~/cluster-onboarding` lists the files above.

## Step 3 — Hello cluster (~5 min)

Your first job asks for one GPU for two minutes and prints where it ran:

```bash
cd ~
sbatch --account=<your_account> cluster-onboarding/hello_cluster.sh
#   -> Submitted batch job 12345
squeue --me                      # shows your job while it is pending (PD) or running (R)
cat hello_cluster-12345.out      # once it has finished (use your own job ID)
```

`sbatch` only puts the job in the queue. The `.out` file appears in the directory you submitted from once the job starts.

✅ The `.out` file shows a node name, your account and an `nvidia-smi` table with a GPU.

If the job disappears from `squeue` and there is no output file, check what happened with:
`sacct -j 12345 --format=JobID,State,ExitCode`

## Step 4 — Create your Python environment (~10 min)

Do this on deep21:

```bash
source /shared/anaconda/anaconda/bin/activate        # makes the conda command available
conda create -n dl python=3.12 -y                    # "dl" is the environment name; pick your own
conda activate dl
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126
```

Use the `cu126` build. Newer CUDA builds of PyTorch don't support the cluster's older GPUs (TITAN X).

Then check that the environment can see a GPU. This runs a short test job:

```bash
cd ~
sbatch --account=<your_account> cluster-onboarding/gpu_check.sh dl     # last argument = your environment name
```

✅ `gpu_check-<jobid>.out` contains `CUDA available: True` and `Matrix multiply on GPU: OK`.

👉 More on managing environments and packages: **[guides/environment.md](guides/environment.md)**

## Step 5 — Run your own job

```bash
mkdir -p ~/projects/myproject && cd ~/projects/myproject
cp ~/cluster-onboarding/job_template.sh .
nano job_template.sh          # edit the lines marked EDIT: account, environment, command, resources
sbatch job_template.sh
```

**Where are my results?**

* Everything your job prints goes to `<job-name>-<jobid>.out`, in the directory where you ran `sbatch`.
* Files your code writes (checkpoints, plots, CSVs) go wherever your code saves them. Relative paths start from that same directory.

👉 The available GPUs, choosing resources, monitoring jobs, interactive sessions and job arrays: **[guides/jobs.md](guides/jobs.md)**

## Step 6 — Where your files live

* Your home directory `/shared/<username>` holds your code, data and results. Your conda environments are kept under `/shared/anaconda/<username>/`.
* Storage is on redundant disks (RAID5), but **there is no backup**. Keep your code in Git/GitHub and copy important results to your own computer.
  A deleted file cannot be recovered.
* The disk is shared by everyone, so please use it sensibly: delete old checkpoints, don't keep several copies of a dataset,
  and run `conda clean --all` and `pip cache purge` now and then. To see what takes space: `du -sh ~/* ~/.cache | sort -h`
* Copy files to or from your computer (run this **on your computer**): `scp deep21:~/projects/myproject/results.csv .`
  You can also drag and drop files in VS Code.

## Step 7 — Resources and your GPU budget

* You have **20 GPU-hours per course**. GPU-hours = number of GPUs × how long the job actually runs.
  This is counted whether or not your code uses the GPU, so an idle interactive session still uses up your budget.
  The budget does not refill during the semester.
* **Always set `--time`.** A job only starts if `--time` × GPUs fits into the budget you have left.
  A job with no `--time`, or a `--time` longer than your remaining hours, **waits in the queue forever**.
* Limits per job and per person: at most **24 h** per job, **2 jobs running** at the same time and **8 CPU cores** across your running jobs.
  These count all your courses together. Only the 20 h budget is separate for each course.
* See how much you have used: `bash ~/cluster-onboarding/my_gpu_usage.sh`
* Ask for what you need: usually **1 GPU**, **4 CPUs**, **6 GB RAM** and a realistic `--time`. Smaller requests start sooner.
* Test with a short run (a few minutes, a small part of the data) before starting a long one.

👉 How the budget is counted, why a job is pending, and tips for saving GPU time: **[guides/accounting.md](guides/accounting.md)**

---

## Cheat sheet

| Command | What it does |
|---|---|
| `sbatch script.sh` | submit a job; prints its job ID |
| `squeue --me` | your queued (PD) and running (R) jobs |
| `scancel <jobid>` | cancel a job (`scancel -u $USER` cancels all your jobs) |
| `sacct -j <jobid> --format=JobID,State,Elapsed,ExitCode` | what happened to a job that has finished |
| `tail -f <name>-<jobid>.out` | follow a running job's output (Ctrl+C stops following, not the job) |
| `sinfo` | nodes and whether they are busy |
| `srun --account=<your_account> --gres=gpu:1 --time=00:30:00 --pty bash` | interactive shell on a GPU node (type `exit` when done) |
| `bash ~/cluster-onboarding/my_gpu_usage.sh` | GPU-hours you have used |

## Rules

1. No heavy computation on deep21. Use `sbatch` or `srun`.
2. Always set `--account` and `--time`.
3. Don't use `--nodelist` unless your instructor asks you to. Let Slurm choose a node.
4. Cancel jobs you no longer need, and leave interactive sessions as soon as you are done.
5. Use only your own account, and never share your **private** key (`id_ed25519` without `.pub`) with anyone.

## Need help?

1. Look in the **[FAQ](guides/faq.md)**. Most first-week problems are covered there.
2. Open an issue in **this repository** (the **Issues** tab at the top of the page).
   Include your username, the job ID, the job script and the error message. Never post your private key.
3. Email: `<SUPPORT_EMAIL>` <!-- TODO admin: support email -->
