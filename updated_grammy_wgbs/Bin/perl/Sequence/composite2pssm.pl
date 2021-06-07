#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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
my $alphabet_str = get_arg("op", 0, \%args);

my $pssm_matrix_name = "";
my $composite_matrix_name = "";
my %matrices2positionstr;

while(<$file_ref>)
{
  chomp;

  if (/^<WeightMatrices/ or /<[\/]WeightMatrices/)
  {
    print "$_\n";
  }
  elsif (/Type=[\"]PositionSpecific[\"]/ and /<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
    $pssm_matrix_name = $1;
  }
  elsif (/Type=[\"]Composite[\"]/ and /<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
    $composite_matrix_name = $1;

    s/Composite/PositionSpecific/;

    print "$_\n";
  }
  elsif (length($pssm_matrix_name) > 0 and /<Position.*Weights=[\"]([^\"]+)[\"]/)
  {
    $matrices2positionstr{$pssm_matrix_name} .= "$_\n";
  }
  elsif (length($composite_matrix_name) > 0 and /<SubMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
    print $matrices2positionstr{$1};
  }
  elsif (length($pssm_matrix_name) > 0 and /<[\/]WeightMatrix/)
  {
    #print STDERR "Collected $pssm_matrix_name\n";
    #print STDERR "$matrices2positionstr{$pssm_matrix_name}\n";

    $pssm_matrix_name = "";
  }
  elsif (length($composite_matrix_name) > 0 and /<[\/]WeightMatrix/)
  {
    print "$_\n";

    $composite_matrix_name = "";
  }
}

__DATA__

composite2pssm.pl <gxm file>

   Converts composite matrices to position specific matrices

   -op:   Output the position specific matrices as well

