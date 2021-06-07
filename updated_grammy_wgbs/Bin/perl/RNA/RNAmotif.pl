#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

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
  open(FILE, $file_name) or die("Could not open file '$file_name'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $min_len = get_arg("min", 5, \%args);
my $max_len = get_arg("max", 50, \%args);
my $dots = get_arg("dots", 0, \%args);

# finding motifs
while (<$file_ref>) {
  chomp $_;
  my ($name, $struct) = split("\t", $_);
  find_motifs($struct, $name, $min_len, $max_len, $dots);
}




# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# find_motif(struct, name, min_len, max_len)
# ------------------------------------------------------------------------
sub find_motifs($$$$$) {
  my ($struct, $name, $min_len, $max_len, $dots) = @_;

  my $total_size = length($struct);
  my $max_st = $total_size - $min_len;
  my $size = $max_len;
  if ($size > $total_size){
    $size = $total_size;
  }

  # array representing the entire structure
  my $struct_num = $struct;
  $struct_num =~ s/\(/1 /g;
  $struct_num =~ s/\)/-1 /g;
  $struct_num =~ s/\./0 /g;
  my @all_struct = split(/ /, $struct_num);
  unshift(@all_struct, 0);

  # array representing the current part of the structure
  my @curr_struct;
  @curr_struct[0] = 0;
  for (my $i = 1; $i <= $size; $i++) {
    $curr_struct[$i] = $curr_struct[$i-1] + $all_struct[$i];
  }

  # counting motifs
  for (my $st = 1; $st <= $max_st; $st++) {

    # find motifs
    # possible motif lengths
    for (my $k = $min_len; $k <= $size; $k++) {

      # motif: ends with zero, and never reach negative values
      # drop motifs that contain points in each of the edges
      my @mot = @curr_struct;
      splice(@mot, $k+1);
      my  $str_mot = substr($struct, $st-1, $k);

      if (legal_motif($str_mot, $dots, @mot)) {
	my $end = $st + $k - 1;
	print "$name\t$st\t$end\t$str_mot\n";
      }
    }

    # end point
    if ($st + $size > $total_size){
      $size = $size - 1;
    }

    # move one character
    my $v = -1 * $all_struct[$st];
    for (my $j = 1; $j < $size; $j++) {
      $curr_struct[$j] = $curr_struct[$j+1] + $v;
    }

    if ($st + $size <= $total_size) {
      $curr_struct[$size] = $curr_struct[$size-1] + $all_struct[$st+$size];
    }
  }
}


# ------------------------------------------------------------------------
# legal_motif(motif_string, list)
# ------------------------------------------------------------------------
sub legal_motif($$@) {
  my ($str_motif, $dots, @motif) = @_;
  my $s = @motif;

  # last element must be zero
  if ($motif[$s-1] != 0) {
    return(0);
  }

  # no negative values
  my $i = 0;
  while ($i < $s and $motif[$i] >= 0) {
    $i = $i + 1;
  }

  # motif cannot contain points at the edges
  # i.e. cannot extand a motif by points
  if ((not ($dots)) and (($str_motif =~ m/^\.(.*)/g) or ($str_motif =~ m/(.*)\.$/g))) {
    return(0);
  }

  return($i == $s);
}


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAmotif.pl <file_name> [options]

  RNAmotif.pl reads RNA structures from stdin and finds legal motifs in
  these sequences.

  The sequences are given in the following format:
  <id> <structure>

  The output format is:
  <gene-id> <start> <end> <motif>
  (first position of the sequence is starting point 1, not 0).
  where start and end are on the gene's sequence as given in the input.

OPTIONS
  -min <num>       minimal motif length (default = 5)
  -max <num>       maximal motif length (default = 50)
  -dots            Allow dots at the start and the end of the motif
