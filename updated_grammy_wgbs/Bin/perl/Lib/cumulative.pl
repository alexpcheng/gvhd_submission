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

my $x_column = get_arg("x", 0, \%args);
my $y_column = get_arg("y", 1, \%args);
my $reverse = get_arg("r", 0, \%args);
my $no_sort = get_arg("s", 0, \%args);

my @values;


while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  push(@values, "$row[$x_column]\t$row[$y_column]");
}

if (!$no_sort) {
    if ($reverse == 0)
    {
        @values = sort { my @aa=split(/\t/,$a); my @bb=split(/\t/,$b); $aa[0] <=> $bb[0]; } @values;
    }
    else
    {
        @values = sort { my @aa=split(/\t/,$a); my @bb=split(/\t/,$b); $bb[0] <=> $aa[0]; } @values;
    }
}

my $cumulative = 0;
for (my $i = 0; $i < @values; $i++)
{
    my @row = split(/\t/, $values[$i]);
    print "$row[0]\t";
    print $row[1] + $cumulative;
    print "\n";
    $cumulative += $row[1];
}

__DATA__

cumulative.pl <file>

   Produce a cumulative count out of numbers in a column

   -x <num>:     x-axis column (default: 0)
   -y <num>:     y-axis column (default: 1)

   -r:           Accumulate numbers towards smaller x (default: towards large x)

   -s:           Don't sort the column. (default: sort it towards large x)

