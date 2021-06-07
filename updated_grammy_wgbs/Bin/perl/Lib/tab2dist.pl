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


my $index_col = get_arg("index_col", 0, \%args);
my $dist_col = get_arg("dist_col", 1, \%args);



my $use_min_as_lower = get_arg("use_min_as_lower", 0, \%args);

my $default_val = get_arg("default_val", 0, \%args);




my @indices;
my @dist;

my $first_row = 1;
my $min_index = 0;
my $max_index = 0;

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);
  
  push(@indices, $row[$index_col]);
  push(@dist, $row[$dist_col]);
  
  if ($first_row == 1)
  {
	$min_index = $row[$index_col];
	$max_index = $row[$index_col];
	$first_row = 0;
  }
  else
  {
	if ($min_index > $row[$index_col])
	{
		$min_index = $row[$index_col];
	}
	if ($max_index < $row[$index_col])
	{
		$max_index = $row[$index_col];
	}
  }
}

if ($use_min_as_lower  == 0)
{
	if ($min_index > 0)
	{
		$min_index = 0;
	}
}
#print STDERR "indecis: @indices\n";
#print STDERR "dist: @dist\n";

my $lower_index = get_arg("lower_index", $min_index , \%args);
my $upper_index = get_arg("upper_index", $max_index , \%args);

if ($lower_index > $min_index)
{
	die("min index ($min_index) smaller then lower index ($lower_index)\n");
}

if ($upper_index < $max_index)
{
	die("max index ($min_index) larger then upper index ($upper_index)\n");
}

print STDOUT "<Factor>\n";
print STDOUT "\t<RvVec>\n";
print STDOUT "\t\t<Rv Name=\"Index\">\n";
print STDOUT "\t\t\t<domain type=\"int\">\n";
print STDOUT "\t\t\t\t<lower val=\"$lower_index\"></lower>\n";
print STDOUT "\t\t\t\t<upper val=\"$upper_index\"></upper>\n";
print STDOUT "\t\t\t</domain>\n";
print STDOUT "\t\t</Rv>\n";
print STDOUT "\t</RvVec>\n";
print STDOUT "\t<JointDistribution DefaultVal=\"$default_val\" >\n";
#print STDERR "indecis: @indices\n";
my $rows_num = @indices;
#print STDERR "$rows_num\n";
for (my $i = 0; $i < $rows_num; $i++)
{
	my $cur_index = $indices[$i];
	my $cur_val = $dist[$i];
	print STDOUT "\t\t<JointDistributionEntry Entry=\"$cur_index\" Value=\"$cur_val\"></JointDistributionEntry>\n";
}
print STDOUT "\t</JointDistribution>\n";
print STDOUT "</Factor>\n";




__DATA__

tab2dist.pl <file>

   Produce a distribution over an index value (a Factor_cl that contain one IntRv named Index)

   -index_col <num>:	the index column (default: 0)
   -dist_col <num>: 	the distribution probability column (default: 0)
   -lower_index <num>:	the minimal index for the distribution (defualt: minimum between 0 and min index)
   -upper_index <num>:	the maximal index for the distribution (defualt: max index given)
   -default_val <double> the defualt probability (default: 0)
   -use_min_as_lower if no lower given - takes the min index as lower insted of the minimum between 0 and min index

