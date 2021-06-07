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

for (my $i = 0; $i < $skip_rows; $i++) { my $line = <$file_ref>; print "$line"; }

my @matrix;
my $row_counter = 0;
my $num_columns = 0;
while(<$file_ref>)
{
    chop;

    if ($row_counter > 0 and $row_counter % 1000 == 0) { print STDERR "Loading row $row_counter\n"; }

    my @row = split(/\t/);

    for (my $i = 0; $i < @row; $i++)
    {
	$matrix[$row_counter][$i] = $row[$i];
    }

    $num_columns = @row;
    $row_counter++;
}

for (my $i = $skip_columns; $i < $num_columns; $i++)
{
    if ($column == -1 or $column == $i)
    {
      my $n=$row_counter;
      while($n>1){
	$n--;
	my $target_row = int(rand($n+1));
	my $tmp = $matrix[$n][$i];
	$matrix[$n][$i] = $matrix[$target_row][$i];
	$matrix[$target_row][$i] = $tmp;
      }
    }
}

for (my $i = 0; $i < $row_counter; $i++)
{
    print "$matrix[$i][0]";
    for (my $j = 1; $j < $num_columns; $j++)
    {
	print "\t$matrix[$i][$j]";
    }
    print "\n";
}

__DATA__

permute_column.pl <file>

   Takes in a tab delimited file and permutes within a specified column

   -c <num>:     Column on which to compute the statistic (default: -1 for all columns)

   -skip <num>:  Number of row headers to skip (default: 1)
   -skipc <num>: Number of column headers to skip (default: 1)

