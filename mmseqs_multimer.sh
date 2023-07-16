#!/usr/bin/env bash


#SBATCH -c 12 # number of cores
#SBATCH --mem 50G # memory pool for all cores
#SBATCH --job-name=MSA_mmseqs
#SBATCH -o slurm.%N.%j.out # STDOUT
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH --time 10:00:00

#time it start
start_time=$(date +%s)
#insert file name
FILE_NAME=$1
FILE=$(echo "$FILE_NAME" | awk -F"." '{print $(NF-1)}')

# directories
USER_HOMEDIR=/home/alphafold_user/carla/output
mkdir -p ${USER_HOMEDIR}/${FILE}/mmseqsruns
DB_PATH=/ibmm_data/alphafold_database
UNIREF90_db=${USER_HOMEDIR}/database_db


#format file in json
python msas_json --fasta_file ${FILE_NAME} --output_file ${USER_HOMEDIR}/${FILE}/${FILE}.json
python msas_multimer --json_file ${USER_HOMEDIR}/${FILE}.json  --output_dir ${USER_HOMEDIR}/${FILE}

#acces json of specific file
json=$(cat output/${FILE}/${FILE}.json)
#go to msas files
cd ${USER_HOMEDIR}/${FILE}/msas
#
for dir in ./*; do
  if [ -d "$dir" ]; then
    letter=$(basename "$dir")
    sequence=$(echo "$json" | jq -r '."'$letter'".sequence')
    description=$(echo "$json" | jq -r '."'$letter'".description')
    echo "> $description" > ${USER_HOMEDIR}/${FILE}/mmseqsruns/${letter}_seq
    echo $sequence >> ${USER_HOMEDIR}/${FILE}/mmseqsruns/${letter}_seq
    #cat ${USER_HOMEDIR}/${FILE}/mmseqsruns/${letter}_seq
    #fasta file redable by mmseqs
    mmseqs createdb  /home/alphafold_user/carla/${FILE_NAME} ${USER_HOMEDIR}/${FILE}/mmseqsruns/${letter}_seq
    #produce msas
    mmseqs search  ${USER_HOMEDIR}/${FILE}/mmseqsruns/${letter}_seq  ${UNIREF90_db}/uniref_db  ${USER_HOMEDIR}/${FILE}/mmseqsruns/${FILE}_re ${USER_HOMEDIR}/${FILE}/mmseqsruns/tmp --num-iterations 2 --max-seqs 100 

    #fasta
    mmseqs result2msa ${USER_HOMEDIR}/${FILE}/mmseqsruns/${letter}_seq  ${UNIREF90_db}/uniref_db  ${USER_HOMEDIR}/${FILE}/mmseqsruns/${FILE}_re  ${USER_HOMEDIR}/${FILE}/msas/bdf_uniref_hits.a3m --msa-format-mode 2
  fi
done



#job info 
end_time=$(date +%s)
printf 'Elapsed time is %d seconds\n' $((end_time - start_time)) >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
free -m -U alphafold_user| awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
df -h -U alphafold_user| awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
top -bn1 -U alphafold_user| grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
squeue -j ${SLURM_JOB_ID} -o '%C %M %t' >> ${USER_HOMEDIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt