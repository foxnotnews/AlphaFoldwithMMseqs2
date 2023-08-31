#!/usr/bin/env bash
#SBATCH --job-name=alphafold
#SBATCH -N 1 # number of nodes
#SBATCH -c 2 # number of cores
#SBATCH --mem 85G # memory pool for all cores
#SBATCH --gres=gpu:alphafold:1
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH --time 40:00:00

set -euo pipefail
EMAIL_ADDRESS=$1
FILE_NAME=$2
MODEL=$3
RELAXATION=$4
GPU_RELAXATION=$5
TEMPLATE_DATE=$6
NUM_PREDICTIONS=$7
ID=$8

echo "Continued job with Job_ID ${SLURM_JOB_ID}" >>${LOG_DIR}/slurm.error.${ID}.txt
cat ${LOG_DIR}/slurm.out.${ID}.txt >>${LOG_DIR}/slurm.out.${SLURM_JOB_ID}.txt
cat ${LOG_DIR}/slurm.error.${ID}.txt >>${LOG_DIR}/slurm.error.${SLURM_JOB_ID}.txt

#IF monomer or Multimer
if [[ "$MODEL" != "multimer" ]]; then
  PDB_DATABASE_PATH="--pdb70_database_path="${DB_HOMEDIR}"/pdb70/pdb70"

else
  PDB_DATABASE_PATH="--pdb_seqres_database_path="${DB_HOMEDIR}"/pdb_seqres/pdb_seqres_fixed.txt --uniprot_database_path="${DB_HOMEDIR}"/uniprot/uniprot.fasta"
fi

#running job with  all FLAGS
podman run --rm --security-opt=label=disable --hooks-dir=/usr/share/containers/oci/hooks.d/ \
  --mount 'type=bind,src='${DB_HOMEDIR}',dst='${DB_HOMEDIR} \
  --mount 'type=bind,src='${USER_HOMEDIR}',dst='${USER_HOMEDIR} \
  alphafold_2_3_1 --fasta_paths=${OUTPUT_DIR}/${ID}/file.fasta --output_dir=${OUTPUT_DIR}/${ID} \
  --max_template_date=$TEMPLATE_DATE --use_gpu_relax=$GPU_RELAXATION --db_preset=full_dbs --model_preset=$MODEL --run_relax=$RELAXATION --use_gpu_relax=$GPU_RELAXATION \
  --data_dir=${DB_HOMEDIR}/ --uniref90_database_path=${DB_HOMEDIR}/uniref90/uniref90.fasta \
  --mgnify_database_path=${DB_HOMEDIR}/mgnify/mgy_clusters_2022_05.fa --template_mmcif_dir=${DB_HOMEDIR}/pdb_mmcif/mmcif_files/ \
  --bfd_database_path=${DB_HOMEDIR}/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt \
  --obsolete_pdbs_path=${DB_HOMEDIR}/pdb_mmcif/obsolete.dat --uniref30_database_path=${DB_HOMEDIR}/uniref30/Uniref30_2022_02/UniRef30_2022_02 \
  --num_multimer_predictions_per_model=${NUM_PREDICTIONS} --use_precomputed_msas=true $PDB_DATABASE_PATH &&
echo "alphafold job" &&
echo $(squeue -j ${SLURM_JOB_ID} -o '"%A %T %r %M %V"') &&
echo $(squeue -j ${SLURM_JOB_ID} -o '%C %M') &&
mkdir ${ZIP_DIR}/${ID} &&
  cp ${LOG_DIR}/slurm.error.${SLURM_JOB_ID}.txt ${OUTPUT_DIR}/${ID}/slurm.error.${SLURM_JOB_ID}.txt &&
  cp ${LOG_DIR}/slurm.out.${ID}.txt ${OUTPUT_DIR}/${ID}/slurm.out.${SLURM_JOB_ID}.txt &&
  cd ${OUTPUT_DIR} &&
  zip -r -9 ${ZIP_DIR}/${ID}/full_output.zip ${ID} &&
  zip -9 ${ZIP_DIR}/${ID}/models.zip ${ID}/file/*.pdb &&
  printf "Your AlphaFold job with number ${ID} finished.\nUntil they get deleted in 14 days, you can download only the model .pdbs from inside the unibe network here:\nhttp://130.92.121.14:8000/${ID}/models.zip \nIf you want to download the whole folder with all the scores, you can download it here:\nhttp://130.92.121.14:8000/${ID}/full_output.zip \nMaybe you have to manually grant a permission to download from an unknown source.\nYou can find a list of useful tools to process the proteins further here:http://130.92.121.14:5001/tools\nIf you have a question, please send a request to the admins (jannik.gut@unibe.ch)" | mutt -s "Alphafold Job ${ID} Output" -- $EMAIL_ADDRESS &&
  rm -r ${OUTPUT_DIR}/${ID} || { # error
  printf "Your Job with ${ID} failed.\nIn the attachments is the error log.\nPlease check your inputs again, read the descriptions and if nothing else helps, check with the admins." | mutt -s "Failed Alphafold Job ${ID}" -c "jannik.gut@unibe.ch" -a ${LOG_DIR}/slurm.error.${ID}.txt -- ${EMAIL_ADDRESS}
}
