#!/usr/bin/perl

# =============================================================================
# Distance Calculation Subroutines
# --------------------------------
#
# Input files formats:
#  - structure file: <id> <structure> (a single structure in each line)
#  - motif file:     <id> <structure list>
#  - comparison file: <id> <id>
#
# Output format:
# <id 1> <id 2> <f> <F> <h> <H> <w> <W> <c> <C> (or only a subset of these distances)
#
# Distance Matrices:
#  f = full structure, tree editing distance
#  nf = full structure, tree editing distance, normalized
#  F = full structure, string alignment
#  nF = full structure, string alignment, normalized
#  h = HIT structure, tree editing distance
#  H = HIT structure, string alignment
#  w = weighted coarse structure, tree editing distance
#  W = weighted coarse structure, string alignment
#  c = coarse structure, tree editing distance
#  C = coarse structure, string alignment
#
# Linkage methods:
#  0 = max linkage
#  1 = min linkage
#  2 = avg linkage
# =============================================================================


# =============================================================================
# Require
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/libstats.pl";

# =============================================================================
# Constants
# =============================================================================
my $EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs";
my $MAXDOUBLE = 1.79769e+308;
my $EPS = 0.00000001;



# =============================================================================
# Subroutines
# =============================================================================

# -----------------------------------------------------------------------------
# round(number)
#
# Returns a rounded number.
# -----------------------------------------------------------------------------
sub round($){
  my($number) = shift(@_);
  return int($number + .5 * ($number <=> 0));
}

# -----------------------------------------------------------------------------
# RNAsequence_distance(struct1_ref, struct2_ref, distance_type)
#
# Returns a list of distances between the given structures
# -----------------------------------------------------------------------------
sub RNAsequence_distance($$$$) {
  my ($struct1_ref, $struct2_ref, $distance_type) = @_;
  my @struct1 = @$struct1_ref;
  my @struct2 = @$struct2_ref;

  open(FILE, ">tmp_seqfile_$$") or die "cannot create temporary file\n";
  my $size = scalar(@struct1);
  for(my $s = 0; $s < $size; $s++) {
    print FILE "$struct1[$s]\n$struct2[$s]\n";
  }
  close(FILE);

  my $r = `$EXE_DIR/RNAdistance -D$distance_type < tmp_seqfile_$$ | cut -d " " -f 2 | tr "\n" "\t"`;
  my @distances = split("\t", $r);

  `rm -rf tmp_seqfile_$$`;
  return(@distances);
}

# -----------------------------------------------------------------------------
# RNAmotif_distance(motif1 ref, motif2 ref, distance type, linkage method, percentile)
#
# Calculate the distance between two motifs (lists of structures).
# -----------------------------------------------------------------------------
sub RNAmotif_distance($$$$$) {
  my ($motif1_ref, $motif2_ref, $distance_type, $linkage_method, $percentile) = @_;
  my @motif_list1 = @$motif1_ref;
  my @motif_list2 = @$motif2_ref;

  # Running RNAdistance
  open (SEQFILE, ">tmp_seqfile_$$") or die("Could not open temporary sequence file.\n");
  foreach my $m1 (@motif_list1) {
    foreach my $m2 (@motif_list2) {
      print SEQFILE "$m1\n$m2\n";
    }
  }
  close (SEQFILE);

  # running RNAdistance
  my $r = `$EXE_DIR/RNAdistance -D$distance_type < tmp_seqfile_$$ | cut -d " " -f 2 | tr "\n" "\t"`;

  # remove temporary files
  unlink("tmp_seqfile_$$");

  # calculate the distance
  my @distances = split("\t", $r);
  my @sorted_distances = sort {$a <=> $b} @distances; # sort numerically ascending
  my $n_distances = scalar(@sorted_distances);
  my $expected_n_distances = round($percentile * scalar(@motif_list1) * scalar(@motif_list2));
  my $dist = -$MAXDOUBLE;

  # there are distances, but we don't expect any distances, so we use the best distance
  if ($expected_n_distances == 0) {
    $expected_n_distances = 1;
  }

  # selecting the correct distance
  if ($linkage_method == 0) { # max linkage
    $dist = $sorted_distances[$expected_n_distances - 1];
  }
  elsif ($linkage_method == 1) { # min linkage
    $dist = $sorted_distances[0];
  }
  elsif ($linkage_method == 2) { # avg linkage
    $dist = @sorted_distances[0];
    for (my $i = 1; $i < $expected_n_distances; $i++) {
      $dist += @sorted_distances[$i];
    }
    $dist = $dist/$expected_n_distances;
  }

  return($dist);
}
