#!/usr/bin/perl

use strict;

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

my $line = <$file_ref>;
my $types_str;
if ($line =~ /FeatureTypes="(.*?)"/)
{
   $types_str = $1;
}
else
{
   print STDERR "Error: Could not find the FeatureTypes attribute in line:\n$line\n";
   exit 1;
}
my @types = split(/;/,$types_str);
my @row;

while(<$file_ref>)
{
  chop;

  if (/<\/GeneXPressChromosomeTrack>/)
  {
     last;
  }

  @row = split ('\t');
  
  if ($#row < 4)
  {
     print STDERR "Error: Missing fields in line: $_\n";
     exit 1;
  }

  $row[4] = $types[$row[4]];

  $line = join ("\t", @row);

  print "$line\n";
}


__DATA__

gxt2chr.pl <file> 

    Converts a gxt file to a chr file.

