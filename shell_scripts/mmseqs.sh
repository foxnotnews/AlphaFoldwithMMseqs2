#!/usr/bin/env bash
#SBATCH -c 12 # number of cores
#SBATCH --mem 100G # memory pool for all cores
#SBATCH --job-name=MSA_mmseqs
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH -o slurm.%N.%j.out # STDOUT
#SBATCH --time 12:00:00
####

EMAIL_ADDRESS=$1
FILE_NAME=$2
MODEL=$3
RELAXATION=$4
GPU_RELAXATION=$5
TEMPLATE_DATE=$6
NUM_PREDICTIONS=$7
SENSITIVITY=$8
MAX_SEQ=$9

##On the alphafold_job.sh OUTPUT_DIR is not define
mkdir ${OUTPUT_DIR}/${SLURM_JOB_ID} && mv $FILE_NAME ${OUTPUT_DIR}/${SLURM_JOB_ID}/file.fasta

cd ${OUTPUT_DIR}
#some directory
mkdir -p ${SLURM_JOB_ID}/file/mmseqsruns && mkdir -p ${SLURM_JOB_ID}/file/msas

#prepare file for mmseqs
mmseqs createdb ${OUTPUT_DIR}/${SLURM_JOB_ID}/file.fasta ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_db &&
    mmseqs touchdb ${DATABASE_DB}/uniref90/uniref_db &&
    mmseqs search ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_db ${DATABASE_DB}/uniref90/uniref_db ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_re tmp_mmseqs/${SLURM_JOB_ID} -s $8 --max-seqs $9 --db-load-mode 3 &&
    mmseqs result2msa ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_db ${DATABASE_DB}/uniref90/uniref_db ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_re ${SLURM_JOB_ID}/file/mmseqsruns/uniref_output --msa-format-mode 2 &&
    ##MGNIFY
    mmseqs touchdb ${DATABASE_DB}/mgnify/mgnify_db &&
    mmseqs search ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_db ${DATABASE_DB}/mgnify/mgnify_db ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_re2 tmp_mmseqs/${SLURM_JOB_ID} -s $8 --max-seqs $9 --db-load-mode 3 &&
    mmseqs result2msa ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_db ${DATABASE_DB}/mgnify/mgnify_db ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_re2 ${SLURM_JOB_ID}/file/mmseqsruns/mgnify_output --msa-format-mode 2 &&

    ##BFD
    #mmseqs touchdb ${DATABASE_db}/bdf/bdf_db &&
    #mmseqs search  ${SLURM_JOB_ID}/${FILE}/mmseqsruns/${FILE}_db   ${DATABASE_db}/bdf/bdf_db  ${SLURM_JOB_ID}/${FILE}/mmseqsruns/${FILE}_re3  tmp_mmseqs/${SLURM_JOB_ID}    --db-load-mode 3 &&
    #mmseqs result2msa ${SLURM_JOB_ID}/${FILE}/mmseqsruns/${FILE}_db   ${DATABASE_db}/bdf/bdf_db  ${SLURM_JOB_ID}/${FILE}/mmseqsruns/${FILE}_re3  ${SLURM_JOB_ID}/${FILE}/msas/bfd_output --msa-format-mode 2 &&

    # MULTIMER
    if [[ "$MODEL" != "multimer" ]]; then
        ###merge all UNIREF magnify
        cat ${SLURM_JOB_ID}/file/mmseqsruns/mgnify_output >>${SLURM_JOB_ID}/file/mmseqsruns/uniref_output &&
            #####if mutiple masas from different database must be merged#####
            ##remove null lines to check correctly
            tr <${SLURM_JOB_ID}/file/mmseqsruns/uniref_output -d '\000' >${SLURM_JOB_ID}/file/msas/bfd_uniref_hits.a3m &&
            #create other msas files necessary for alphafold
            python ${USER_HOMEDIR}/Alphafold-Website/python_scripts/mmseqs_monomer.py --fasta_paths ${OUTPUT_DIR}/${SLURM_JOB_ID}/file.fasta --output_dir ${OUTPUT_DIR}/${SLURM_JOB_ID}
    else
        ##UNIRPOT
        mmseqs touchdb ${DATABASE_DB}/uniprot/uniprot_db &&
            mmseqs search ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_db ${DATABASE_DB}/uniprot/uniprot_db ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_re4 -s $8 --max-seqs $9 tmp_mmseqs/${SLURM_JOB_ID} --db-load-mode 3 &&
            #fasta
            mmseqs result2msa ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_db ${DATABASE_DB}/uniprot/uniprot_db ${SLURM_JOB_ID}/file/mmseqsruns/mmseqs_re4 ${SLURM_JOB_ID}/file/mmseqsruns/uniprot_output --msa-format-mode 2 &&

            #Which file do you have bfd_uniref_hits.a3m  mgnify_hits.sto  uniprot_hits.sto  uniref90_hits.sto
            FILE_OUTPUT=("uniref_output" "mgnify_output" "uniprot_output") && # "bfd_output"
            #format file in json
            python ${USER_HOMEDIR}/Alphafold-Website/python_scripts/msas_json.py --fasta_file ${OUTPUT_DIR}/${SLURM_JOB_ID}/file.fasta --output_file ${OUTPUT_DIR}/${SLURM_JOB_ID}/file/msas/chain_id_map.json &&

            # Get the starting sequence  from the JSON file
            starting_sequence=$(jq -r '.A.sequence' "${SLURM_JOB_ID}/file/msas/chain_id_map.json") &&
            starting_descritpion=$(jq -r '.A.description' ${SLURM_JOB_ID}/file/msas/chain_id_map.json) &&
            letters=$(jq -r 'keys[]' "${SLURM_JOB_ID}/file/msas/chain_id_map.json") &&
            #loop through all different types of files for each different directory
            for file in "${FILE_OUTPUT[@]}"; do
                before_letter=A &&
                    last_letter=$(jq -r 'keys[-1]' "${SLURM_JOB_ID}/file/msas/chain_id_map.json") &&
                    starting_sequence=$(jq -r '.A.sequence' "${SLURM_JOB_ID}/file/msas/chain_id_map.json") &&
                    starting_descritpion=$(jq -r '.A.description' ${SLURM_JOB_ID}/file/msas/chain_id_map.json) &&
                    for letter in $letters; do
                        mkdir -p ${SLURM_JOB_ID}/file/msas/${letter} &&
                            #if it's the first letter create directory and file then pass
                            if [ "$letter" == "A" ]; then
                                echo ">$starting_descritpion" >${SLURM_JOB_ID}/file/msas/${letter}/$file &&
                                    continue # Skip to the next iteration of the loop
                            fi &&
                            #get name and seq of the  current letter directory
                            new_description=$(jq -r '."'$letter'".description' ${SLURM_JOB_ID}/file/msas/chain_id_map.json) &&
                            new_sequence=$(jq -r '."'$letter'".sequence' ${SLURM_JOB_ID}/file/msas/chain_id_map.json) &&
                            #add this name to its corresponding output  file
                            echo ">$new_description" >${SLURM_JOB_ID}/file/msas/${letter}/$file &&
                            #catch the previous sequence output msas and add it to the previous letter output file
                            sed -n "/${starting_sequence}/,/>${new_description}/{/>${new_description}/q;p}" ${SLURM_JOB_ID}/file/mmseqsruns/$file >>${SLURM_JOB_ID}/file/msas/${before_letter}/$file &&
                            #update current step
                            starting_sequence=$new_sequence &&
                            before_letter=$letter &&
                            #if it's last letter
                            if [ "$letter" == "$last_letter" ]; then
                                descritpion=$(jq -r '."'$letter'".description' "${SLURM_JOB_ID}/file/msas/chain_id_map.json") &&
                                    sequence=$(jq -r '."'$letter'".sequence' "${SLURM_JOB_ID}/file/msas/chain_id_map.json") &&
                                    sed -n "/$sequence/,\$p" ${SLURM_JOB_ID}/file/mmseqsruns/$file >>${SLURM_JOB_ID}/file/msas/${letter}/$file
                            fi
                    done
            done

        ##concanate all files
        for letter in $letters; do
            description=$(jq -r '."'$letter'".description' "${SLURM_JOB_ID}/file/msas/chain_id_map.json") &&
                #merge bfd with uniref
                cat ${SLURM_JOB_ID}/file/msas/${letter}/mgnify_output >>${SLURM_JOB_ID}/file/msas/${letter}/uniref_output &&
                cat ${SLURM_JOB_ID}/file/msas/${letter}/uniprot_output >>${SLURM_JOB_ID}/file/msas/${letter}/uniref_output &&
                #remove eventual empty lines
                tr -d '\000' <"${SLURM_JOB_ID}/file/msas/${letter}/uniref_output" | grep -v '^$' >"${SLURM_JOB_ID}/file/msas/${letter}/bfd_uniref_hits.a3m"
        done &&

            #create  other fake msa mgnify and uniref90 , uniref for each seqs
            python ${USER_HOMEDIR}/Alphafold-Website/python_scripts/msa_multimer.py --json_file ${OUTPUT_DIR}/${SLURM_JOB_ID}/file/msas/chain_id_map.json --output_dir ${OUTPUT_DIR}/${SLURM_JOB_ID}/file

    fi &&
    rm -r ${OUTPUT_DIR}/tmp_mmseqs/${SLURM_JOB_ID}/* &&
    echo "mmseqs job" &&
    echo $(squeue -j ${SLURM_JOB_ID} -o '"%A %T %r %M %V"') &&
    echo $(squeue -j ${SLURM_JOB_ID} -o '%A %C %M %t' --noheader | awk '{sum+=$2} END {avg=sum/NR; printf "Average CPU usage: %.2f\n", avg}') &&
    echo $(squeue -j ${SLURM_JOB_ID} -o '%C %M' &&
    sbatch --open-mode=append -o ${LOG_DIR}/slurm.out.%j.txt -e ${LOG_DIR}/slurm.error.%j.txt --dependency=after:${SLURM_JOB_ID}:+2 ${USER_HOMEDIR}/Alphafold-Website/shell_scripts/alphafold.sh ${EMAIL_ADDRESS} ${OUTPUT_DIR}/${SLURM_JOB_ID}/file.fasta ${MODEL} ${RELAXATION} ${GPU_RELAXATION} ${TEMPLATE_DATE} ${NUM_PREDICTIONS} ${SLURM_JOB_ID}) || { # error
    printf "Your Job with ${SLURM_JOB_ID} failed.\nIn the attachments is the error log.\nPlease check your inputs again, read the descriptions and if nothing else helps, check with the admins." | mutt -s "Failed Alphafold Job ${SLURM_JOB_ID}" -c "jannik.gut@unibe.ch" -a ${LOG_DIR}/slurm.error.${SLURM_JOB_ID}.txt -- ${EMAIL_ADDRESS}
}
#ID=$(sbatch --parsable --open-mode=append -o ${LOG_DIR}/slurm.dalcosrv.$SLURM_JOB_ID.out -e ${LOG_DIR}/slurm.dalcosrv.$SLURM_JOB_ID.err ${USER_HOMEDIR}/Alphafold-Website/shell_scripts/alphafold.sh)
