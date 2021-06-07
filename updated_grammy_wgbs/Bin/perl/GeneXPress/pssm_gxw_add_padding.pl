#!/usr/bin/perl

use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

# require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $left_padding = get_arg("left_padding", "0", \%args);
my $right_padding = get_arg("right_padding", "0", \%args);

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



while(<$file_ref>)
{

  my $line = $_;

 if ( $line =~ /<WeightMatrix/ ) 
   {
     $line =~ s/LeftPaddingPositions=\".*\"//;
     $line =~ s/RightPaddingPositions=\".*\"//;
     $line =~ s/>/ LeftPaddingPositions=\"$left_padding\" RightPaddingPositions=\"$right_padding\" >/;

   }

    print $line;



}

__DATA__

pssm_gxw_add_padding.pl <pssm gxm file>

  Outputs a gxw with added (or replaced) padding

  -left_padding
  -right_padding

