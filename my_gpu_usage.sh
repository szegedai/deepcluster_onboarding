#!/usr/bin/env bash
# Shows how many GPU-hours you have used, per course account.
# Usage:  bash ~/cluster-onboarding/my_gpu_usage.sh [START_DATE]     e.g. 2026-10-01 (default: start of term)
#
# GPU-hours = GPUs allocated x time the job actually ran (running jobs count up to now).

START="${1:-2026-09-01}"
DEFAULT_LIMIT_HOURS=20

# Accounts you belong to, and the GPU limit Slurm has set for you (if any), e.g. "dl_2026_fall|gres/gpu=1200"
ASSOC=$(sacctmgr -n -P show assoc user="$USER" format=Account,GrpTRESMins 2>/dev/null)

# One line per job: account|elapsed seconds|allocated resources
JOBS=$(sacct -u "$USER" -S "$START" -E now -X -n -P -o Account,ElapsedRaw,AllocTRES 2>/dev/null)

echo "GPU usage for $USER since $START"
echo
{ echo "$ASSOC" | sed 's/^/A|/'; echo "$JOBS" | sed 's/^/J|/'; } |
awk -F'|' -v deflimit="$DEFAULT_LIMIT_HOURS" '
$1 == "A" && $2 != "" {
    acct[$2] = 1
    if (match($3, /gres\/gpu=[0-9]+/)) limit[$2] = substr($3, RSTART + 9, RLENGTH - 9) / 60
}
$1 == "J" && $2 != "" {
    acct[$2] = 1
    gpus = 0
    if (match($4, /gres\/gpu=[0-9]+/)) gpus = substr($4, RSTART + 9, RLENGTH - 9)
    used[$2] += gpus * $3 / 3600
    if (gpus > 0) njobs[$2]++
}
END {
    printf "%-20s %8s %10s %10s %10s\n", "Account", "GPU jobs", "Used (h)", "Limit (h)", "Left (h)"
    for (a in acct) {
        lim = (a in limit) ? limit[a] : deflimit
        printf "%-20s %8d %10.2f %10.1f %10.2f\n", a, njobs[a], used[a], lim, lim - used[a]
    }
}'
echo
echo "Details per job:  sacct -X -S $START -o JobID,JobName,Account,Elapsed,AllocTRES%45,State"
