#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";

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

my $split_columns_str = get_arg("c", "", \%args);
my @split_columns = split(/\,/, $split_columns_str);

while (<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $column_index = 0;
  for (my $i = 0; $i < @split_columns; $i++)
  {
    my $first = 1;
    for (; $column_index <= $split_columns[$i]; $column_index++)
    {
      if ($first == 1)
      {
	$first = 0;
      }
      else
      {
	print "\t";
      }
      print "$row[$column_index]";
    }
    print "\n";
  }

  my $first = 1;
  for (; $column_index <= @row; $column_index++)
  {
    if ($first == 1)
    {
      $first = 0;
    }
    else
    {
      print "\t";
    }
    print "$row[$column_index]";
  }
  if ($first == 0)
  {
    print "\n";
  }
}

__DATA__

split_lines.pl <file>

   Splits each line of a file into several lines

   -c <str>: Columns after which to split (example: 1,3 will split a line into three lines: columns 1+2, 3+4, 5-)

