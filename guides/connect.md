# Connecting to the cluster

```text
your computer ──> linux.inf.u-szeged.hu (kabinet) ──> deep21.inf.u-szeged.hu
```

| Hop | Hostname | Username | How you log in |
|---|---|---|---|
| Jump host | `linux.inf.u-szeged.hu` | your h-account, e.g. `h649999` | h-account password (or a key, see [step 4](#4-optional-stop-typing-the-kabinet-password)) |
| Cluster | `deep21.inf.u-szeged.hu` | your Neptun ID, **lowercase**, e.g. `abc123` | the SSH key you pasted into the access form |

Forgot your h-account password? See the [SZTE password reset guide](https://www.inf.u-szeged.hu/~hferenc/files/progalap/jelszovaltas.pdf).

## 1. Check that you have your key

You need the **private** key that belongs to the public key you pasted into the form, on the computer you connect from.

```bash
# Linux / macOS
ls -l ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```
```powershell
# Windows PowerShell
ls $env:USERPROFILE\.ssh\id_ed25519*
```

* If your key has a different file name, use that name for `IdentityFile` below.
* If you want to connect from a second computer, copy the private key there safely (for example with a USB stick, not email).
  Or create a new key on that computer and send us the new `.pub` file (see [Need help?](../README.md#need-help)).
* If you lost the key, create a new one with `ssh-keygen -t ed25519` and send us the new **`.pub`** file.
  Never send the private key.

## 2. Create the SSH config file

**Linux / macOS**

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/config
```

**Windows (PowerShell)**

```powershell
$cfg = "$env:USERPROFILE\.ssh\config"
if (!(Test-Path $cfg)) { New-Item -ItemType File -Force $cfg | Out-Null }
notepad $cfg
```

The file must be named exactly `config`. Notepad sometimes saves it as `config.txt`, so check the name.

Paste this in, then replace `h649999` with your h-account and `abc123` with your Neptun ID (lowercase):

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

On Linux/macOS, also run `chmod 600 ~/.ssh/config ~/.ssh/id_ed25519`.

## 3. Connect

```bash
ssh deep21
```

1. The first time, SSH asks `Are you sure you want to continue connecting (yes/no)?`. Type `yes`. It may ask twice, once for each host.
2. Enter your **h-account password** when asked. That password is for kabinet.
3. You are logged in to deep21 with your key, without another password.

✅ The prompt shows `abc123@deep21`, and `pwd` prints `/shared/abc123`.

## 4. (Optional) Stop typing the kabinet password

Install the same key on kabinet. You do this once, and it asks for your h-account password one last time.

```bash
# Linux / macOS
ssh-copy-id -i ~/.ssh/id_ed25519.pub kabinet
```
```powershell
# Windows PowerShell (ssh-copy-id is not available on Windows)
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh kabinet "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

## 5. VS Code (Remote - SSH)

1. Install the **Remote - SSH** extension.
2. Press `Ctrl+Shift+P` (`Cmd+Shift+P` on macOS), choose **Remote-SSH: Connect to Host...**, then pick `deep21`.
   VS Code reads your `~/.ssh/config` and connects through kabinet automatically.
3. Open your project folder, e.g. `/shared/abc123/projects/myproject`.
4. To pick your conda environment as the Python interpreter, choose
   `/shared/anaconda/abc123/.conda/envs/<env>/bin/python`.

> ⚠️ VS Code runs on **deep21, the login node**, so its terminal is a login-node terminal.
> Use it to edit files and run `sbatch`, but don't start training there.

If VS Code hangs while connecting, it is usually waiting for the kabinet password.
Turn on the setting `remote.SSH.showLoginTerminal` so you can see the prompt, or do [step 4](#4-optional-stop-typing-the-kabinet-password).

## 6. Copying files

Run these **on your own computer**:

```bash
scp data.zip deep21:~/projects/myproject/          # upload a file
scp -r deep21:~/projects/myproject/results .       # download a folder
rsync -avP deep21:~/projects/myproject/results .   # Linux/macOS: faster for many files, can resume
```

In VS Code you can also drag files into the Explorer, or right-click a file and choose **Download**.
For your code, use Git rather than copying files back and forth.

## Troubleshooting

| What you see | Cause and fix |
|---|---|
| `Could not resolve hostname deep21` | SSH didn't find your config. Check that the file is called `config` (not `config.txt`) and is in your `.ssh` folder. |
| `Permission denied` right after typing your h-account password | Wrong h-account username or password. Test with `ssh kabinet` on its own. |
| `abc123@deep21...: Permission denied (publickey)` | Wrong username (it must be lowercase) or wrong key. Run `ssh -v deep21` to see which key is offered. It must be the one you pasted into the form. |
| `no matching host key type found` | The `HostkeyAlgorithms +ssh-rsa` line is missing from the `kabinet` section. |
| `Bad owner or permissions on ~/.ssh/config` | Linux/macOS: `chmod 600 ~/.ssh/config` |
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` | Linux/macOS: `chmod 600 ~/.ssh/id_ed25519`. Windows: run the two commands below. |
| `Connection timed out` | Check your internet connection and whether `ssh kabinet` works. |

Windows key permissions fix (PowerShell):

```powershell
icacls $env:USERPROFILE\.ssh\id_ed25519 /inheritance:r
icacls $env:USERPROFILE\.ssh\id_ed25519 /grant:r "$($env:USERNAME):(R)"
```
