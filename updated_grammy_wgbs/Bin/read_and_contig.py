import sys
import pysam
def parse_args():
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    file_type = sys.argv[3]
    return(input_file, output_file, file_type)

def bam_in(input_file, output_file, viruses_of_interest):
    readids=[]
    d= {'NC_001538.1': '10629',
        'NC_001664.4': '32603',
        'NC_006273.1': '10359',
        'NC_014407.1': '10372',
        'NC_014406.1': '746830',
        'NC_000898.1': '32604',
        'NC_007605.1': '10376'}

    with open(output_file, 'w') as w:
        bamfile = pysam.AlignmentFile(input_file, 'rb')
        for read in bamfile:
            readid = read.query_name
            contig = read.reference_name
            print(readid)
            print(contig)
            taxid = d[contig]
            if readid not in readids:
                readids.append(readid)
                w.write(readid+'\t'+taxid+'\t'+contig+'\n')


def blast_in(input_file, output_file, viruses_of_interest):
    with open(input_file) as f, open(output_file, 'w') as w:
        for line in f:
            readid = line.strip().split('\t')[0].split('-')[0]
            taxid = line.strip().split('\t')[-1]
            contig = line.strip().split('\t')[1].split('|')[3]
            if taxid in viruses_of_interest:
                w.write(readid+'\t'+taxid+'\t'+contig+'\n')

def main():
    viruses_of_interest=['10629', '32603', '10359', '10372', '746830', '32604', '10376']
    input_file, output_file, file_type = parse_args()
    if file_type == 'bam':
        bam_in(input_file, output_file, viruses_of_interest)
    if file_type=='blast':
        blast_in(input_file, output_file, viruses_of_interest)

if __name__ == "__main__":
    main()
