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

my $organism = get_arg("os", "", \%args);
my $factor = get_arg("bf", "", \%args);
my $print_method = get_arg("pm", 0, \%args);

my $org = "";
my $tf = "";
my $seq = "";
my $method = "";
my $count_sites = 0;

while(<$file_ref>)
{
  chop;

  if (/^[\/][\/]/)
  {
      if ($count_sites > 0)
      {
	  if ((($organism ne "") && ($org =~ m/$organism/)) || ($organism eq ""))
	  {
	      if ((($factor ne "") && ($tf =~ m/$factor/)) || ($factor eq ""))
	      {
		  my $string = ">".$count_sites." ".$tf."  ".$org;
		  if ($print_method)
		  {
		      $string = $string."  ".$method;
		  }
		  print "$string\n";
		  print "$seq\n";
	      }
	      
	  }
      }
      $count_sites++;
      $org = "";
      $tf = "";
      $seq = "";
      $method = "";
  }
  if (/^OS/)
  {
      /^OS +(.*)/;
      $org = $1;
  }
  if (/^BF/)
  {
      /^BF +(.*)/;
      $tf = $1; 
  }
  if (/^SQ/)
  {
      /^SQ +([a-zA-Z]*)/;
      $seq = $1; 
  }
  if (/^MM/)
  {
      /^MM +(.*)/;
      if ($method eq "")
      {
	  $method = $1; 
      }
      else
      {
	  $method = $method." ".$1;
      }
  }
}


__DATA__

parse_transfac_sites.pl <file>

   Parses a transfac site.dat file

   -os <str>: Extract only this species (default: extract all)
   -bf <str>: Extract only this factor (default: extract all)
   -pm <bool> : Print method (default: false)



