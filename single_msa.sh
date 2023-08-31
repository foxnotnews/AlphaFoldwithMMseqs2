#!/usr/bin/env bash

#SBATCH -c 1 # number of cores
#SBATCH --mem 100G # memory pool for all cores
#SBATCH --job-name=MSA_mmseqs
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH -o slurm.%N.%j.out # STDOUT
#SBATCH --time 1:00:00




#echo -e ">query\n$(awk '$1=$1' ORS='\n>ERR1719251_30936 \n' /ibmm_data/alphafold_database/openproteinset/fixed/3dde_A.fasta)" | head -n -1 > temp.fasta
FILE_NAME=$1
MODEL=$2

USER_HOMEDIR=${SLURM_JOB_ID}
FILE=$(echo "$FILE_NAME" | awk -F"." '{print $(NF-1)}')

mkdir -p ${SLURM_JOB_ID}/${FILE}/msas

if [[ "$MODEL" != "multimer" ]];then

##remove eventual  null lines to check correctly 
tr <  ${FILE_NAME} -d '\000' > ${SLURM_JOB_ID}/${FILE}/msas/bfd_uniref_hits.a3m
#python monomer_msa_format.py --input_file ${FILE_NAME}  --output_dir ${SLURM_JOB_ID}
#create fasta with only query
#description=$(grep ">" "$FILE_NAME" | head -n 1) >> query_file
#echo $description
#seq=$(awk '/^>/{flag=1;next} flag{print;flag=0;exit}' ${FILE_NAME}) >> query_file

#remove >
description=$( grep ">" ${FILE_NAME} | head -n 1 | cut -c 2-)
seq=$(awk '/^>/{flag=1;next} flag{print;flag=0;exit}' ${FILE_NAME}) 
#fasta file
echo $(grep ">" "$FILE_NAME" | head -n 1) >> ${SLURM_JOB_ID}/${FILE}/query_file
echo $seq >> ${SLURM_JOB_ID}/${FILE}/query_file

num_res=${#seq}
uniref90_out_path=${SLURM_JOB_ID}/${FILE}/msas/uniref90_hits.sto
if [ ! -f "$uniref90_out_path" ]; then
    {
        echo -e "# STOCKHOLM 1.0"
        echo
        echo -n $description
        echo " $seq"
        echo "#=GC RF $(printf 'x%.0s' $(seq "$num_res"))"
        echo "//"
    } > "$uniref90_out_path"
fi
mgnify_out_path=${SLURM_JOB_ID}/${FILE}/msas/mgnify_hits.sto
if [ ! -f "$mgnify_out_path" ]; then
    {
        echo -e "# STOCKHOLM 1.0"
        echo
        echo -n $description
        echo " $seq"
        echo "#=GC RF $(printf 'x%.0s' $(seq "$num_res"))"
        echo "//"
    } > "$mgnify_out_path"
fi
##dont remember but it probably did not work for multimers if it was commented
#else
#    #create json of the seuqenc of the multimer 
#    python msas_json.py --fasta_file ${FILE_NAME} --output_file ${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json
#    # Get the starting sequence  from the JSON file
#    starting_sequence=$(jq -r '.A.sequence' "${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json" )
#    starting_descritpion=$(jq -r '.A.description' ${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json )
#    #each letter correspond to 1 sequence 
#    letters=$(jq -r 'keys[]' "${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json")
#    #current letter to loop through
#    before_letter=A
#    last_letter=$(jq -r 'keys[-1]' "${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json")
#
#    for letter in $letters; do
#    mkdir -p ${SLURM_JOB_ID}/${FILE}/msas/${letter}
#    #if it's the first letter create directory and file then pass
#    if [ "$letter" == "A" ]; then
#        echo ">$starting_descritpion" > ${SLURM_JOB_ID}/${FILE}/msas/${letter}/$file
#        continue  # Skip to the next iteration of the loop
#    fi
#    #get name and seq of the  current letter directory
#    new_description=$( jq -r '."'$letter'".description' ${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json )
#    new_sequence=$( jq -r '."'$letter'".sequence' ${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json )
#    #add this name to its corresponding output  file
#    echo ">$new_description" >  ${SLURM_JOB_ID}/${FILE}/msas/${letter}/$file
#    
#    #catch the previous sequence output msas and add it to the previous letter output file
#    sed -n "/${starting_sequence}/,/>${new_description}/{/>${new_description}/q;p}" ${SLURM_JOB_ID}/${FILE}/mmseqsruns/$file >> ${SLURM_JOB_ID}/${FILE}/msas/${before_letter}/$file
#
#    #update current step
#    starting_sequence=$new_sequence
#    before_letter=$letter
#    #if it's last letter
#    if [ "$letter" == "$last_letter" ]; then
#        descritpion=$( jq -r '."'$letter'".description' "${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json" )
#        sequence=$( jq -r '."'$letter'".sequence' "${SLURM_JOB_ID}/${FILE}/msas/chain_id_map.json" )
#        sed -n "/$sequence/,\$p"  ${SLURM_JOB_ID}/${FILE}/mmseqsruns/$file >>  ${SLURM_JOB_ID}/${FILE}/msas/${letter}/$file
#    
#    fi
#    done
#
fi

#Hope it run alphafold afterward
ID=$(sbatch --parsable --open-mode=append -o $SLURM_JOB_ID.out -e $SLURM_JOB_ID.err alphafold.sh)
sbatch --open-mode=append -o $SLURM_JOB_ID.out -e $SLURM_JOB_ID.err --dependency=after:${ID}:+2 alphafold.sh ${SLURM_JOB_ID}/${FILE}/query_file ${SLURM_JOB_ID} ${MODEL}