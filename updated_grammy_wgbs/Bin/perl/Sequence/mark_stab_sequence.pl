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

my $mark_characters = get_arg("c", "", \%args);
my $output_prefix = get_arg("prefix", "<b><font color=\"red\">", \%args);
my $output_suffix = get_arg("suffix", "</b></font>", \%args);

my %mark_characters_hash;
if (length($mark_characters) > 0)
{
    my @row = split(/\,/, $mark_characters);
    foreach my $char (@row) { $mark_characters_hash{$char} = "1"; }
}

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);
  my $sequence = $row[1];

  print "$row[0]\t";
  
  if (length($mark_characters) > 0)
  {
      for (my $i = 0; $i < length($sequence); $i++)
      {
	  my $char = substr($sequence, $i, 1);

	  if ($mark_characters_hash{$char} eq "1")
	  {
	      print $output_prefix . "\U$char" . $output_suffix;
	  }
	  else
	  {
	      print "\L$char";
	  }
      }
  }

  print "\n";
}

__DATA__

mark_stab_sequence.pl <file>

   Takes in a stab sequence file and marks certain positions on it

   -c <str>:      List of characters, separated by commas that will be marked (e.g., R,K)

   -prefix <str>: Prefix to put before the marked sequence (default: <b><font color=\"red\">)
   -suffix <str>: Prefix to put after the marked sequence (default: </b></font>)

