import json
from absl import app, flags

FLAGS = flags.FLAGS
flags.DEFINE_string("fasta_file", "", "Path to the input FASTA file")
flags.DEFINE_string("output_file", "", "Path to the output JSON file")


def main(argv):
    sequences = {}
    current_sequence = None

    with open(FLAGS.fasta_file, "r") as file:
        for line in file:
            line = line.strip()
            if line.startswith(">"):
                header = line[1:]
                current_sequence = {"description": header, "sequence": ""}
                sequences[header] = current_sequence
            else:
                current_sequence["sequence"] += line

    with open(FLAGS.output_file, "w") as file:
        json.dump(sequences, file, indent=4)


if __name__ == '__main__':
    app.run(main)
