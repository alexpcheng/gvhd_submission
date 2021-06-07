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

#my $word_length = get_arg("n", 5, \%args);

my $first = 1;
while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);
  my $sequence = $row[1];

  if ($first == 1)
  {
      $first = 0;
      print "Pos";
      for (my $i = 0; $i < length($sequence); $i++) { print "\t" . ($i + 1); }
      print "\n";
  }

  print "$row[0]";
  for (my $i = 0; $i < length($sequence); $i++)
  {
    print "\t" . substr($sequence, $i, 1);
  }
  print "\n";
}

__DATA__

stab2tab.pl <file>

   Takes in a stab sequence file and converts it such that each residue is in its own column

