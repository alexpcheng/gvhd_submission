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

my $combine_files_str = get_arg("f", "", \%args);
my @combine_files = split(/\,/, $combine_files_str);

print "<WeightMatrices>\n";

foreach my $combine_file (@combine_files)
{
  $combine_file =~ s/ //g;
  $combine_file =~ s/[\n]//g;
  $combine_file =~ s/[\t]//g;

  open(COMBINE_FILE, "<$combine_file") or die "Could not find gxw to combine with: [$combine_file]\n";
  while(<COMBINE_FILE>)
  {
    chop;

    if (/<WeightMatrix[\s]/ or /<Position Weights=[\"]/ or /<[\/]WeightMatrix>/)
    {
      print "$_\n";
    }
  }
}

print "</WeightMatrices>\n";

__DATA__

gxw_combine.pl

   Combines gxw files

   -f <str>: gxw files to combine with (comma separated)

