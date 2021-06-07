import sys

infile = sys.argv[1]
outfile = sys.argv[2]

with open(infile) as f, open(outfile, 'w') as w:
    for line in f:
        qseqid, sseqid, pident, length, mismatch, gapopen, qstart,qend, sstart, send, evalue, bitscore, qlen, strand, taxid = line.strip().split('\t')
        if (float(length)/float(qlen) >= 0.9 and float(pident) >= 90 and taxid != "GI_NOT_FOUND"):
            newline = line.replace("/1-1", '-1').replace("/2-2", '-2') #hacky fix for poor coding earlier
            w.write(newline)
