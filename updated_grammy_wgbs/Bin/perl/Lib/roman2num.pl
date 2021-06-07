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

my $column_to_convert = get_arg("c", "A", \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  for (my $i = 0; $i < @row; $i++)
  {
    if ($i > 0) { print "\t"; }

    if ($column_to_convert eq "A" or $column_to_convert == $i)
    {
      $row[$i] = "\U$row[$i]";

      if ($row[$i] eq "I") { $row[$i] = 1; }
      elsif ($row[$i] eq "II") { $row[$i] = 2; }
      elsif ($row[$i] eq "III") { $row[$i] = 3; }
      elsif ($row[$i] eq "IV") { $row[$i] = 4; }
      elsif ($row[$i] eq "V") { $row[$i] = 5; }
      elsif ($row[$i] eq "VI") { $row[$i] = 6; }
      elsif ($row[$i] eq "VII") { $row[$i] = 7; }
      elsif ($row[$i] eq "VIII") { $row[$i] = 8; }
      elsif ($row[$i] eq "IX") { $row[$i] = 9; }
      elsif ($row[$i] eq "X") { $row[$i] = 10; }
      elsif ($row[$i] eq "XI") { $row[$i] = 11; }
      elsif ($row[$i] eq "XII") { $row[$i] = 12; }
      elsif ($row[$i] eq "XIII") { $row[$i] = 13; }
      elsif ($row[$i] eq "XIV") { $row[$i] = 14; }
      elsif ($row[$i] eq "XV") { $row[$i] = 15; }
      elsif ($row[$i] eq "XVI") { $row[$i] = 16; }
      elsif ($row[$i] eq "XVII") { $row[$i] = 17; }
      elsif ($row[$i] eq "XVIII") { $row[$i] = 18; }
      elsif ($row[$i] eq "XIX") { $row[$i] = 19; }
      elsif ($row[$i] eq "XX") { $row[$i] = 20; }
    }

    print "$row[$i]";
  }

  print "\n";
}

__DATA__

roman2num.pl <file>

   Converts Roman letters to numbers

   -c <str>: Convert only column in <str> (default: A for all columns)

