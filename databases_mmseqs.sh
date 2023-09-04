#!/usr/bin/env bash

#SBATCH -c 3 # number of cores
#SBATCH --job-name=Databases_mmseqs
#SBATCH -e slurm.%N.%j.err # STDERR
#SBATCH -o slurm.%N.%j.out # STDOUT
#SBATCH --time 72:00:00
DB_PATH=/ibmm_data/alphafold_database
DATABASE_db=/ibmm_data/alphafold_database/mmseqs_databases

#UNIREF90
#mmseqs createdb ${DB_PATH}/uniref90/uniref90.fasta   ${DATABASE_db}/uniref90/uniref_db
#mmseqs createindex  ${DATABASE_db}/uniref90/uniref_db   ${DATABASE_db}/uniref90/tmp

####database to create maybe put it in alphafold database_db ?
#mgnify
#mmseqs createdb ${DB_PATH}/mgnify/mgy_clusters_2022_05.fa  ${DATABASE_db}/mgnify/mgnify_db
#mmseqs createindex  ${DATABASE_db}/mgnify/mgnify_db  ${DATABASE_db}/mgnify/tmp

#only for multimer UNIPROT
#mmseqs createdb ${DB_PATH}/uniprot/uniprot.fasta  ${DATABASE_db}/uniprot/uniprot_db
#mmseqs createindex  ${DATABASE_db}/uniprot/uniprot_db  ${DATABASE_db}/uniprot/tmp

#bfd
#    
#mmseqs createdb ${DB_PATH}/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt_a3m.ffdata   ${DATABASE_db}/bfd/bfd_db 
mmseqs createindex  ${DATABASE_db}/bfd/bfd_db  ${DATABASE_db}/bfd/tmp

#
echo squeue -j ${SLURM_JOB_ID} -o '%C %M'
