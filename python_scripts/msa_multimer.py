import json
import os

from absl import app, flags

FLAGS = flags.FLAGS
flags.DEFINE_string("json_file", "", "Path to the input JSON file")
flags.DEFINE_string("output_dir", "", "Path to the output directory")


def main(argv):
    # create fake msas
    with open(FLAGS.json_file, "r") as file:
        data = json.load(file)

        for key, value in data.items():
            msa_output_dir = os.path.join(FLAGS.output_dir, "msas", key)
            os.makedirs(msa_output_dir, exist_ok=True)

            input_description = value["description"]
            input_sequence = value["sequence"]
            num_res = len(input_sequence)

            uniref90_out_path = os.path.join(msa_output_dir, "uniref90_hits.sto")
            if not os.path.exists(uniref90_out_path):
                with open(uniref90_out_path, "w") as f:
                    f.write("# STOCKHOLM 1.0\n\n")
                    f.write(f"{input_description} {input_sequence}\n")
                    f.write(f"#=GC RF {''.join(['x' for _ in range(num_res)])}\n")
                    f.write("//\n")

            mgnify_out_path = os.path.join(msa_output_dir, "mgnify_hits.sto")
            if not os.path.exists(mgnify_out_path):
                with open(mgnify_out_path, "w") as f:
                    f.write("# STOCKHOLM 1.0\n\n")
                    f.write(f"{input_description} {input_sequence}\n")
                    f.write(f"#=GC RF {''.join(['x' for _ in range(num_res)])}\n")
                    f.write("//\n")

            bfd_out_path = os.path.join(msa_output_dir, "bfd_uniref_hits.a3m")
            if not os.path.exists(bfd_out_path):
                with open(bfd_out_path, "w") as f:
                    f.write(f">{input_description}\n")
                    f.write(f"{input_sequence}\n")

            uniprot_out_path = os.path.join(msa_output_dir, "uniprot_hits.sto")
            if not os.path.exists(uniprot_out_path):
                with open(uniprot_out_path, "w") as f:
                    f.write(f"# STOCKHOLM 1.0\n\n")
                    f.write(f"{input_description} {input_sequence}\n")
                    f.write(f"#=GC RF " + "".join(["x" for _ in range(num_res)]) + "\n")
                    f.write(f"//\n")


if __name__ == "__main__":
    app.run(main)
