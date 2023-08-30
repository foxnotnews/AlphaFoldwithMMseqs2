#!/bin/bash
JOB_ID=$1
grep "Submitted batch job" ${LOG_DIR}/slurm.out.${JOB_ID}.txt
