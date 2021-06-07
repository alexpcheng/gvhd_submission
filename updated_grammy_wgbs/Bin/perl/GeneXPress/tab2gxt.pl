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

my $name = get_arg("n", "Gene names", \%args);

print "<GeneXPressChromosomeTrack Type=\"ChromosomeExpressionTrack\" Name=\"$name\">\n";

while(<$file_ref>)
{
  chop;

  print "$_\n";
}

print "</GeneXPressChromosomeTrack>\n";

__DATA__

tab2gxt.pl <file> 

    Creates a gxt file from a tab file

    -n <name>:  Name of the chromosome track (default: Gene names)

