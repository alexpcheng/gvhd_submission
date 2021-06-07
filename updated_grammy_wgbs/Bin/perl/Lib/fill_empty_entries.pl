#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

my $fill_string = get_arg("s", "", \%args);
my $min_num_columns = get_arg("c", 0, \%args);
my $max = get_arg("max", -1, \%args);

my @lines;
while(<$file_ref>)
{
  chop;

  push(@lines, $_);

  my @row = split(/\t/);
  my $num = @row;

  if ($num > $min_num_columns)
  {
    $min_num_columns = $num;
  }
}

for (my $i = 0; $i < @lines; $i++)
{
  my @row = split(/\t/, $lines[$i]);

  my $first = 1;

  for (my $i = 0; $i < @row; $i++)
  {
    if ($first == 0) { print "\t"; }
    else { $first = 0; }

    if (length($row[$i]) == 0) { print "$fill_string"; }
    else { print "$row[$i]"; }
  }

  for (my $i = @row; $i < $min_num_columns; $i++)
  {
    if ($first == 0) { print "\t"; }
    else { $first = 0; }

    print "$fill_string";
  }

  print "\n";
}

__DATA__

fill_empty_entries.pl <source file>

   Fill empty entries with a specified string

   -s <str>: String with which to fill the missing entries
   -c <num>: If specified, then always make sure we have <num> entries in each row
   -max    : If specified, then always make sure we have columns equal to the max in all rows

