import json
from collections import defaultdict
from itertools import product
from string import ascii_uppercase

from absl import app, flags

FLAGS = flags.FLAGS
flags.DEFINE_string("fasta_file", "", "Path to the input FASTA file")
flags.DEFINE_string("output_file", "", "Path to the output JSON file")


# Generate letters from A ..Z , AA..ZZ
def generate_labels(n):
    num_letters = len(ascii_uppercase)
    label_length = 1
    while n > num_letters**label_length:
        n -= num_letters**label_length
        label_length += 1
    labels = product(ascii_uppercase, repeat=label_length)
    return ["".join(label) for label in labels][n - 1]


def main(argv):
    sequences = defaultdict(dict)
    current_sequence = {}
    sequence_count = 0

    with open(FLAGS.fasta_file, "r") as file:
        for line in file:
            line = line.strip()
            if line.startswith(">"):
                header = line[1:]
                sequence_count += 1
                current_sequence = sequences[generate_labels(sequence_count)]
                current_sequence["description"] = header
                current_sequence["sequence"] = ""
            else:
                current_sequence["sequence"] = (
                    current_sequence.get("sequence", "") + line
                )
                current_sequence["sequence"] = (
                    current_sequence["sequence"]
                    .replace("-", "x")
                    .replace(">Sequence", "")
                )

    with open(FLAGS.output_file, "w") as file:
        json.dump(sequences, file, indent=4)


if __name__ == "__main__":
    app.run(main)
