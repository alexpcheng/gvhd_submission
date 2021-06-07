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

my $column_list = get_arg("zero", "", \%args);
my $skip_num = get_arg("skip", 0, \%args);
my $precision = get_arg("precision", 3, \%args);

my @column_lists = split(/ /, $column_list);

for (my $i = 0; $i < $skip_num; $i++)
{
  my $line = <$file_ref>;

  print "$line";
}

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  for (my $i = 0; $i < @column_lists; $i++)
  {
    my @columns = split(/\,/, $column_lists[$i]);

    for (my $j = @columns - 1; $j >= 0; $j--)
    {
      my $column = $columns[$j];

      if (length($row[$columns[0]]) > 0 and length($row[$column]) > 0)
      {
	$row[$column] = &format_number($row[$column] - $row[$columns[0]], $precision);
      }
    }
  }

  for (my $i = 0; $i < @row; $i++)
  {
    if ($i > 0) { print "\t"; }

    print "$row[$i]";
  }

  print "\n";
}

__DATA__

zero_transform.pl <source file>

   Zero transform columns in <source file> that are given in a list

   -zero <list>:     List should have the form "1,17,18 2,3" for subtracting column 1 from 17 and 18 and 2 from 3
   -skip <num>:      Skip num rows in the source file and just print them (default: 0)
   -precision <num>: Precision of the numbers printed (default: 3 digits)

