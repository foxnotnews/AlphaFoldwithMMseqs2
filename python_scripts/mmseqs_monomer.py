#  can create  3 fake MSA files in your input folder
# Warning: This file is only for monomers


import os
import pathlib

from absl import app, flags

flags.DEFINE_list(
    "fasta_paths",
    None,
    "Paths to FASTA files, each containing a prediction "
    "target that will be folded one after another. If a FASTA file contains "
    "multiple sequences, then it will be folded as a multimer. Paths should be "
    "separated by commas. All FASTA paths must have a unique basename as the "
    "basename is used to name the output directories for each prediction.",
)
flags.DEFINE_string(
    "output_dir", None, "Path to a directory that will " "store the results."
)


FLAGS = flags.FLAGS


def parse_fasta(fasta_string: str):
    """Parses FASTA string and returns list of strings with amino-acid sequences.

    Arguments:
      fasta_string: The string contents of a FASTA file.

    Returns:
      A tuple of two lists:
      * A list of sequences.
      * A list of sequence descriptions taken from the comment lines. In the
        same order as the sequences.
    """
    sequences = []
    descriptions = []
    index = -1
    for line in fasta_string.splitlines():
        line = line.strip()
        if line.startswith(">"):
            index += 1
            descriptions.append(line[1:])  # Remove the '>' at the beginning.
            sequences.append("")
            continue  # Added
        sequences[index] += line

    return sequences, descriptions


def generate_fake_msa(fasta_path: str, fasta_name: str, output_dir_base: str):
    # Create output directories.
    output_dir = os.path.join(output_dir_base, fasta_name)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    msa_output_dir = os.path.join(output_dir, "msas")
    if not os.path.exists(msa_output_dir):
        os.makedirs(msa_output_dir)

    # Generate fake MSA
    with open(fasta_path) as f:
        input_fasta_str = f.read()
    input_seqs, input_descs = parse_fasta(input_fasta_str)
    if len(input_seqs) != 1:
        raise ValueError(f"More than one input sequence found in {fasta_path}.")
    input_sequence = input_seqs[0]
    input_description = input_descs[0].split()[0]
    num_res = len(input_sequence)

    # Generate fake MSA if not already present in msas
    ##UNIREF90
    uniref90_out_path = os.path.join(msa_output_dir, "uniref90_hits.sto")
    if not os.path.exists(uniref90_out_path):
        with open(uniref90_out_path, "w") as f:
            f.write(f"# STOCKHOLM 1.0\n\n")
            f.write(f"{input_description} {input_sequence}\n")
            f.write(f"#=GC RF " + "".join(["x" for _ in range(num_res)]) + "\n")
            f.write(f"//\n")

    mgnify_out_path = os.path.join(msa_output_dir, "mgnify_hits.sto")
    if not os.path.exists(mgnify_out_path):
        with open(mgnify_out_path, "w") as f:
            f.write(f"# STOCKHOLM 1.0\n\n")
            f.write(f"{input_description} {input_sequence}\n")
            f.write(f"#=GC RF " + "".join(["x" for _ in range(num_res)]) + "\n")
            f.write(f"//\n")


def main(argv):
    # Check for duplicate FASTA file names.
    fasta_names = [pathlib.Path(p).stem for p in FLAGS.fasta_paths]
    if len(fasta_names) != len(set(fasta_names)):
        raise ValueError("All FASTA paths must have a unique basename.")

    for i, fasta_path in enumerate(FLAGS.fasta_paths):
        fasta_name = fasta_names[i]
        generate_fake_msa(fasta_path, fasta_name, FLAGS.output_dir)


if __name__ == "__main__":
    flags.mark_flags_as_required(["fasta_paths", "output_dir"])
    app.run(main)
