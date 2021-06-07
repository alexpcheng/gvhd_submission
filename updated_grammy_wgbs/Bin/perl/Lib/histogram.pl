#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $column = get_arg("c", 0, \%args);
my $min_value = get_arg("min", -1, \%args);
my $max_value = get_arg("max", 1, \%args);
my $step_value = get_arg("step", 0.01, \%args);
my $by_fraction = get_arg("by_fraction", 0, \%args);
my $skip_rows = get_arg("skip", 0, \%args);
my $print_header = get_arg("ph", 0, \%args);
my $print_empty = get_arg("empty", 0, \%args);
my $auto_bins = get_arg("bins", 0, \%args);
my $print_min_max = get_arg("print_min_max", 0, \%args);

$min_value =~ s/\"//g;
$max_value =~ s/\"//g;

my $tmp_file = "tmp_histogram_".int(rand(10000000000)) ;
my $find_min=0;
my $find_max=0;
if ($min_value eq "auto") {$find_min=1}
if ($max_value eq "auto") {$find_max=1}

if($find_min or $find_max){
  open(TMP,">$tmp_file");
  while(my $line=<$file_ref>){
    print TMP $line;
    chomp $line;
    my @row = split /\t/,$line;
    if ($find_min and ($min_value eq "auto" or $row[$column]<$min_value)){
      $min_value=$row[$column];
    }
    if ($find_max and ($max_value eq "auto" or $row[$column]>$max_value)){
      $max_value=$row[$column];
    }
  }
  close TMP;
  open(TMP,"$tmp_file");
  $file_ref=\*TMP;
  print STDERR "Min=$min_value  Max=$max_value\n";
  print "Min=$min_value  Max=$max_value\n" if ( $print_min_max );
}

my $num_bins = ($max_value-$min_value) / $step_value;

if ($auto_bins>1){
  $auto_bins--;
  $step_value=($max_value-$min_value)/$auto_bins;
  $num_bins=$auto_bins;
}


my @bins;
my $total = 0;

for (my $i = 0; $i < $skip_rows; $i++) {
  my $line = <$file_ref>;
  if ($print_header){
    print $line;
  }
}

my @bin_values;
while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $num = $row[$column];

  if ($by_fraction == 0)
  {
    $total++;

      if ($num >= $min_value and $num <= $max_value)
      {
	  my $bin = int(sprintf("%.10f",$num_bins * ($num - $min_value) / ($max_value - $min_value)));
	  $bins[$bin]++;
      }
      elsif ($num < $min_value)
      {
	$bins[0]++;
      }
      elsif ($num > $max_value)
      {
	$bins[int($num_bins)]++;
      }
  }
  else
  {
      $bin_values[$total] = $num;
      
      $total++;
  }
}

if ($by_fraction == 1)
{
    my @bins_num;
    for (my $i = 0; $i < $total; $i++)
    {
	my $bin = int(sprintf("%.10f",$num_bins * ($i / $total - $min_value) / ($max_value - $min_value)));
	$bins[$bin] += $bin_values[$i];
	$bins_num[$bin]++;

	#print STDERR "bins[$bin]=$bins[$bin] num=$bins_num[$bin] val=$bin_values[$i]\n";
    }

    for (my $i = 0; $i < $num_bins; $i++)
    {
	$bins[$i] /= $bins_num[$i];
    }
}

my $current = $min_value;
my $cumulative = 0;
for (my $i = 0; $i <= $num_bins; $i++)
{
  if ( $print_empty || (length($bins[$i]) > 0) )
  {
    print "$current\t";
    print "[";
    print $current;
    print " ";
    print ($current + $step_value);
    print "]\t";
    if (length($bins[$i]) == 0)
    {
    	print "0\t";
    }
    else
    {
    	print &format_number($bins[$i], 3) . "\t";
    }
    print &format_number($bins[$i] / $total, 4) . "\t";
    $cumulative += $bins[$i] / $total;
    print &format_number($cumulative, 4) . "\n";
  }

  $current = sprintf("%.10f",$current+$step_value)+0;
}

if ($find_min or $find_max){
  close TMP;
  unlink $tmp_file ;
}

__DATA__

histogram.pl <file>

   Produce a histogram out of values specified in a column
   NOTE: precision of the script is 1e-10

   -c <num>:       Column of the numbers (default: 0)

   -min <num>:     Minimum value to consider (default: -1). specify "auto" to
                   automatically choose minimum.
   -max <num>:     Maximum value to consider (default: 1). specify "auto" to
                   automatically choose maximum.
   -step <num>:    Size of each bin (default: 0.01).
   
   -bins <num>:    Number of bins. selects step size to be (max-min)/<num>

   -by_fraction:   Build the histogram by taking consecutive numbers in the column 
                   and averaging their value, where the number of consecutive numbers
                   taken is determined by -step

   -skip <num>:    Number of rows to skip in the input file (default: 0)
   
   -ph:            Print header rows
   -empty     :    Print all bins (including empty ones)

   -print_min_max : Print minimun and maximum values at the start.

