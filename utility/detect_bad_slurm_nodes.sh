#!/bin/bash
# Searches for Slurm nodes that had issues completing toil jobs in the last six hours.
# Failures that are captured (purely based on experience):
# Reason: NODE_FAIL -- Slurm recognised that the node failed for whatever reason
# Exit code: 0:53 -- usually indicates that (a folder on) a file system is unreachable from the node
# Exit code: 1:0 -- some error
# State: CANCELLED by 0 -- job killed by root, indicating issues with the node like sssd having failed
TODAY=$(date +"%Y-%m-%d")
MAX_RUNTIME=30 # seconds until Failure
JOB_PATTERN="toil_job"

BAD_NODES=$(sacct -X -S now-6hour --format=JobID,JobName,State,NodeList,ElapsedRaw,ExitCode --noheader --parsable2 |
grep "$JOB_PATTERN" |
grep -E "NODE_FAIL|0:53|1:0|CANCELLED by 0" |
awk -F'|' -v max="$MAX_RUNTIME" '$5 < max { print $4 }' |
tr ',' '\n' |
sort -u |
paste -sd, -)
echo "$BAD_NODES"
