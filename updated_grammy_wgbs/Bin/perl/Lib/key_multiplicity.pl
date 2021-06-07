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

my $multiplicity_column_str = get_arg("k", "1", \%args);
my @multiplicity_columns = split(/\,/, $multiplicity_column_str);

my $r = int(rand(10000000));
open(OUTFILE, ">tmp$r");

my %keys2multiplicity;

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $key = "";
  for (my $i = 0; $i < @multiplicity_columns; $i++)
  {
    my $column = $multiplicity_columns[$i] - 1;
    $key .= "$row[$column]\t";
  }

  $keys2multiplicity{$key}++;

  print OUTFILE "$_\n";
}
close(OUTFILE);

open(INFILE, "<tmp$r");
while(<INFILE>)
{
  chop;

  my @row = split(/\t/);

  my $key = "";
  for (my $i = 0; $i < @multiplicity_columns; $i++)
  {
    my $column = $multiplicity_columns[$i] - 1;
    $key .= "$row[$column]\t";
  }

  print "$keys2multiplicity{$key}\t$_\n";
}
close(INFILE);

system("rm -f tmp$r");

__DATA__

key_multiplicity.pl <file>

   Adds the multiplicity of a key defined by several columns

   -k <n1,n2,..>: Key column to count multiplicity for (default: 1)

   NOTE: 1-based!

