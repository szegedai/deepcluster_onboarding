# FAQ and common errors

### Connecting
See the troubleshooting table in [connect.md](connect.md#troubleshooting).

### `git clone` asks for a username and password, or says `Repository not found`
Check that you copied the **HTTPS** address from the green **Code** button of the repository (it starts with `https://` and ends with `.git`).
If it still asks, contact us (see the end of this page).

### `git pull` fails with `Your local changes ... would be overwritten`
You edited a file inside `~/cluster-onboarding`. Copy your changed file somewhere else, then run `git checkout -- <file>` and `git pull` again.

### `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified`
The account name is wrong, or you're not a member of that course account. Check the spelling against the
[README table](../README.md#what-you-already-have) and list your accounts with `sacctmgr show assoc user=$USER format=Account%20`.

### `sbatch: error: Batch script contains DOS line breaks (\r\n)`
You edited the script on Windows. Convert it on deep21 with `sed -i 's/\r$//' myscript.sh`.
In VS Code you can also click `CRLF` in the bottom-right corner and switch it to `LF`.

### My job disappeared from `squeue` and there is no output file
* Check what happened: `sacct -j <jobid> --format=JobID,State,ExitCode`
* Does the folder in `--output` exist? Slurm doesn't create folders.
* Did you submit from a folder you can write to? Submit from `~` or your project folder.

### `print()` output appears only at the end, or not at all
Python buffers its output. Add `export PYTHONUNBUFFERED=1` to the script (the template has it), or run `python -u script.py`.

### `conda: command not found`, or `CondaError: Run 'conda init' before 'conda activate'`
Run `source /shared/anaconda/anaconda/bin/activate` first, in your terminal **and** in the job script.

### Conda asks me to accept Terms of Service (`CondaToSNonInteractiveError`)
Either accept them as the message describes, or create the environment from conda-forge instead:
`conda create -n dl -c conda-forge --override-channels python=3.12`

### `ModuleNotFoundError` in the job, but the import works on deep21
The job isn't using the same environment. Check the `conda activate <name>` line in your script and run `conda env list`.

### `torch.cuda.is_available()` is `False`
* Inside a job: did you request a GPU (`--gres=gpu:1`)?
* `python -c "import torch; print(torch.version.cuda)"` prints `None`: you have a CPU-only build.
  Reinstall it with the command in [environment.md](environment.md#3-install-packages).
* On deep21 itself this is expected. Test inside a job.

### `CUDA error: no kernel image is available for execution on the device`
Your PyTorch build doesn't support the GPU the job landed on, usually a TITAN X. Reinstall PyTorch with the `cu126`
command from [environment.md](environment.md#3-install-packages).
As a quick workaround, ask for a newer GPU type, e.g. `--gres=gpu:rtx3060:1`.

### `CUDA out of memory`
Your model or batch doesn't fit in **GPU** memory. Reduce the batch size or model size, or use mixed precision.
(`--mem` is system RAM and doesn't help with this.)

### Job state `OUT_OF_MEMORY`, or `oom-kill` in the log
Your job ran out of **system RAM**. Increase `--mem`, or load less data at once.

### Job state `TIMEOUT`
The job reached its `--time` limit. Increase `--time`, and save checkpoints so you can resume.

### My job has been pending for a long time
Look at the reason in `squeue --me`. The most common cause is a missing or too-long `--time`
(see [the `--time` rule](accounting.md#the---time-rule)). All reasons are explained in [accounting.md](accounting.md#why-is-my-job-still-pending).

### Can I use Jupyter notebooks?
For real work, move the code into a `.py` script and submit it as a job.
You can open notebooks in VS Code on deep21 for light editing or exploring results. They run on the login node, without a GPU.

### Can I use GitHub on the cluster?
Yes, and you should, because nothing on the cluster is backed up. Public repositories: `git clone https://github.com/...`.
For private repositories and pushing, create a separate key on deep21 (`ssh-keygen -t ed25519`) and add its `.pub`
to GitHub under Settings → SSH and GPG keys.

### I deleted a file by accident
There is no backup, so it can't be restored. Keep your code in Git and copy important results to your own computer.

### New laptop, or lost SSH key
See [connect.md, step 1](connect.md#1-check-that-you-have-your-key).

### Still stuck?
Open an issue in this repository (the **Issues** tab) or email `<SUPPORT_EMAIL>`. Include your username, the job ID, your script and the full error message.
