#!/usr/bin/env bash
LOGFILE=$1

# Remove escape sequences for coloured formatting.
sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" $LOGFILE > job_output_full_nocolour.txt
# Check for success or fail
STATUS=$(grep "Final process status" job_output_full_nocolour.txt | awk '{ printf $NF }')

if [[ $STATUS == "success" ]]; then
    echo "=== PIPELINE  SUCCESFUL ==="
    exit 0
else
    echo "===   PIPELINE FAILED   ==="
fi
# Check which steps and workflows have failed.
echo First failed workflow, step and job:
grep "permanentFail" job_output_full_nocolour.txt | \
    grep "workflow" | \
    awk -F"[][]" '{ printf "%s\n",$2}' | \
    head -n 1 | \
    awk -F" " '{ printf "┬%s\n",$2}'

#echo First failed step:
grep "permanentFail" job_output_full_nocolour.txt | \
    grep "step" | \
    awk -F"[][]" '{ printf "%s\n",$2}' | \
    head -n 1 | \
    awk -F" " '{ printf "└─┬%s\n",$2}'

#echo First failed job:
grep "permanentFail" job_output_full_nocolour.txt | \
    grep "job" | \
    awk -F"[][]" '{ printf "%s\n",$2}' | \
    head -n 1 | \
    awk -F" " '{ printf "  └──%s\n",$2}'

