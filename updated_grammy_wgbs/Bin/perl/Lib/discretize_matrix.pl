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

my $skip_rows = get_arg("skip", 1, \%args);
my $skip_columns = get_arg("skipc", 1, \%args);
my $min = get_arg("min", 2, \%args);
my $max = get_arg("max", -2, \%args);
my $min_prefix = get_arg("mins", "Induced ", \%args);
my $max_prefix = get_arg("mins", "Repressed ", \%args);

for (my $i = 0; $i < $skip_rows; $i++)
{
    my $line = <$file_ref>;
    chop $line;

    my @row = split(/\t/, $line);

    my $first = 1;
    for (my $j = 0; $j < $skip_columns; $j++)
    {
	if ($first == 1) { $first = 0; } else { print "\t"; }

	print "$row[$j]";
    }
	
    for (my $j = $skip_columns; $j < @row; $j++)
    {
	if ($first == 1) { $first = 0; } else { print "\t"; }

	print "$row[$j] $min_prefix\t$row[$j] $max_prefix";
    }

    print "\n";
}

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    my $first = 1;
    for (my $j = 0; $j < $skip_columns; $j++)
    {
	if ($first == 1) { $first = 0; } else { print "\t"; }

	print "$row[$j]";
    }
	
    for (my $j = $skip_columns; $j < @row; $j++)
    {
	if ($first == 1) { $first = 0; } else { print "\t"; }

	my $induced = (length($row[$j]) > 0 and $row[$j]) >= $min ? 1 : 0;
	my $repressed = (length($row[$j]) > 0 and $row[$j]) <= $max ? 1 : 0;

	print "$induced\t$repressed";
    }

    print "\n";
}

__DATA__

discretize_matrix.pl <file>

   Takes in a tab delimited file and discretizes the matrix based on thresholds

   -skip <num>:  Number of row headers to skip (default: 1)
   -skipc <num>: Number of column headers to skip (default: 1)

   -min <num>:   Minimum value above which to create an induced column (default: 2)
   -max <num>:   Maximum value below which to create a repressed column (default: -2)

   -mins <str>:  String to prepend to the induced column name (default: 'Induced ')
   -maxs <str>:  String to prepend to the repressed column name (default: 'Repressed ')

