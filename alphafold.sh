#!/usr/bin/env bash
#SBATCH --job-name=alphafold
#SBATCH -N 1 # number of nodes
#SBATCH -c 12 # number of cores
#SBATCH --mem 85G # memory pool for all cores
#SBATCH --gres=gpu:alphafold:1
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH --time 10:00:00
#srun ./monitor.sh

#get file by user
FILE_NAME=$1

DATE="1961-01-01"
#file name without extension

FILE=$(echo "$FILE_NAME" | awk -F"." '{print $(NF-1)}')
#get output directory and model type (monomer or mutlimer)
USER_HOMEDIR=/home/alphafold_user/carla
OUTPUT_DIR=${USER_HOMEDIR}/$3
MODEL=$2
DB_PATH=/ibmm_data/alphafold_database

echo "alphafold" > ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt


#IF monomer or Multimer
if [[ "$MODEL" != "multimer" ]]; then
    PDB_DATABASE_PATH="--pdb70_database_path=${DB_PATH}/pdb70/pdb70"
else
    PDB_DATABASE_PATH="--pdb_seqres_database_path=${DB_PATH}/pdb_seqres/pdb_seqres_fixed.txt --uniprot_database_path="${DB_PATH}"/uniprot/uniprot.fasta"
fi

#running job with  all FLAGS 
podman run --rm --security-opt=label=disable --hooks-dir=/usr/share/containers/oci/hooks.d/ \
  --mount 'type=bind,src='${DB_PATH}',dst='${DB_PATH} \
  --mount 'type=bind,src='${USER_HOMEDIR}',dst='${USER_HOMEDIR} \
  alphafold_2_3_1 --fasta_paths=${USER_HOMEDIR}/${FILE_NAME} \
  --use_precomputed_msas=true \
  --max_template_date=${DATE} \
  --output_dir=${OUTPUT_DIR} \
  --data_dir=${DB_PATH} \
  --use_gpu_relax=true --db_preset=full_dbs --model_preset=${MODEL} --run_relax=true --use_gpu_relax=true \
  --data_dir=${DB_PATH}/ --uniref90_database_path=${DB_PATH}/uniref90/uniref90.fasta \
  --mgnify_database_path=${DB_PATH}/mgnify/mgy_clusters_2022_05.fa --template_mmcif_dir=${DB_PATH}/pdb_mmcif/mmcif_files/ \
  --bfd_database_path=${DB_PATH}/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt \
  --obsolete_pdbs_path=${DB_PATH}/pdb_mmcif/obsolete.dat --uniref30_database_path=${DB_PATH}/uniref30/Uniref30_2022_02/UniRef30_2022_02 \
  --num_multimer_predictions_per_model=2 ${PDB_DATABASE_PATH}



#info on memory CPU load
free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
df -h | awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
top -bn1 | grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
squeue -j ${SLURM_JOB_ID} -o '%C %M' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
squeue -j ${SLURM_JOB_ID} -o '%A %C %M %t' --noheader | awk '{sum+=$2} END {avg=sum/NR; printf "Average CPU usage: %.2f\n", avg}' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
#!/usr/bin/env bash
#SBATCH --job-name=alphafold
#SBATCH -N 1 # number of nodes
#SBATCH -c 12 # number of cores
#SBATCH --mem 85G # memory pool for all cores
#SBATCH --gres=gpu:alphafold:1
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH --time 10:00:00
#srun ./monitor.sh

#get file by user
FILE_NAME=$1

DATE="1961-01-01"
#file name without extension

FILE=$(echo "$FILE_NAME" | awk -F"." '{print $(NF-1)}')
#get output directory and model type (monomer or mutlimer)
USER_HOMEDIR=/home/alphafold_user/carla
OUTPUT_DIR=${USER_HOMEDIR}/$3
MODEL=$2
DB_PATH=/ibmm_data/alphafold_database

echo "alphafold" > ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt


#IF monomer or Multimer
if [[ "$MODEL" != "multimer" ]]; then
    PDB_DATABASE_PATH="--pdb70_database_path=${DB_PATH}/pdb70/pdb70"
else
    PDB_DATABASE_PATH="--pdb_seqres_database_path=${DB_PATH}/pdb_seqres/pdb_seqres_fixed.txt --uniprot_database_path="${DB_PATH}"/uniprot/uniprot.fasta"
fi

#running job with  all FLAGS 
podman run --rm --security-opt=label=disable --hooks-dir=/usr/share/containers/oci/hooks.d/ \
  --mount 'type=bind,src='${DB_PATH}',dst='${DB_PATH} \
  --mount 'type=bind,src='${USER_HOMEDIR}',dst='${USER_HOMEDIR} \
  alphafold_2_3_1 --fasta_paths=${USER_HOMEDIR}/${FILE_NAME} \
  --use_precomputed_msas=true \
  --max_template_date=${DATE} \
  --output_dir=${OUTPUT_DIR} \
  --data_dir=${DB_PATH} \
  --use_gpu_relax=true --db_preset=full_dbs --model_preset=${MODEL} --run_relax=true --use_gpu_relax=true \
  --data_dir=${DB_PATH}/ --uniref90_database_path=${DB_PATH}/uniref90/uniref90.fasta \
  --mgnify_database_path=${DB_PATH}/mgnify/mgy_clusters_2022_05.fa --template_mmcif_dir=${DB_PATH}/pdb_mmcif/mmcif_files/ \
  --bfd_database_path=${DB_PATH}/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt \
  --obsolete_pdbs_path=${DB_PATH}/pdb_mmcif/obsolete.dat --uniref30_database_path=${DB_PATH}/uniref30/Uniref30_2022_02/UniRef30_2022_02 \
  --num_multimer_predictions_per_model=2 ${PDB_DATABASE_PATH}



#info on memory CPU load
free -m | awk 'NR==2{printf "Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
df -h | awk '$NF=="/"{printf "Disk Usage: %d/%dGB (%s)\n", $3,$2,$5}' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
top -bn1 | grep load | awk '{printf "CPU Load: %.2f\n", $(NF-2)}' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
squeue -j ${SLURM_JOB_ID} -o '%C %M' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
squeue -j ${SLURM_JOB_ID} -o '%A %C %M %t' --noheader | awk '{sum+=$2} END {avg=sum/NR; printf "Average CPU usage: %.2f\n", avg}' >> ${OUTPUT_DIR}/${FILE}/${FILE}_${SLURM_JOB_ID}_job_info.txt
