# Does insilico conversion ...
import sys
import os
import itertools
from Bio.Seq import Seq
infile=sys.argv[1]
outfile=sys.argv[2]

conversion=sys.argv[3]

# If ever non-directional libraries are used ...
#if conversion == 'C2T':
#	incharacter='C'
#	outcharacter='T'
#if conversion == 'G2A':
#	incharacter='G'
#	outcharacter='A'

def reverse_complement(sequence):
	endl = ''
	if (sequence[-1]=='\n'):
		endl = '\n'
		sequence = sequence.strip()
	rc = str(Seq(sequence).reverse_complement())
	return(rc+endl)

incharacter='C'
outcharacter='T'
# Blast does not handle paired-ends so we flip R2 to its reverse complement, then do CT conversion
#(saves on blast runs)
with open(infile) as f, open(outfile, 'w') as w:
	for read_id, sequence in itertools.zip_longest(*[f]*2):
		if read_id.strip().endswith('1') or read_id.strip().endswith('C'):
			w.write(read_id)
			w.write(sequence.replace(incharacter, outcharacter))
		if read_id.strip().endswith('2'):
			w.write(read_id)
			rev_comp = reverse_complement(sequence)
			w.write(rev_comp.replace(incharacter, outcharacter))
