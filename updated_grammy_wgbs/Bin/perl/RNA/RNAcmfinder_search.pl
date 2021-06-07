#! /usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";


# =============================================================================
# Constants
# =============================================================================

my $PATH = "/home/genie/Genie/Bin/infernal/infernal-0.72/src";

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
my $model_file = get_arg("model", "", \%args);
if ($model_file eq "") {
  print STDERR "No input model is given\n";
  print STDOUT <DATA>;
  exit;
}

my $threshold = get_arg("threshold", -1, \%args);
my $significant = get_arg("significant", 0, \%args);
my $best = get_arg("best", 0, \%args);
my $neg_score = get_arg("neg_score", -1, \%args);



# reading input file, and creating fasta format file
open(SEQ, ">tmpseqfile_$$.fasta") or die "cannot create sequence file\n";
my $size = 0;

while (<$file_ref>) {
  my $line = $_;
  chomp($line);

  my @fields = split("\t", $line);
  print SEQ ">$fields[0]\n$fields[1]\n";
  $size += length($fields[1]);
}

close(SEQ);



# searching using cmsearch (only the given strand, local alignment)
system("$PATH/cmsearch --toponly $model_file tmpseqfile_$$.fasta >> output_$$.tmp");
system("rm tmpseqfile_$$.fasta");



# analyze results
# As a rough guide, scores greater than the log (base two) of the target database size are significant.
# e.g., given a 600 nt target (300 nt × 2 strands), scores over 9-10 bits are significant
open(FILE, "output_$$.tmp") or die "cannot read the results\n";

my $sig_threshold = log($size)/log(2);
if ($significant and ($sig_threshold > $threshold)) {
  $threshold = $sig_threshold;
}

if ($threshold > 0) {
  print "threshold = $threshold\n";
}

my $seq_name;
my $max_score = $neg_score;
my $max_score_start;
my $max_score_end;

while (<FILE>) {
  my $line = $_;
  chomp $line;

  if ($line =~ m/sequence: (.+)/g) {
    if ($best and (defined $seq_name)) {
      print "$seq_name\t$max_score\t$max_score_start\t$max_score_end\n";
    }
    $seq_name = $1;
    $max_score = $neg_score;
  }

  if ($line =~ m/hit.*:\s*(\d+)\s*(\d+)\s*([\d\.]+) bits/g) {
    if ($3 > $max_score) {
      $max_score = $3;
      $max_score_start = $1;
      $max_score_end = $2;
    }

    if ((not $best) and (($threshold > 0 and $3 >= $threshold) or ($threshold < 0))) {
      print "$seq_name\t$3\t$1\t$2\n";
    }
  }
}
if ($best and (defined $seq_name)) {
  print "$seq_name\t$max_score\t$max_score_start\t$max_score_end\n";
}

# remove files
system("rm output_$$.tmp");




# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAcmfinder_search.pl <file_name> [options]

Search a given covariance model learned by RNAcmfinder.pl in a given set of sequences.
This program uses the INFERNAL program for this search.
INFERNAL: http://infernal.janelia.org/

Options:
    -model <file>       File name for a file containing the covariance model outputed by 
                        RNAcmfinder.pl (.cm file).
    -threshold <num>    Display only results with score above the given threshold.
    -significant        Display only significant results (scores greater than the log[database size])
    -best               Display only the highest scoring result for each sequence.
    -neg_score <um>     Score for sequences without a motif at all (Default = -1);
