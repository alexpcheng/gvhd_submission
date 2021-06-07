#!/usr/bin/perl

my $AUTHOR="Eran Hodis"; my $DATE="December 25, 2007"; my $VERSION="1.01";

# This program takes a fasta file and counts the number of genes, the number of exons, and the total basepairs, and adds that information along with the directory name to a file
#this program was originally created to run over all the organism directories created by parsing the RefSeq database into CDS.fasta files.  Each organism directory will have one CDS.fasta file that will contain all its exons

#require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/)
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}
#my $file_ref2;
#my $file2 = $ARGV[1];
#if (length($file2) < 1 or $file2 =~ /^-/)
#{
#  $file_ref2 = \*STDIN;
#}
#else
#{
#  open(FILE2, $file2) or die("Could not open file '$file2'.\n");
#  $file_ref2 = \*FILE2;
#}


#my %args = load_args(\@ARGV);

#my $uniquify_column = get_arg("c", 0, \%args);
#my $force_numbers_on_all = get_arg("f", 0, \%args);
#my $delim = get_arg("d", "-", \%args);

use strict 'vars';
use warnings;

my %gene1 = ();
my %gene2 = ();
my $exons_with_no_genes = 0;
my $total_exons = 0;
my $total_bp = 0;
my $total_genes = 0;
my ($organism, $filename, $gbff_file, $accession, $gi, $gene_id1, $gene_id2);


#go through fasta file
#there are 2 unique gene id's, if the first exists, count it in the first hash gene1, if the first doesn't exist, but the second does, count the second in the second gene hash, if neither exist, add to exons_with_no_genes
#also count exons and their length
while (my $line = <$file_ref>) {
	chomp($line);
	if (substr($line,0,1) eq '>') {
	#header
		my @info = split (/\|/,$line);
		#sometimes there is an error that throws off the arrangement of info in the header, fix for it
		if (substr($info[2],0,8) eq 'complete') {
			($organism, $filename, $gbff_file, $accession, $gi, $gene_id1, $gene_id2) = @info;
		}
		else {
			($organism, $filename, $accession, $gi, $gene_id1, $gene_id2) = @info;
		}
		if ($gene_id1) {
			$gene1{$gene_id1} = 1;
		}
		elsif ($gene_id2) {
			$gene2{$gene_id2} = 1;
		}
		else {
			$exons_with_no_genes++;
		}
	}
	else {
	#sequence
		$total_exons++;
		$total_bp += length($line);
	}

}


#add up the total elements in gene hashes 1 and 2
while (my ($key, $value) = each (%gene1)) {
	$total_genes++;
}
while (my ($key, $value) = each (%gene2)) {
	$total_genes++;
}

my $max_nmer = int(log($total_bp/10)/log(4));

print "$file\t$total_genes\t$total_exons\t$total_bp\t$max_nmer\t$exons_with_no_genes\n";

close ($file_ref);
#close ($file_ref2);

__DATA__

count_genes_exons_bp.pl <inputfile> <outputfile>

	Takes in a fasta file whose entries are assumed to be exons
	and outputs in tab delimited format the following: 
	inputfile, total genes, total exons, total basepairs, 
	the maximum nmer size that you can count and expect to have 
	each nmer appear 10 times in the entire fasta file, and the
	number of exons counted that have no gene data.

	This program is specific to the database of CDS exons derived
	from NCBI's RefSeq database by Eran Hodis at:
	~/Data/Protein/DNA/Sequence/*ORGANISMNAME*/RefSeq/data_all_cds.fas
 
