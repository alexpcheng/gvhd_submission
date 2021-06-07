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

my $column_list = get_arg("avg", "", \%args);
my $skip_num = get_arg("skip", 0, \%args);
my $precision = get_arg("precision", 3, \%args);

my @column_lists = split(/\s/, $column_list);

my %excluded_columns;
for (my $i = 0; $i < @column_lists; $i++)
{
  my @columns = split(/\,/, $column_lists[$i]);

  for (my $j = 1; $j < @columns; $j++) { $excluded_columns{$columns[$j]} = "1"; }
}

for (my $i = 0; $i < $skip_num; $i++)
{
  my $line = <$file_ref>;

  chop $line;

  my @row = split(/\t/, $line);

  my $first = 1;
  for (my $i = 0; $i < @row; $i++)
  {
    if ($excluded_columns{$i} ne "1")
    {
	if ($first == 0) { print "\t"; }
	else { $first = 0; }
	
	print "$row[$i]";
    }
  }

  print "\n";
}

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my @average_data;
  my @average_counts;

  for (my $i = 0; $i < @row; $i++)
  {
    $average_data[$i] = $row[$i];

    if (length($row[$i]) > 0) { $average_counts[$i] = 1; }
    else { $average_counts[$i] = 0; }
  }

  for (my $i = 0; $i < @column_lists; $i++)
  {
    my @columns = split(/\,/, $column_lists[$i]);

    for (my $j = 1; $j < @columns; $j++)
    {
      my $column = $columns[$j];

      if ($average_counts[$column] > 0)
      {
	$average_data[$columns[0]] += $row[$column];
	$average_counts[$columns[0]]++;
      }
    }
  }

  for (my $i = 0; $i < @average_data; $i++)
  {
    if ($average_counts[$i] > 1)
    {
      $average_data[$i] = format_number($average_data[$i] / $average_counts[$i], $precision);
    }
  }

  my $first = 1;
  for (my $i = 0; $i < @row; $i++)
  {
      if ($excluded_columns{$i} ne "1")
      {
	  if ($first == 0) { print "\t"; }
	  else { $first = 0; }
	  
	  print "$average_data[$i]";
      }
  }

  print "\n";
}

__DATA__

average_columns.pl <source file>

   Average columns in <source file> that are given in a list

   -avg <list>:      List should have the form "1,17 2,3" for averaging columns 1 and 17 and also 2 and 3
   -skip <num>:      Skip num rows in the source file and just print them (default: 0)
   -precision <num>: Precision of the numbers printed (default: 3 digits)

