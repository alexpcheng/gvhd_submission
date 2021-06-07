#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $VIENNA_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs";


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
my $min_len = get_arg("min", 10, \%args);
my $max_len = get_arg("max", 80, \%args);


while (<$file_ref>) {
  chomp;
  my $struct = $_;
  my $total_size = length($struct);
  my $max_st = $total_size - $min_len;
  my $size = $max_len;
  if ($size > $total_size){
    $size = $total_size;
  }

  my $struct_num = $struct;
  $struct_num =~ s/\(/1 /g;
  $struct_num =~ s/\)/-1 /g;
  $struct_num =~ s/\./0 /g;
  my @all_struct = split(/ /, $struct_num); # the entire structure
  unshift(@all_struct, 0);

  my @curr_struct; # the current part of the structure
  @curr_struct[0] = 0;
  for (my $i = 1; $i <= $size; $i++) {
    $curr_struct[$i] = $curr_struct[$i-1] + $all_struct[$i];
  }

  ### find motifs ###
  for (my $st = 1; $st <= $max_st; $st++) { # possible starting points

    for (my $k = $min_len; $k <= $size; $k++) { # possible motif lengths

      # motif: ends with zero, and never reach negative values
      # drop motifs that contain points in each of the edges
      my @mot = @curr_struct;
      splice(@mot, $k+1);
      my $str_mot = substr($struct, $st-1, $k);

      if (legal_motif($str_mot, @mot)) {
	print "$str_mot\n";
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



# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# legal_motif(motif_string, list)
# ------------------------------------------------------------------------
sub legal_motif($@) {
  my ($str_motif, @motif) = @_;
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

  # motif cannot contain points in the edges
  # i.e. cannot extand a motif by points
  if (($str_motif =~ m/^\.(.*)/g) or ($str_motif =~ m/(.*)\.$/g)) {
    return(0);
  }

  return($i == $s);
}



# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

build_motifs_bg.pl <file_name> [options]

  build_motifs_bg.pl reads RNA structures from stdin and finds motifs
  in those structures.

OPTIONS
  -min <num>           minimal motif length (Default = 10).
  -max <num>           maximal motif length (Default = 80).
