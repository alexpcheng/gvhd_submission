#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/RNA/RNAmodel.pl";

# =============================================================================
# Const
# =============================================================================
my $SEPERATOR = ":";

# =============================================================================
# Main part
# =============================================================================

# reading arguments
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
  open(FILE, $file_name) or die("Could not open $file_name.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $n = get_arg("n", 5, \%args);
my $shuffle = get_arg("shuffle", "p", \%args);
my $per_sequence = get_arg("per_sequence", 0, \%args);


# shuffling sequences
my %sequences;
while (<$file_ref>) {
  chomp;
  my ($id, $seq) = split("\t");
  $sequences{$id} = $seq;
}
close($file_ref);

my %negative_sequences = build_negative_set($n, ($shuffle eq "p"), $per_sequence, \%sequences);
foreach my $i (keys %negative_sequences) {
  print "$i\t$negative_sequences{$i}\n";
}


# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAbuild_negative_examples.pl <file_name> [options]

  RNAbuild_negative_examples.pl reads RNA sequences from stdin, and creates
  a set of shuffled sequences with similar nucleotide distribution as the
  input set.
  Sequences are given in the following format: <id> <sequence>

OPTIONS
  -n <num>        Number of sequences to create from each input sequence
                  (Default = 5).
  -shuffle <s|p>  Shuffle by single nucleotide distribution (s) or pairwise
                  nucleotide distribution (p) (Default = p).
  -per_sequence   Calculate the distribution per sequence.
