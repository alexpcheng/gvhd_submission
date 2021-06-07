#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";


# =============================================================================
# Main
# =============================================================================
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $statistics_file = get_arg("s", "", \%args);
my $fmin = get_arg("fmin", -1, \%args);
my $fmax = get_arg("fmax", -1, \%args);
my $normal = get_arg("normal", 0, \%args);

my $cdata = get_arg ("c", 0, \%args);
my $csize = get_arg("cs", -1, \%args);

my $fsize_range = get_arg("fsize_range", 0, \%args);
my $fsize_min = get_arg("fsize_min", -1, \%args);
my $fsize_max = get_arg("fsize_max", -1, \%args);

my $max_size = get_arg("max", -1, \%args);
my $print_size = get_arg("ps", 0, \%args);

# reading bg values
my %bg_values; #[size] => {value, value ...}
open(INPUT_FILE, "<$statistics_file");
while(<INPUT_FILE>) {
  chomp;
  my ($value, $size) = split("\t", $_);
  if (not defined($size)) {
    $size = "NULL";
  }

  if (($fmin < 0 or $size >= $fmin) and ($fmax < 0 or $size <= $fmax)) {
    if (exists $bg_values{$size}) {
      my $ref = $bg_values{$size};
      push(@$ref, $value);
    }
    else {
      $bg_values{$size} = [$value];
    }
  }
}



# calculating pvalues, filtering BG by size
if ($csize >= 0) {
  while(<$file_ref>) {
    chomp;
    my @row = split(/\t/);

    my @bg_values;
    if ($fsize_min >= 0) {
      my $row_size = ($max_size >= 0 and $row[$csize] > $max_size) ? $max_size : $row[$csize];
      my $min = round($row_size - $row_size*$fsize_min);
      foreach my $k (keys %bg_values) {
	if ($min <= $k and $k <= $row_size) {
	  my $ref = $bg_values{$k};
	  push(@bg_values, @$ref);
	}
      }
    }
    elsif ($fsize_max >= 0) {
      my $row_size = ($max_size >= 0 and $row[$csize] > $max_size) ? $max_size : $row[$csize];
      my $max = round($row_size + $row_size*$fsize_max);
      foreach my $k (keys %bg_values) {
	if ($row_size <= $k and $k <= $max) {
	  my $ref = $bg_values{$k};
	  push(@bg_values, @$ref);
	}
      }
    }
    else {
      my $row_size = ($max_size >= 0 and $row[$csize] > $max_size) ? $max_size : $row[$csize];
      my $min = round($row_size - $row_size*$fsize_range);
      my $max = round($row_size + $row_size*$fsize_range);
      foreach my $k (keys %bg_values) {
	if ($min <= $k and $k <= $max) {
	  my $ref = $bg_values{$k};
	  push(@bg_values, @$ref);
	}
      }
    }
    my $bg_size = scalar(@bg_values);
    my $pvalue = -1;

    if ($bg_size > 0) {
      if ($normal) {
	my ($mean, $std) = calculate_z_score_stats(@bg_values);
	my $zscore = ($row[$cdata] - $mean)/$std;
	$pvalue = NormalStd2Pvalue($zscore);
      }
      else {
	my @sorted_bg = sort {$a <=> $b} @bg_values; # sort ascending
	my $i = 0;
	for (; $sorted_bg[$i] < $row[$cdata] and $i < $bg_size; $i++) {}
	$pvalue = ($bg_size > 0) ? ($bg_size - $i)/$bg_size : -1;
      }
    }

    my $str = "";
    for( my $v = 0; $v < scalar(@row); $v++) {
      if ($v != $cdata) {
	$str = $str."$row[$v]\t";
      }
      else {
	$str = $str."$pvalue\t";
	if ($print_size) {
	  $str = $str."$bg_size\t";
	}
      }
    }
    chop $str;

    print "$str\n";
  }
}

# calculating pvalues, using the entire BG distribution
else {
  my @bg_values;
  foreach my $k (keys %bg_values) {
    my $ref = $bg_values{$k};
    push(@bg_values, @$ref);
  }
  my $bg_size = scalar(@bg_values);

  if ($normal and $bg_size > 0) {
    my ($mean, $std) = calculate_z_score_stats(@bg_values);
    while(<$file_ref>) {
      chomp;
      my @row = split(/\t/);
      my $zscore = ($row[$cdata] - $mean) / $std;
      my $pvalue = NormalStd2Pvalue($zscore);

      my $str = "";
      for( my $v = 0; $v < scalar(@row); $v++) {
	if ($v != $cdata) {
	  $str = $str."$row[$v]\t";
	}
	else {
	  $str = $str."$pvalue\t";
	  if ($print_size) {
	    $str = $str."$bg_size\t";
	  }
	}
      }
      chop $str;

      print "$str\n";
    }
  }

  elsif ($bg_size > 0) {
    my @sorted_bg = sort {$a <=> $b} @bg_values; # sort ascending
    while(<$file_ref>) {
      chomp;
      my @row = split(/\t/);

      my $i = 0;
      for (; $sorted_bg[$i] < $row[$cdata] and $i < $bg_size; $i++) {}
      my $pvalue = ($bg_size > 0) ? ($bg_size - $i)/$bg_size : -1;

      my $str = "";
      for( my $v = 0; $v < scalar(@row); $v++) {
	if ($v != $cdata) {
	  $str = $str."$row[$v]\t";
	}
	else {
	  $str = $str."$pvalue\t";
	  if ($print_size) {
	    $str = $str."$bg_size\t";
	  }
	}
      }
      chop $str;

      print "$str\n";
    }
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
      $mean = $mean + $i;
    }
    $mean = $mean/$size;

    foreach my $i (@values) {
      $std = $std + ($mean-$i)*($mean-$i);
    }
    $std = sqrt($std/$size);
  }

  return ($mean, $std);
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub round($) {
  my ($num) = @_;
  my $i = int($num);
  if ($num - $i >= 0.5) {
    $i++;
  }

  return $i;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
__DATA__

compute_pvalue.pl <file>

   Takes in a background distribution of values, and transfers the values
   in the input file to pvalues.
   Assume: higher values are better.

Options:
   -c <num>:          Column number containing the data to be pvalued in
                      the input file (zero-based) [Default = 0].
   -s <str>:          The file containing the background values.
                      Format : [value] ([size])

   -fmin <num>        Filter the background values to values of size >= <num>.
   -fmax <num>        Filter the background values to values of size <= <num>.
   -normal            Assume bg values are normally distributed (use z-score).

   -cs <num>          Column number containing size, to filter the background
                      values by. [Default = ignore].
   -fsize_min <num>   Include background sizes in the range
                       [size]-<num>*[size] .. [size]
   -fsize_max <num>   Include background sizes in the range
                       [size] .. [size]+<num>*[size]
   -fsize_range <num> Include background sizes in the range
                       [size]-<num>*[size] .. [size]+<num>*[size]
                      [Default = 0].
   -max <num>         Convert any size >= <num> to num.
   -ps                Print bg size for each pvalue.
