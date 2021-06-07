#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/RNA/libRNAclustering.pl";
require "$ENV{PERL_HOME}/Lib/load_args.pl";

# =============================================================================
# Constants
# =============================================================================
my $MAX_ROWS = 1000;
my $NORMALIZATION_DIR = "$ENV{GENIE_HOME}/Data/mRNA/Distances";

# =============================================================================
# Main part
# =============================================================================

# help mesasge
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

# input file (containing the sequences)
my $file = $ARGV[0];
my $file_ref;
if (length($file) < 1 or $file =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

# arguments
my %args = load_args(\@ARGV);
my $comparison_file = get_arg("c", "", \%args);
my $dist_func = get_arg("d", "f", \%args);
my $max = get_arg("max", -1, \%args);
my $single = get_arg("single", 0, \%args);
my $linkage_method = get_arg("l", 0, \%args);
if ($linkage_method eq "avg") {
  $linkage_method = 2;
}
elsif ($linkage_method eq "min") {
  $linkage_method = 1;
}
else {
  $linkage_method = 0;
}
my $percentile = get_arg("p", 1, \%args);
my $maxn = get_arg("maxn", 0, \%args);





# temporary output file
my $output_file_ref = \*STDOUT;
if ($maxn) {
  open(OUT, ">tmp_output_$$") or die("Could not open output file.\n");
  $output_file_ref = \*OUT;
}

# calculating distances
my $count;
if ($single) {
  if ($comparison_file eq "") {
    $count = RNAdistance_structure($file_ref, $output_file_ref, $dist_func, $max);
  }
  else {
    $count = RNAdistance_structure_file($file_ref, $output_file_ref, $dist_func, $max, $comparison_file);
  }
}
else {
  if ($comparison_file eq "") {
    $count = RNAdistance_motif($file_ref, $output_file_ref, $dist_func, $max, $linkage_method, $percentile);
  }
  else {
    $count = RNAdistance_motif_file($file_ref, $output_file_ref, $dist_func, $max, $linkage_method, $percentile, $comparison_file);
  }
}

# filtering results to reach the wanted maximal number
if ($maxn) {
  close($output_file_ref);

  if ($count <= $maxn) {
    my $out = `cat tmp_output_$$; /bin/rm tmp_output_$$;`;
    print "$out";
  }
  else {
    my %distances;
    my %dist_counts;
    my $max_dist = 0;

    open(INPUT, "tmp_output_$$") or die("Could not open output file.\n");
    while (<INPUT>) {
      chomp $_;
      $_ =~ m/(.+)\t(.+)\t(\d+)/g;
      $distances{$3} = $distances{$3}."$_\n";
      $dist_counts{$3}++;
    }
    close(INPUT);
    `/bin/rm tmp_output_$$`;

    my @dist_list = sort {$a <=> $b} keys(%distances);
    my $total_count = 0;
    for(my $i = 0; ($i < scalar(@dist_list)) and ($total_count + $dist_counts{$dist_list[$i]} < $maxn); $i++) {
      print "$distances{$dist_list[$i]}";
      $total_count = $total_count + $dist_counts{$dist_list[$i]};
    }
  }
}




# =============================================================================
# Subroutines
# =============================================================================

# -----------------------------------------------------------------------------
# RNAdistance_structure(structure file, distance_type, max_distance)
#
# Reads RNA structures from a file, and calculate the distance between each pair
# of structures in the file.
# -----------------------------------------------------------------------------
sub RNAdistance_structure($$$) {
  my ($file_ref, $output_file_ref, $distance_type, $max_distance) = @_;
  my $count = 0;

  # read the sequences from input file
  my %structures;
  while (<$file_ref>) {
    my $line = $_;
    chomp $line;

    my  ($id, $seq) = split("\t", $line);
    $structures{$id} = $seq;
  }
  close($file_ref);

  # RNAdistance
  my @structure_keys = keys(%structures);
  my $rows = 0;
  my @id1 = ();
  my @id2 = ();
  my @struct1 = ();
  my @struct2 = ();

  for my $id (@structure_keys) {
    foreach my $j (@structure_keys) {
      push(@id1, $id);
      push(@id2, $j);
      push(@struct1, $structures{$id});
      push(@struct2, $structures{$j});
      $rows++;

      # run RNAdistance
      if ($rows >= $MAX_ROWS) {
	$rows = 0;
	my @distances = RNAsequence_distance(\@struct1, \@struct2, $distance_type);
	my $size = scalar(@distances);
	for (my $i = 0; $i < $size; $i++) {
	  if (($max_distance < 0) or ($distances[$i] <= $max_distance)) {
	    print $output_file_ref "$id1[$i]\t$id2[$i]\t$distances[$i]\n";
	    $count++;
	  }
	}

	# empty lists
	@id1 = ();
	@id2 = ();
	@struct1 = ();
	@struct2 = ();
      }
    }
  }

  # last time
  my @distances = RNAsequence_distance(\@struct1, \@struct2, $distance_type);	
  my $size = scalar(@distances);
  for (my $i = 0; $i < $size; $i++) {
    if (($max_distance < 0) or ($distances[$i] <= $max_distance)) {
      print $output_file_ref "$id1[$i]\t$id2[$i]\t$distances[$i]\n";
      $count++;
    }
  }

  return $count;
}



# -----------------------------------------------------------------------------
# RNAdistance_structure_file(structure file, distance_type, max_distance, comparison file)
#
# Reads RNA structures from a file, and calculate the distance between each pair
# of structures in the file.
# -----------------------------------------------------------------------------
sub RNAdistance_structure_file($$$$) {

  my ($file_ref, $output_file_ref, $distance_type, $max_distance, $comparison_file) = @_;
  my $count = 0;

  # read the clusters from input files
  my %structures;

  while (<$file_ref>) {
    my $line = $_;
    chomp $line;

    my  ($id, $struct) = split("\t", $line);
    $structures{$id} = $struct;
  }
  close($file_ref);

  # RNAdistance
  my $rows = 0;
  my @id1 = ();
  my @id2 = ();
  my @struct1 = ();
  my @struct2 = ();

  open(COMP, $comparison_file) or die("cannot open $comparison_file");
  while (<COMP>) {
    chomp($_);
    my ($id1, $id2) = split("\t", $_);
    push(@id1, $id1);
    push(@id2, $id2);
    push(@struct1, $structures{$id1});
    push(@struct2, $structures{$id2});
    $rows++;

    # run RNAdistance
    if ($rows >= $MAX_ROWS) {
      $rows = 0;
      my @distances = RNAsequence_distance(\@struct1, \@struct2, $distance_type);	
      my $size = scalar(@distances);
      for (my $i = 0; $i < $size; $i++) {
	if (($max_distance < 0) or ($distances[$i] <= $max_distance)) {
	  print $output_file_ref "$id1[$i]\t$id2[$i]\t$distances[$i]\n";
	  $count++;
	}
      }

      # empty lists
      @id1 = ();
      @id2 = ();
      @struct1 = ();
      @struct2 = ();
    }
  }

  # last time
  my @distances = RNAsequence_distance(\@struct1, \@struct2, $distance_type);
  my $size = scalar(@distances);
  for (my $i = 0; $i < $size; $i++) {
    if (($max_distance < 0) or ($distances[$i] <= $max_distance)) {
      print $output_file_ref "$id1[$i]\t$id2[$i]\t$distances[$i]\n";
      $count++;
    }
  }

  return $count;
}


# -----------------------------------------------------------------------------
# RNAdistance_motif(motif file, distance_type, max_distance, linkage_method, percentile)
#
# Reads RNA motifs (lists of structures) from a file, and calculate the distance 
# between each pair of motifs (lists of structures).
# -----------------------------------------------------------------------------
sub RNAdistance_motif($$$$$) {
  my ($file_ref, $output_file_ref, $distance_type, $max_distance, $linkage_method, $percentile) = @_;
  my $count = 0;

  # read the clusters from input files
  my %structures;
  while (<$file_ref>) {
    my $line = $_;
    chomp $line;

    my  ($id, @motifs) = split("\t", $line);
    $structures{$id} = \@motifs;
  }
  close($file_ref);

  # RNAdistance
  foreach my $id1 (keys(%structures)) {
    foreach my $id2 (keys(%structures)) {
      my $dist = RNAmotif_distance($structures{$id1}, $structures{$id2}, $distance_type, $linkage_method, $percentile);
      if (($max_distance < 0) or ($dist <= $max_distance)) {
	print $output_file_ref "$id1\t$id2\t$dist\n";
	$count++;
      }
    }
  }

  return $count;
}

# -----------------------------------------------------------------------------
# RNAdistance_motif_file(motif file, distance_type, max_distance, linkage_method, percentile, comp file)
#
# Reads RNA motifs (lists of structures) from a file, and calculate the distance 
# between each pair of motifs (lists of structures).
# -----------------------------------------------------------------------------
sub RNAdistance_motif_file($$$$$$) {
  my ($file_ref, $output_file_ref, $distance_type, $max_distance, $linkage_method, $percentile, $comparison_file) = @_;
  my $count = 0;

  # read the clusters from input files
  my %structures;
  while (<$file_ref>) {
    my $line = $_;
    chomp $line;

    my  ($id, @motifs) = split("\t", $line);
    $structures{$id} = \@motifs;
  }
  close($file_ref);

  # RNAdistance
  open(COMP, $comparison_file) or die("cannot open $comparison_file");

  while (<COMP>) {
    chomp($_);
    my ($id1, $id2) = split("\t", $_);
    my $dist = RNAmotif_distance($structures{$id1}, $structures{$id2}, $distance_type, $linkage_method, $percentile);
    if (($max_distance < 0) or ($dist <= $max_distance)) {
      print $output_file_ref "$id1\t$id2\t$dist\n";
      $count++;
    }
  }

  return $count;
}



# ------------------------------------------------------------
# Help message
# ------------------------------------------------------------
__DATA__

RNAdistance.pl <cluster_file>

Reads RNA clusters (lists of structures) from a file, and calculate the distance
between each pair of clusters (lists of structures).

Cluster file format:  <cluster id> <list of structures>
The output format: <cluster id> <cluster id> <distance>

Distance functions:
 f = full structure, tree editing distance
 F = full structure, string alignment
 h = HIT structure, tree editing distance
 H = HIT structure, string alignment
 w = weighted coarse structure, tree editing distance
 W = weighted coarse structure, string alignment
 c = coarse structure, tree editing distance
 C = coarse structure, string alignment

Options:
  -c <comparison_file>  Calculate only distances given in the comparison file.
                        Comparison file format: <cluster id> <cluster id>
  -d <distance_type>    Distance function type (Default: f)
  -l <min | max | avg>  Linkage method (Default: max)
  -p <num>              Linkage percentile (Default: 1)
  -max <num>            Do not output distances larger than <num>
  -maxn <num>           Output no more than <num> smallest distances.
  -single               If there is only a single structure in each line
