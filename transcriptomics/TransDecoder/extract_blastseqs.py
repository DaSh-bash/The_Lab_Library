#to be run after the script "retrieve_blastheaders.py"
def extract_sequences_from_headers(header_file, sequence_file, output_file):
    try:
#read the headers from the file you just generated
        with open(header_file, 'r') as hfile:
            headers = set(line.strip().split()[0] for line in hfile if line.startswith('>'))

#open the OG sequence file and output file
        with open(sequence_file, 'r') as sfile, open(output_file, 'w') as ofile:
            write_sequence = False  
            for line in sfile:
                if line.startswith('>'):
                    #check if the header is in the list of headers to extract
                    header = line.strip().split()[0]
                    if header in headers:
                        write_sequence = True
                        ofile.write(line) #write header to the output file
                    else:
                        write_sequence = False
                elif write_sequence:
                    ofile.write(line)  #write sequence to the output file

        print(f"Extracted sequences have been written to {output_file}")
    except FileNotFoundError as e:
        print(f"error!: {e}")
    except Exception as e:
        print(f"error occurred: {e}")

#main function
if __name__ == "__main__":
#enter your file names below
    header_file = "blastseqs_cds.txt"  #header file you just made 
    sequence_file = "Sattenuata.fasta.transdecoder.cds"  #OG sequence file 
    output_file = "Sattenuata_blasthits_only.cds"  #output file 

#call function
    extract_sequences_from_headers(header_file, sequence_file, output_file)
