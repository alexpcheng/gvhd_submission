#!/usr/bin/perl

# =============================================================================
# Require
# =============================================================================
use strict;

# =============================================================================
# Main
# =============================================================================

# help mesasge
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $clusters_file = shift(@ARGV);
if (length($clusters_file) < 1 or $clusters_file =~ /^-/) {
  print STDERR <DATA>;
  exit(1);
}

my $conv_file = shift(@ARGV);
if (length($conv_file) < 1 or $conv_file =~ /^-/) {
  print STDERR <DATA>;
  exit(1);
}


# reading conversion file
my %convert;
open(CONV, "$conv_file") or die "cannot read $conv_file \n";
while (<CONV>) {
  chomp;
  $_ =~ m/(.+?)\t(.+)/g;
  $convert{$1} = $2;
}
close(CONV);

# reading clusters and printing output
open(CLUSTER_FILE, $clusters_file) or 
  die("Could not open file '$clusters_file'.\n");

while (<CLUSTER_FILE>) {
  my $line = $_;
  chomp($line);
  my ($id, $score, $parent, $parent_score, $diff, $n_leaves, @leaves) = split("\t", $line);
  print "$id\t$score\t$parent\t$parent_score\t$diff\t$n_leaves";
  foreach my $leaf (@leaves) {
    if (exists($convert{$leaf})) {
      print "\t$convert{$leaf}";
    }
    else {
      print "\t$leaf";
    }
  }
  print "\n";
}
close(CLUSTER_FILE);



# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------
# Help message
# ------------------------------------------------------------
__DATA__

cluster_convert.pl <clusters file> <converting file>

converting file is a file of the format: [id] [convert expression]
clusters file is in the format:
  [cluster id] [score] [parent] [parent score] [diff] [n leaves] [leaves]

Each appearance of id in the cluster file will be converted with the relevant expression
in the converting file.

