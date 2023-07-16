from Bio import SeqIO
from absl import app, flags


#flags files output_dir , json_file
#FLAGS = flags.FLAGS
#flags.DEFINE_string("input_file", "", "Path to the input FASTA file")
#flags.DEFINE_string("output_dir", "", "Path and name to the output JSON file")
#
#def main(argv):
#
#    records = SeqIO.parse(FLAGS.input_file, "fasta")
#    records = [record for record in records if len(record.seq) > 0]  # Remove records with empty sequences
#    count = SeqIO.write(records,  f"{FLAGS.output_dir}/mgnify_hits.sto", "stockholm")
#
#if __name__ == '__main__':
#    
#    app.run(main)
filename = "output/file1/msas/mgnify_hits.sto"

with open(filename, "r") as file:
    content = file.read().rstrip("\x00")

with open(filename, "w") as file:
    file.write(content)


records = SeqIO.parse(filename, "fasta")
count = SeqIO.write(records,  filename, "stockholm")
