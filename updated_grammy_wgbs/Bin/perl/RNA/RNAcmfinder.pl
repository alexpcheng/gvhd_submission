#! /usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
use Getopt::Long qw(:config no_ignore_case);
require "$ENV{PERL_HOME}/Lib/load_args.pl";


# =============================================================================
# Constants
# =============================================================================

my $PATH = "/home/genie/Genie/Bin/CMfinder/CMfinder_0.2/bin";
my $BLAST_PATH = "/home/genie/Genie/Bin/CMfinder/CMfinder_0.2/blast";


# =============================================================================
# Main part
# =============================================================================

# Reading arguments
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, $file_name) or die("Could not open file '$file_name'.\n");
  $file_ref = \*FILE;
}


# Parameters
my %args = load_args(\@ARGV);

my $cand = get_arg("cand", 40, \%args);
my $n = get_arg("n", 9, \%args);
my $maxspan = get_arg("max", 100, \%args);
my $minspan = get_arg("min", 30, \%args);
my $fraction = get_arg("f", 0.8, \%args);

my $min_hairpin = 1;
my $max_hairpin = get_arg("stem", 1, \%args);
if ($max_hairpin < $min_hairpin) {
  $max_hairpin  = $min_hairpin;
}

my $output_file = get_arg("file", "output", \%args);
my $no_blast = get_arg("no_blast", 0, \%args);
if ($no_blast == 0 && (! defined $BLAST_PATH || ! -e "$BLAST_PATH/blastn" || ! -e "$BLAST_PATH/xdformat")) {
  print STDERR "Can not find BLAST. Search without BLAST\n";
  $no_blast = 1;
}



# reading input file, and creating fasta format file
open(SEQ, ">tmpseqfile_$$.fasta") or die "cannot create sequence file\n";

while (<$file_ref>) {
  my $line = $_;
  chomp($line);

  my @fields = split("\t", $line);
  print SEQ ">$fields[0]\n$fields[1]\n";
}

close(SEQ);



# run 1: hairpins
print STDERR "1) Find Candidates for motifs: candf \n";

system("$PATH/candf -c $cand -o tmpseqfile_$$.candf -M $maxspan -m $minspan -s $min_hairpin -S $max_hairpin tmpseqfile_$$.fasta > /dev/null");



# run 2: blast
print STDERR "2) Build database: cands\n";

if ($no_blast == 0) { # build blast database
  `$BLAST_PATH/xdformat -n tmpseqfile_$$.fasta 2> /dev/null`;
  system("$BLAST_PATH/blastn tmpseqfile_$$.fasta tmpseqfile_$$.fasta -notes -top -W 8 -noseqs > tmpseqfile_$$.blast");
  system("$PATH/parse_blast.pl tmpseqfile_$$.blast > tmpseqfile_$$.match");
  `$PATH/cands -n $n -f $fraction -m tmpseqfile_$$.match tmpseqfile_$$.fasta tmpseqfile_$$.candf 2> /dev/null`;

  system("rm tmpseqfile_$$.blast");
  system("rm tmpseqfile_$$.match");
  system("rm tmpseqfile_$$.*xn*");
}
else {
  system("$PATH/cands -n $n -f $fraction tmpseqfile_$$.fasta tmpseqfile_$$.candf > /dev/null");
}



# run 3: main
print STDERR "3) Find motifs: canda, cmfinder\n";

for (my $i = 1; $i <= $n; $i++) {
  if (-s "tmpseqfile_$$.candf.$i") {
    system("$PATH/canda tmpseqfile_$$.candf.$i tmpseqfile_$$.fasta tmpseqfile_$$.align.$i > /dev/null");
    system("$PATH/cmfinder -o $output_file.$i.align -a tmpseqfile_$$.align.$i tmpseqfile_$$.fasta $output_file.$i.cm >> tmpseqfile_$$.out.$i");
    my $output = `$PATH/summarize $output_file.$i.align`;
    $output =~ m/\sScore=([\d\.]+)\s/g;
    print "Motif $i score: $1\n";
  }
}

# remove temporary files
system("rm tmpseqfile_$$.*cand*");
system("rm tmpseqfile_$$.*align*");
system("rm tmpseqfile_$$.*out*");
system("rm tmpseqfile_$$.fasta");

print STDERR "4) Done \n";






# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAcmfinder.pl <file_name> [options]

Learn motifs common to all the given RNA sequnces, and create a covariance model that represents
these motifs.
CMfinder: http://bio.cs.washington.edu/yzizhen/CMfinder/

Create two output files for each motif:
  1. Alignment file (.align): in Stockholm format (http://www.cgb.ki.se/cgb/groups/sonnhammer/Stockholm.html),
     with slight changes in the mark-up lines:
       #=GS <seqname> DE <start>..<end> <score>
       #=GS <seqname> WT <weight>
     to indicate the start/end position, alignment score, and weight of the motif.
  2. CM file(.cm): describes the motif using a covariance model.
The files are numbered in sequencial order.

Options:
    -cand <num>      The maximum number of candidate motifs in each sequence. [Default = 40]. No bigger than 100.
    -min <num>       The minimum length of a candidate motif. [Default = 30]
    -max <num>       The maximum length of a candidate motif. [Default = 100]
    -n <num>         The maximum number of output motifs. [Default = 9]
    -f <num>         The fraction of the sequences expected to contain the motif. [Default = 0.80]
    -stem <num>      The maximal number of stem-loops in the motif. [Default = 1]
    -file <name>     The output file name to save the motif and CM to. [Default = output]
    -no_blast        Do not use BLAST search to locate anchors.
