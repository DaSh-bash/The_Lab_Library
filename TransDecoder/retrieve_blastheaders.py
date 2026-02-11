import sys

def filter_headers(input_file, output_file):
    try:
#open the input file
        with open(input_file, 'r') as infile:
#open output file
            with open(output_file, 'w') as outfile:
#loop through each line in  input file
                for line in infile:
#see if line starts with > and contains the | character (will have | if it's a sequence with blast homology)
                    if line.startswith('>') and '|' in line:
#write the headers for sequences with blast homology to output file
                        outfile.write(line)
        print(f"headers written to {output_file}")
    except FileNotFoundError:
        print(f"can't find {input_file}")
    except Exception as e:
        print(f"error?: {e}")

#main function
if __name__ == "__main__":
#enter your input and output file names!
    input_file = "Sattenuata.fasta.transdecoder.cds"
    output_file = "blastseqs_cds.txt" #this file is just headers for seqs w blast homology, so it will work with both the .cds and .pep files

#call function
    filter_headers(input_file, output_file)
