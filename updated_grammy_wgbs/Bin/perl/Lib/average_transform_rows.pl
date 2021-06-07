#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $log2 = log(2);

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

my $column_list = get_arg("zero", "", \%args);
my $skip_num = get_arg("skip", 0, \%args);
my $skipc_num = get_arg("skipc", 1, \%args);
my $precision = get_arg("precision", 3, \%args);
my $min = get_arg("min", "", \%args);
my $max = get_arg("max", "", \%args);
my $log_ratio = get_arg("log_ratio", 0, \%args);
my $rank = get_arg("rank", "", \%args);
my $mean_columns = get_arg("mean_columns", "", \%args);
my $median_center = get_arg("median_center", 0, \%args);
my $no_average = get_arg("no_average", 0, \%args);
my $std_scale = get_arg("std_scale", 0, \%args);
my $max_scale = get_arg("max_scale", 0, \%args);

my %mean_columns_hash;
if (length($mean_columns) > 0)
{
  my @row = split(/\,/, $mean_columns);
  for (my $i = 0; $i < @row; $i++)
  {
    $mean_columns_hash{$row[$i]} = "1";
  }
}

for (my $i = 0; $i < $skip_num; $i++)
{
  my $line = <$file_ref>;

  print "$line";
}

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $num = 0;
  my $sum = 0;
  my $sum_xx = 0;
  my $max_num = -1e300;

  for (my $i = $skipc_num; $i < @row; $i++)
  {
    if (length($row[$i]) > 0)
    {
      if (length($min) > 0 and $row[$i] < $min) { $row[$i] = $min; }
      if (length($max) > 0 and $row[$i] > $max) { $row[$i] = $max; }
      if ($row[$i] > $max_num) { $max_num = $row[$i]; }

      if (length($mean_columns) == 0 or $mean_columns_hash{$i} eq "1")
      {
	$sum += $row[$i];
        $sum_xx += $row[$i] * $row[$i];
	$num++;
      }
    }
  }

  my $mean = 0;
  my $std = 1;
  if ($num > 0)
  {
    $mean = $sum / $num;
    $std = ($sum_xx / $num - $mean * $mean > 0) ? sqrt($sum_xx / $num - $mean * $mean) : 0;
  }

  if ($median_center == 1)
  {
    my @sorted_data;
    for (my $i = $skipc_num; $i < @row; $i++) { if (length($row[$i]) > 0) { push(@sorted_data, $row[$i]); } }
    @sorted_data = sort { $a <=> $b } @sorted_data;
    my $sorted_data_size = @sorted_data;
    if ($sorted_data_size % 2 == 1)
    {
      $mean = $sorted_data[int(($sorted_data_size - 1) / 2)];
    }
    else
    {
      $mean = ($sorted_data[int($sorted_data_size / 2)] + $sorted_data[int($sorted_data_size / 2) - 1]) / 2;
    }
  }

  if ( $skipc_num > 0 ) {
    print join("\t",@row[0..($skipc_num-1)]);
  }

  if (length($rank) > 0)
  {
    my @sorted_data;
    for (my $i = $skipc_num; $i < @row; $i++) { if (length($row[$i]) > 0) { push(@sorted_data, "$i\t$row[$i]"); } }
    @sorted_data =
      sort
      {
	my @aa = split(/\t/, $a);
	my @bb = split(/\t/, $b);

	return $rank eq "Asc" ? $aa[1] <=> $bb[1] : $bb[1] <=> $aa[1];
      }
      @sorted_data;

    my @ranked_values;
    for (my $i = 0; $i < @sorted_data; $i++)
    {
      my @item = split(/\t/, $sorted_data[$i]);
      $ranked_values[$item[0]] = $i;
    }

    for (my $i = $skipc_num; $i < @row; $i++)
    {
      if ( $i > 0 ) {
	print "\t";
      }

      if (length($row[$i]) > 0)
      {
	print "$ranked_values[$i]";
      }
    }
  }
  else
  {
    for (my $i = $skipc_num; $i < @row; $i++)
    {
      if ( $i > 0 ) {
	print "\t";
      }
     
      if (length($row[$i]) > 0)
      {
	my $output_num;
	    
	if ($no_average == 1) { $output_num = &format_number($row[$i], $precision); }
	elsif ($log_ratio == 1) { $output_num = &format_number(log($row[$i] / $mean) / $log2, $precision); }
	else { $output_num = &format_number($row[$i] - $mean, $precision); }

	if (($std_scale == 1) && ($std != 0))
	{
	  $output_num = &format_number($output_num / $std, $precision);
	}

	if ($max_scale == 1)
	{
	  $output_num = &format_number($output_num / $max_num, $precision);
	}

	print $output_num;
      }
    }
  }

  print "\n";
}

__DATA__

average_transform_rows.pl <source file>

   Subtracts the average of each row from each entry in the row

   -skip <num>:          Skip num rows in the source file and just print them (default: 0)
   -skipc <num>:          Skip num columns in the source file and just print them (default: 1)
   -precision <num>:     Precision of the numbers printed (default: 3 digits)
   -min <num>:           Values below num are converted to num
   -max <num>:           Values above num are converted to num
   -log_ratio:           Each value is printed as the log-ratio to the subtracted average
   -rank <str>:          Each value is printed as its rank within the row (<str>: Asc/Des)
   -no_average:          Averaging is not done at all (useful for trimming values)
   -mean_columns <list>: The mean is computer from the column <list> (format: 1,3,6)
   -median_center:       Use the median of the row as the average to subtract
   -std_scale:           Divide each number by the std of the row
   -max_scale:           Divide each number by the max in the row (positive numbers are thus [0,1])

