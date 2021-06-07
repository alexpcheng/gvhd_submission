#!/bin/python
import os
from simplesam import Reader, Writer, encode_tag
import sys
from pyfaidx import Fasta
import gzip
import time
from Bio.Seq import Seq

def get_important_bam_info(read):
	seq_id = str(read.qname)
	seq_qual = str(read.qual)
	rev_bisulfite_seq = str(read['XN'])
	direction = str(read['YD'])
	flag = int(read.flag)
	start = int(read.pos)
	chr = str(read.rname)
	return(seq_id, seq_qual, rev_bisulfite_seq, direction, flag, start, chr)

def mask_SNP(chr, start, sequence, CT_SNP_array):
	masked_read=""
	for nucleotide, position in zip(sequence, range(start, start+len(sequence))):
		genomic_location = chr + ':' + str(start)
		if genomic_location not in CT_SNP_array: #may need to double check
			masked_read+=nucleotide
		else:
			masked_read+='N'
	return(masked_read)

def get_fastQ(read, hg19, CT_SNP_array):
	seq_id, seq_qual, rev_bisulfite_seq, direction, flag, start, chr = get_important_bam_info(read)

	# Sanity check
	if flag & 64: # first read in pair
		pair="R1"
	elif flag & 128: #second read in pair
		pair="R2"
	else:
		sys.exit("Read not first or second in pair???")

	if direction == 'f':
		masked_read = mask_SNP(chr, start, rev_bisulfite_seq, CT_SNP_array)
	elif direction == 'r':
		rev_bisulfite_seq_rc = Seq(rev_bisulfite_seq).reverse_complement()
		masked_read = mask_SNP(chr, start, rev_bisulfite_seq_rc, CT_SNP_array)
		masked_read = str(Seq(masked_read).reverse_complement())
	else:
		sys.exit("Everything should have a direction???")

	return(seq_id, masked_read, seq_qual, pair)

def main():
	CT_SNPs=sys.argv[1]
	file=sys.argv[2]
	R1_outfile=sys.argv[3]
	R2_outfile=sys.argv[4]
	hg19_file = sys.argv[5]

	with open(CT_SNPs, 'r') as f:
		CT_SNP_array = f.read().splitlines()
	CT_SNP_array = frozenset(CT_SNP_array)
	hg19=Fasta(hg19_file)
	in_file = open(file, 'r')
	in_bam=Reader(in_file)

	with open(R1_outfile, 'w') as r1, open(R2_outfile, 'w') as r2:
		for read in in_bam:
			seq_id, masked_read, qual, pair = get_fastQ(read, hg19, CT_SNP_array)
			if pair == "R1":
				r1.write('@' + seq_id + '\n' + masked_read + '\n' + '+' + '\n' + qual + '\n')
			if pair == "R2":
				r2.write('@' + seq_id + '\n' + masked_read + '\n' + '+' + '\n' + qual + '\n')
	in_file.close()

if __name__ == '__main__':
	main()
