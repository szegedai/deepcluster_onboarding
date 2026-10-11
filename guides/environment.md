# Python environments (conda)

Conda is installed centrally at `/shared/anaconda/anaconda`. The environments you create are kept in
`/shared/anaconda/<username>/.conda/envs/`. Create and update them on deep21. Installing packages is light work, so that's fine on the login node.

## 1. Make conda available

```bash
source /shared/anaconda/anaconda/bin/activate
```

You need this in every new terminal **and in every job script**. To have it run automatically when you log in, add it to your `~/.bashrc`:
`echo 'source /shared/anaconda/anaconda/bin/activate' >> ~/.bashrc`

## 2. Create an environment

```bash
conda create -n dl python=3.12 -y
conda activate dl
conda env list            # lists your environments and where they are
```

Use one environment per course or project. `dl` is just an example name.

## 3. Install packages

Activate the environment first, then install with `pip`:

```bash
conda activate dl
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126
pip install numpy pandas matplotlib scikit-learn     # whatever your project needs
# or, if your project has one:  pip install -r requirements.txt
```

About PyTorch and CUDA:

* **Use the `cu126` build shown above.** The cluster has several GPU generations (see [jobs.md](jobs.md#the-gpus)).
  The newer `cu128` and `cu130` builds no longer support the oldest of them, the TITAN X.
  Those builds will run fine on the other GPUs, but you'd get `no kernel image is available` errors whenever your job lands on a TITAN X.
* You **don't** need to install CUDA separately, because the PyTorch packages include what they need.
* Install PyTorch with pip as shown. The old `conda install pytorch -c pytorch` channel is no longer maintained.

## 4. Test on a GPU

The login node is not where your code will run, so test inside a job:

```bash
cd ~
sbatch --account=<your_account> onboarding/gpu_check.sh dl
cat gpu_check-<jobid>.out
```

✅ It shows `CUDA available: True`, the GPU name and `Matrix multiply on GPU: OK`.
If you see `built for CUDA: None`, you installed a CPU-only PyTorch. Reinstall it with the command in step 3.

## 5. Use the environment in a job

Every job script needs these two lines before your `python` command (the [job template](../job_template.sh) already has them):

```bash
source /shared/anaconda/anaconda/bin/activate
conda activate dl
```

## Housekeeping

```bash
pip freeze > requirements.txt            # save your package list (commit it to Git)
conda env export > environment.yml       # full environment description
conda remove -n old_env --all            # delete an environment you no longer need
conda clean --all && pip cache purge     # free disk space from download caches
```
