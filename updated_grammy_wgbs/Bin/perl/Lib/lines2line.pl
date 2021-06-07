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

my $delimiter = get_arg("d", "\t", \%args);

my $first = 1;
while(<$file_ref>)
{
  chop;
  
  if ($first == 0) { print "$delimiter"; }
  else { $first = 0; }

  print "$_";
}
print "\n";

__DATA__

lines2line.pl <gxm file>

   Concatenates several input lines into one line, where
   the concatenation is by a specific delimiter

   -d <str>: delimiter between concatenation of successive lines (default: "\t")

