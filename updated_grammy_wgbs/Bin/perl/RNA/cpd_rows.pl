#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

my $MAX_VALUE = 2 ** 128;

# =============================================================================
# Main part
# =============================================================================

if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my $file_ref;
my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, "../".$file_name) or die("Could not open $file_name.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $debug = get_arg("dbg", 0, \%args);
my $normal = get_arg("n", 0, \%args);
my $percentile = get_arg("i", 0, \%args);
my $bins = get_arg("b", 0, \%args);
my $pseudo_counts = get_arg("pc", 0, \%args);



####### READING INPUT SCORES
print STDERR "Parameters: bins=$bins, pseudo_counts=$pseudo_counts, percentile=$percentile\n";
print STDERR "Loading data ...\n";

my @matrix;         # [ [v11, v12, v13 ...] [v21, v22, v23 ...] ... ]
my %id_to_position;  # <id> => <position>
my @position_to_id;  # <position> => <id>

my $next_position = 0;
while (<$file_ref>) {
  chomp $_;
  my ($id1, $id2, $score) = split("\t", $_);

  if (not (defined $id_to_position{$id1})) {
    $id_to_position{$id1} = $next_position;
    $position_to_id[$next_position] = $id1;
    my @array;
    $matrix[$next_position] = \@array;
    $next_position++;
  }
  if (not (defined $id_to_position{$id2})) {
    $id_to_position{$id2} = $next_position;
    $position_to_id[$next_position] = $id2;
    my @array;
    $matrix[$next_position] = \@array;
    $next_position++;
  }
  my $pos1 = $id_to_position{$id1};
  my $pos2 = $id_to_position{$id2};

  my $ref = $matrix[$pos1];
  $$ref[$pos2] = $score;
  $ref = $matrix[$pos2];
  $$ref[$pos1] = $score;
}

# look for missing values, fill with defaults
for (my $i = 0; $i < $next_position; $i++) {
  my $values = $matrix[$i];
  for (my $j = 0; $j < $next_position; $j++) {
    if (not defined($$values[$j])) {
      $$values[$j] = 'x';
    }
  }
}

if ($debug) {
  print STDERR " ";
  for(my $j = 0; $j < $next_position; $j++) {
    print STDERR "\t$position_to_id[$j]";
  }
  print STDERR "\n";
  for (my $i = 0; $i < $next_position; $i++) {
    my $values = $matrix[$i];
    print STDERR "$position_to_id[$i]";
    for(my $j = 0; $j < $next_position; $j++) {
      print STDERR "\t$$values[$j]";
    }
    print STDERR "\n";
  }
}

print STDERR "Done.\n";



####### CALCULATING PVALUES
print STDERR "Calculating pvalues ...\n";

for (my $i = 0; $i < $next_position; $i++) {
  my $bg_values = $matrix[$i];
  my @bg_filtered_values;
  my @bg_pvalues;
  for (my $j = 0; $j < $next_position; $j++) {
    if ($$bg_values[$j] eq 'x') {
      $bg_pvalues[$j] = 'x';
    }
    else {
      push(@bg_filtered_values, $$bg_values[$j]);
    }
  }
  my $bg_size = scalar(@bg_filtered_values); # = $next_position;

  if ($normal) {
    print STDERR "Using normal distribution.\n";

    my ($mean, $std) = calculate_z_score_stats(@$bg_values);

    for(my $j = 0; $j < $next_position; $j++) {
      my $value = $$bg_values[$j];
      if ($value eq 'x') { next; }
      my $zscore = ($value - $mean) / $std;
      my $pvalue = NormalStd2Pvalue($zscore);

      $bg_pvalues[$j] = $pvalue;
    }
  }

  else {
    my $min = $bg_filtered_values[0];
    my $max = $bg_filtered_values[0];

    if ($debug) {
      print STDERR "$position_to_id[$i] Bins: \n";
      #print STDERR "  $min, $max\n";
    }

    # remove lowest $precentile values
    if ($percentile) {
      my @sorted_bg = sort {$a <=> $b} (@bg_filtered_values); # sort ascending
      my $bg_length = scalar(@sorted_bg);
      $max = $sorted_bg[$bg_length-1];
      $min = $sorted_bg[0];

      my $i_pos = int($percentile*$bg_length);
      my $i_value = $sorted_bg[$i_pos];
      for(my $j = 0; $j < $next_position; $j++) {
	if ($$bg_values[$j] ne 'x' and $$bg_values[$j] <= $i_value) {
	  $$bg_values[$j] = $min;
	}
      }
      #$$bg_values[$i] = $max;
      #print STDERR "p $min, $max\n";
    }

    my %values;        # <value> => [ <pos>, <pos> ...]
    my %values_counts; # <value> => [count]

    # with binning
    if ($bins > 0) {

      # find minimum, maximum
      if (not $percentile) {
	foreach my $v (@bg_filtered_values) {
	  if ($max < $v) {
	    $max = $v;
	  }
	  if ($min > $v) {
	    $min = $v;
	  }
	}

	#$$bg_values[$i] = $max;
	#print STDERR "n $min, $max\n";
      }

      # binning
      my $bin_size = ($max - $min)/$bins;
      if ($bin_size == 0) {
	$bin_size = 1;
      }

      for (my $j = 0; $j < $next_position; $j++) {
	if ($$bg_values[$j] eq 'x') { next; }

	my $v = int(($$bg_values[$j] - $min)/$bin_size);
	$v = ($v == $bins) ? $v-1 : $v;
	if (exists $values{$v}) {
	  my $ref = $values{$v};
	  push(@$ref, $j);
	}
	else {
	  $values{$v} = [$j];
	}
      }

      # pseudo counts
      for (my $k = 0; $k < $bins; $k++) {
	if (exists $values{$k}) {
	  my $ref = $values{$k};
	  $values_counts{$k} = scalar(@$ref) + $pseudo_counts;
	}
	else {
	  $values_counts{$k} = $pseudo_counts;
	}
	$bg_size += $pseudo_counts;
      }
    }

    # without binning
    else {
      for(my $j = 0; $j < $next_position; $j++) {
	my $v = $$bg_values[$j];
	if ($v eq 'x') { next; }

	if (exists $values{$v}) {
	  my $ref = $values{$v};
	  push(@$ref, $j);
	}
	else {
	  $values{$v} = [$j];
	}
      }

      foreach my $k (keys %values) {
	my $ref = $values{$k};
	$values_counts{$k} = scalar(@$ref);
      }
    }

    # calculating pvalues
    my @sorted_bg = sort {$b <=> $a} (keys %values); # sort descending
    my $count = 0;
    for(my $j = 0; $j < scalar(@sorted_bg); $j++) {
      my $v = $sorted_bg[$j];
      $count = $count + $values_counts{$v};
      my $pvalue = $count/$bg_size;

      my $ref = $values{$v};
      foreach my $id (@$ref) {
	$bg_pvalues[$id] = $pvalue;
      }

      if ($debug) {
	print STDERR " $v {pval=$pvalue, count=$count} ==> [";
	foreach my $id (@$ref) {
	  print STDERR "$id, ";
	}
	print STDERR "]\n";
      }
    }
  }

  $matrix[$i] = \@bg_pvalues;
}

if ($debug) {
  for (my $i = 0; $i < $next_position; $i++) {
    my $values = $matrix[$i];
    for(my $j = 0; $j < $next_position; $j++) {
      print STDERR "$$values[$j]\t";
    }
    print STDERR "\n";
  }
}

print STDERR "Done.\n";



####### A = M + Mt
print STDERR "Adding the transpose ...\n";

my @new_matrix;
for (my $i = 0; $i < $next_position; $i++) {
  my $values = $matrix[$i];
  my @new_values;

  for(my $j = 0; $j < $next_position; $j++) {
    if ($$values[$j] eq 'x') {
      $new_values[$j] = 'x';
    }
    else {
      my $ref = $matrix[$j];
      $new_values[$j] = ($$values[$j] + $$ref[$i])/2;
    }
  }
  $new_matrix[$i] = \@new_values;
}

if ($debug) {
  for (my $i = 0; $i < $next_position; $i++) {
    my $values = $new_matrix[$i];
    for(my $j = 0; $j < $next_position; $j++) {
      print STDERR "$$values[$j]\t";
    }
    print STDERR "\n";
  }
}

print STDERR "Done.\n";



####### Final Results
for (my $i = 0; $i < $next_position; $i++) {
  my $values = $new_matrix[$i];
  for(my $j = $i+1; $j < $next_position; $j++) {
    if ($$values[$j] eq 'x') { next; }
    my @ids = ($position_to_id[$i], $position_to_id[$j]);
    my @sids = sort @ids;
    print "$sids[0]\t$sids[1]\t$$values[$j]\n";
  }
}





# =============================================================================
# Subroutines
# =============================================================================

# --------------------------------------------------------
#
# --------------------------------------------------------
sub calculate_z_score_stats(@) {
  my (@values) = @_;

  my $size = scalar(@values);
  my $mean = 0;
  my $std = 0.0000001;

  if ($size > 0) {
    foreach my $i (@values) {
      if ($i eq 'x') { next; }
      $mean = $mean + $i;
    }
    $mean = $mean/$size;

    foreach my $i (@values) {
      if ($i eq 'x') { next; }
      $std = $std + ($mean-$i)*($mean-$i);
    }
    $std = sqrt($std/$size);
  }

  return ($mean, $std);
}

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

cpd_rows.pl

Given a file in the format <ID1> <ID2> <score> representing the distances between
every two IDs, computes the p-value of each entry based on the CPD of every row.
Matrix is assumed to be symmetrical, such that only one pair is given.
Output format: <ID1> <ID2> <p-value>

Assume: higher scores are better.

OPTIONS:
  -n           Assume normal distribution
  -b <num>     Divide scores into <num> bins (not for normal distribution)
  -i <num>     Ignore the high <num> percentile of the input distances.
  -pc <num>    Add <num> pseudo-counts to each bin [Default = 0].
  -dbg         Print debug information
