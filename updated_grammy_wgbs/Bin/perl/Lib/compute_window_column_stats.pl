#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/vector_ops.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $column = get_arg("c", -1, \%args);
my $skip_rows = get_arg("skip", 1, \%args);
my $skip_columns = get_arg("skipc", 1, \%args);
my $empty = get_arg("empty", "", \%args);
my $precision = get_arg("p", 3, \%args);
my $window_size = get_arg("w", 0, \%args);
my $compute_entropy = get_arg("e", 0, \%args);
my $compute_std = get_arg("std", 0, \%args);
my $compute_mean = get_arg("m", 0, \%args);
my $compute_median = get_arg("med", 0, \%args);
my $compute_ratio_to_window_mean = get_arg("rm", 0, \%args);
my $compute_sum = get_arg("s", 0, \%args);
my $compute_num_above_or_equal_min = get_arg("gemin", "", \%args);
my $compute_num_below_or_equal_max = get_arg("lemax", "", \%args);
my $types = get_arg("types", "", \%args);

for (my $i = 0; $i < $skip_rows; $i++) { my $line = <$file_ref>; print "$line"; }

my @matrix;
my $row_counter = 0;
my $num_columns = 0;
my @row_types ;

while(<$file_ref>)
{
    chomp;

    if ($row_counter > 0 and $row_counter % 100000 == 0) { print STDERR "Loading row $row_counter\n"; }

    my @row = split(/\t/,$_,-1);

    for (my $i = 0; $i < @row; $i++)
    {
	$matrix[$row_counter][$i] = $row[$i];
    }
    if($types ne ""){$row_types[$row_counter]=$row[$types]}

    $num_columns = scalar(@row)>$num_columns?scalar(@row):$num_columns;
    $row_counter++;
}

for (my $i = 0; $i < $row_counter; $i++)
{
    my $first = 1;
    for (my $j = 0; $j < $skip_columns; $j++)
    {
	if ($first == 0) { print "\t"; } else { $first = 0; }

	print "$matrix[$i][$j]";
    }

    for (my $j = $skip_columns; $j < $num_columns; $j++)
    {
	if ($column == -1 or $column == $j)
	{
	    my @vec = &GetVec($i, $j);

	    my $num;

	    if ($compute_entropy == 1) { $num = &vec_entropy(\@vec); }
	    elsif ($compute_mean == 1) { $num = &vec_avg(\@vec); }
	    elsif ($compute_median == 1) { $num = &vec_median(\@vec); }
	    elsif ($compute_ratio_to_window_mean == 1) { $num = $matrix[$i][$j] / &vec_avg(\@vec); }
	    elsif ($compute_std == 1) { $num = &vec_std(\@vec); }
	    elsif ($compute_sum == 1) { $num = &vec_sum(\@vec); }
	    elsif (length($compute_num_above_or_equal_min) > 0) { $num = &vec_num_above_or_equal_min(\@vec, $compute_num_above_or_equal_min); }
	    elsif (length($compute_num_below_or_equal_max) > 0) { $num = &vec_num_below_or_equal_max(\@vec, $compute_num_below_or_equal_max); }

	    if ($first == 0) { print "\t"; } else { $first = 0; }

	    if (($empty ne "") && ($matrix[$i][$j] ne "")){
		print "$matrix[$i][$j]";
	    }
	    else {
		print &format_number($num, $precision);
	    }
	}
	else
	{
	    if ($first == 0) { print "\t"; } else { $first = 0; }

	    print "$matrix[$i][$j]";
	}
    }
    print "\n";
}

sub GetVec ()
{    
    my ($row, $column) = @_;

    my @res;

    if ($types eq ""){
      my $start = ($row - $window_size) >= 0 ? $row - $window_size : 0;
      my $end = ($row + $window_size) < ($row_counter - 1) ? ($row + $window_size) : ($row_counter - 1);
      
      for (my $i = $start; $i <= $end; $i++)
	{
	  push(@res, $matrix[$i][$column]);
	}
    }
    else{
      my $i=$row-1;
      my $w=0;
      while($i>=0 and $w<$window_size){
	if ($row_types[$i] eq $row_types[$row]){
	  unshift @res,$matrix[$i][$column];
	  $w++ ;
	}
	$i--;
      }
      push @res,$matrix[$row][$column];
      $i=$row+1;
      $w=0;
      while($i<=$row_counter and $w<$window_size){
	if ($row_types[$i] eq $row_types[$row]){
	  push @res,$matrix[$i][$column];
	  $w++ ;
	}
	$i++;
      }
    }

    return @res;
}

__DATA__

compute_window_column_stats.pl <file>

   Takes in a tab delimited file and computes a moving average for specified columns

   -c <num>:     Column on which to compute the statistic (default: -1 for all columns)

   -skip <num>:  Number of row headers to skip (default: 1)
   -skipc <num>: Number of column headers to skip (default: 1)
   -empty:       compute and replace only for empty cells

   -p <num>:     Precision (default: 3)

   -w <num>:     Window size on which to compute for the column (default: 0)
   -types <num>: Calculate separately by types given in column <num> (default: off)

   STATISTIC TO COMPUTE

   -e:           Entropy (assumes categorical values)
   -lemax <num>: Number that are less than or equal to <num>
   -gemin <num>: Number that are above or equal to <num>
   -m:           Mean
   -med:         Median
   -rm:          Ratio of the number to the mean of the window
   -std:         Standard deviation
   -s:           Sum

