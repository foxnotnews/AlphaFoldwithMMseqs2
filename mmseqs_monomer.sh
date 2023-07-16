#!/usr/bin/env bash

#SBATCH -c 15 # number of cores
#SBATCH --mem 50G # memory pool for all cores
#SBATCH --job-name=MSA_mmseqs
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH -o slurm.%N.%j.out # STDOUT
#SBATCH --time 10:00:00


echo "mmseqs_running_monomer" > ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt


#insert file name
FILE_NAME=$1
FILE=$(echo "$FILE_NAME" | awk -F"." '{print $(NF-1)}')

#some directory
USER_HOMEDIR=/home/alphafold_user/carla/output
mkdir -p ${USER_HOMEDIR}/${FILE}/mmseqsruns
mkdir -p ${USER_HOMEDIR}/${FILE}/msas
DB_PATH=/ibmm_data/alphafold_database
UNIREF90_db=/home/alphafold_user/carla/database_db


#UNIREF90
#already created to gain some time in database_db
#mmseqs createdb ${DB_PATH}/uniref90/uniref90.fasta  ${USER_HOMEDIR}/${FILE}/mmseqsruns/uniref_db

#prepare file for mmseqs
mmseqs createdb  /home/alphafold_user/carla/${FILE_NAME} ${USER_HOMEDIR}/${FILE}/mmseqsruns/${FILE}_db

#produce msas
mmseqs search  ${USER_HOMEDIR}/${FILE}/mmseqsruns/${FILE}_db   ${UNIREF90_db}/uniref_db  ${USER_HOMEDIR}/${FILE}/mmseqsruns/${FILE}_re ${USER_HOMEDIR}/${FILE}/mmseqsruns/tmp --num-iterations 2 --max-seqs 100 

#fasta
mmseqs result2msa ${USER_HOMEDIR}/${FILE}/mmseqsruns/${FILE}_db   ${UNIREF90_db}/uniref_db  ${USER_HOMEDIR}/${FILE}/mmseqsruns/${FILE}_re  ${USER_HOMEDIR}/${FILE}/msas/bfd_uniref_hits.a3m --msa-format-mode 2


#create other msas files necessary for alphafold
python fake_msas.py --fasta_paths ${FILE_NAME} --output_dir ${USER_HOMEDIR}

#job info 
free -m  | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
df -h| awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
top -bn1 -U alphafold_user| grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
squeue -j ${SLURM_JOB_ID} -o '%C %M %t' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
squeue -j ${SLURM_JOB_ID} -o '%A %C %M %t' --noheader | awk '{sum+=$2} END {avg=sum/NR; printf "Average CPU usage: %.2f\n", avg}' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
