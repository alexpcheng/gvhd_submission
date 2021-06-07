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

#my $length = get_arg("l", -1, \%args);

my $r = int(rand(100000));
open(OUTFILE, ">tmp_$r");

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    if ($row[0] eq "AdjacentMatricesCount")
    {
	print OUTFILE "$row[4] - $row[5] - $row[0]\t$row[1]\t$row[7]\n";
    }
    elsif ($row[0] eq "AllMatricesCount")
    {
	print OUTFILE "$row[0]\t$row[1]\t$row[5]\n";
    }
    elsif ($row[0] eq "MatricesCoverage")
    {
	print OUTFILE "$row[0]\t$row[1]\t$row[5]\n";
    }
    elsif ($row[0] eq "SingleMatricesCount")
    {
	print OUTFILE "$row[4] - $row[0]\t$row[1]\t$row[6]\n";
    }
}

close(OUTFILE);

system("list2tab.pl tmp_$r -V 2;");
system("rm tmp_$r");

__DATA__

sequence_features2tab.pl <file>

   Given output of a sequence configuration features file,
   outputs a tab-delimited file for all the feature values

