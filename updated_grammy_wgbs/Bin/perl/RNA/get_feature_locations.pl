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
  open(FILE, $file_name) or die("Could not open $file_name.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $location_file = get_arg("l", 0, \%args);
my $features_str = get_arg("f", "3UTR", \%args);
my $exon = get_arg("exon", 0, \%args);
my $min = get_arg("min", 0, \%args);
my $max = get_arg("max", 0, \%args);

if (not $location_file) {
  print STDERR "Location file must be specified\n";
  print STDERR <DATA>;
  exit;
}
my @features = split(",", $features_str);

# reading ids
my @gene_ids;
while (<$file_ref>) {
  chomp;
  push(@gene_ids, $_);
}

# extracting features
foreach my $id (@gene_ids) {
  my $data = `grep -P "\\t$id\\s" $location_file`;
  my @lines = split("\n", $data);

  # print positions in the matching features that match exons
  if ($exon) {

    # read lines, saving data about exons and features
    my %exon_end; # start => end
    my %line_start;
    my $reverse = 0;
    foreach my $l (@lines) {
      my ($chr, $id, $start, $end, $feature) = split("\t", $l);
      $id =~ s/(.+)\s(.+)/$1/g;

      if ($feature eq "Exon") {
	if ($start > $end) {
	  $reverse = 1;
	  my $tmp = $start;
	  $start = $end;
	  $end = $tmp;
	}
	if ((not (exists $exon_end{$start})) or ($exon_end{$start} < $end)) {
	  $exon_end{$start} = $end;
	}
      }
      else {
	foreach my $f (@features) {
	  if ($feature eq $f) {
	    if ($start > $end) {
	      $reverse = 1;
	      my $tmp = $start;
	      $start = $end;
	      $end = $tmp;
	    }
	    $line_start{$start} = "$chr\t$id\t$start\t$end\t$feature";
	  }
	}
      }
    }

    # remove overlaping exons
    my @sorted_exon_starts = sort {$a <=> $b} keys %exon_end; # ascending
    my $prev;
    my $prev_end = 0;
    foreach my $s (@sorted_exon_starts) {
      if ($s < $prev_end) { # new exon starts before the previous ended
	if ($exon_end{$s} > $prev_end) {
	  $exon_end{$prev} = $exon_end{$s};
	}
	delete $exon_end{$s};
      }
      else {
	$prev = $s;
	$prev_end = $exon_end{$s};
      }
    }
    @sorted_exon_starts = sort {$a <=> $b} keys %exon_end;

    # print the feature parts that match exons
    my $p = 0;
    my @sorted_line_starts = sort {$a <=> $b} keys %line_start;
    foreach my $l (@sorted_line_starts) {
      my ($chr, $id, $start, $end, $feature) = split("\t", $line_start{$l});
      while ($exon_end{$sorted_exon_starts[$p]} < $start) { # exon end < feature start
	$p++;
      }

      my $exon_start = $sorted_exon_starts[$p];
      my $exon_end = $exon_end{$exon_start};
      while ((not ($end < $exon_start)) and $p < scalar(@sorted_exon_starts)) { # ! (feature end < exon start)

	if ($start <= $exon_start and $exon_end < $end) { # feature_start <= exon_start < exon_end < feature_end
	  if (($min <= 0 or $exon_end-$exon_start+1 >= $min) and ($max <= 0 or $exon_end-$exon_start+1 <= $max)) {
	    if ($reverse) {
	      print "$chr\t$id\t$exon_end\t$exon_start\t$feature\n";
	    }
	    else {
	      print "$chr\t$id\t$exon_start\t$exon_end\t$feature\n";
	    }
	  }
	  $p++;
	  $exon_start = $sorted_exon_starts[$p];
	  $exon_end = $exon_end{$exon_start};
	}
	elsif ($start <= $exon_start) { # feature_start <= exon_start < feature_end < exon_end
	  if (($min <= 0 or $end-$exon_start+1 >= $min) and ($max <= 0 or $end-$exon_start+1 <= $max)){
	    if ($reverse) {
	      print "$chr\t$id\t$end\t$exon_start\t$feature\n";
	    }
	    else {
	      print "$chr\t$id\t$exon_start\t$end\t$feature\n";
	    }
	  }
	  last;
	}
	elsif ($exon_end < $end){ # exon_start < feature_start < exon_end < feature_end
	  if (($min <= 0 or $exon_end-$start+1 >= $min) and ($max <= 0 or $exon_end-$start+1 <= $max)){
	    if ($reverse) {
	      print "$chr\t$id\t$exon_end\t$start\t$feature\n";
	    }
	    else {
	      print "$chr\t$id\t$start\t$exon_end\t$feature\n";
	    }
	  }
	  $p++;
	  $exon_start = $sorted_exon_starts[$p];
	  $exon_end = $exon_end{$exon_start};
	}
	else { # exon_start < feature_start < feature_end < exon_end
	  if (($min <= 0 or $end-$start+1 >= $min) and ($max <= 0 or $end-$start+1 <= $max)) {
	    if ($reverse) {
	      print "$chr\t$id\t$end\t$start\t$feature\n";
	    }
	    else {
	      print "$chr\t$id\t$start\t$end\t$feature\n";
	    }
	  }
	  last;
	}
      }
    }
  }

  # simply prints the matching features
  else {
    foreach my $l (@lines) {
      my ($chr, $id, $start, $end, $feature) = split("\t", $l);
      $id =~ s/(.+)\s(.+)/$1/g;

      foreach my $f (@features) {
	if ($feature eq $f and ($min <= 0 or $end-$start+1 >= $min) and ($max <= 0 or $end-$start+1 <= $max)) {
	  print "$chr\t$id\t$start\t$end\t$feature\n";
	}
      }
    }
  }
}

# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

get_feature_locations.pl <file_name> [options]

  Extract the locations of a specific feature for a list of ids.
  Input file contains a list of ids to extract.

OPTIONS
  -l <chr file>   File containing genomic annotations in the format
                  <chr> <id> <start> <end> <feature>
  -f <feature>    The features to extract: 3UTR/5UTR/Coding/Transcript.
                  One or more NON-OVERLAPING features, seperated by "," (Default = 3UTR)
  -exon           Extract only locations that match exons
  -min <num>      Print only locations longer than or equal to <num>
  -max <num>      Print only locations shorter than or equal to <num>
