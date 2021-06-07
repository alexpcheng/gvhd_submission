import sys
import os.path
from joblib import Parallel, delayed

def get_reads(input_file):
    taxids = ['10629', '10359', '32603', '10372', '746830', '32604', '10376']
    sample_name = input_file.split('/')[-1].split('.')[0]
    filtered_grammy = f'sample_output/filtered_grammy/{sample_name}'
    if os.path.isfile(filtered_grammy):
        taxids_that_survived_filtering = []
        with open(filtered_grammy) as fg:
            for line in fg:
                survived_tax = line.strip().split('\t')[1]
                if survived_tax in taxids:
                    taxids_that_survived_filtering.append(survived_tax)
        count=0
        with open(input_file) as f:
            for line in f:
                read_id = line.split('\t')[0].split('-')[0]
                taxid = line.strip().split('\t')[14]
                if taxid in taxids_that_survived_filtering:
                    count+=1
                    if count ==1:
                        w1 = open(f'sample_output/viral_reads/{sample_name}', 'w')
                        w2 = open(f'sample_output/viral_reads/{sample_name}.txt', 'w')
                    w1.write(read_id + '\t' + taxid + '\n')
                    w2.write(read_id + '\n')
        if (count >1):
            w1.close()
            w2.close()

def main():
    threads = int(sys.argv[1])
    files = sys.argv[2:]
    Parallel(n_jobs=threads)(delayed(get_reads)(file) for file in files)

if __name__ == "__main__":
    main()
