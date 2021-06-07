#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $selection_file = get_arg("f", 0, \%args);
my $keep = get_arg("keep", 0, \%args);

my %selection;
open(SELECT, "<$selection_file");
while(<SELECT>)
{
  chop;

  my @row = split(/\t/);

  $selection{$row[0]} = "1";
}

my @keep_columns;
$keep_columns[0] = 1;
open(FILE, "<$file") or die "couldn't open $file\n";
my $line = <FILE>;
chop $line;
my @row = split(/\t/, $line);
my $column_counter = 0;
for (my $i = 0; $i < @row; $i++)
{
  if ($selection{$row[$i]} eq "1")
  {
    $keep_columns[$i] = 1;
  }

  if ($i == 0 or ($keep_columns[$i] == 1 and $keep == 1) or ($keep_columns[$i] == 0 and $keep == 0))
  {
      if ($column_counter > 0) { print "\t"; }

      print "$row[$i]";

      $column_counter++;
  }
}
print "\n";

while (<FILE>)
{
  chop;

  my @row = split(/\t/);

  my $column_counter = 0;
  for (my $i = 0; $i < @row; $i++)
  {
    if ($i == 0 or ($keep_columns[$i] == 1 and $keep == 1) or ($keep_columns[$i] == 0 and $keep == 0))
    {
	if ($column_counter > 0) { print "\t"; }
	
	print "$row[$i]";

	$column_counter++;
    }
  }
  print "\n";
}

__DATA__

remove_columns.pl <file>

   Remove columns from a file by the name of the column (from header)

   -f:           file containing keys of columns to remove
   -keep:        If specified, then will keep the columns specified

