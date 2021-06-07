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

my $chr_id_in_gff_str = get_arg("id", "9", \%args);
my $chr_type_in_gff_str = get_arg("t", "3", \%args);
my $chr_value = get_arg("v", "", \%args);

my @chr_id_in_gff = split(/\,/, $chr_id_in_gff_str);
my @chr_type_in_gff = split(/\,/, $chr_type_in_gff_str);

while(<$file_ref>)
{
  chop;

  if (substr($_, 0, 1) eq "#")
  {
     next;
  }

  my @row = split(/\t/);

  print "$row[0]\t";

  for (my $i = 0; $i < @chr_id_in_gff; $i++)
  {
    if ($i > 0)
    {
      print " ";
    }

    print $row[$chr_id_in_gff[$i] - 1];
  }
  print "\t";

  if ($row[6] eq "+")
  {
    print "$row[3]\t$row[4]\t";
  }
  else
  {
    print "$row[4]\t$row[3]\t";
  }

  for (my $i = 0; $i < @chr_type_in_gff; $i++)
  {
    if ($i > 0)
    {
      print " ";
    }

    print $row[$chr_type_in_gff[$i] - 1];
  }
  print "\t";

  if (length($chr_value) > 0)
  {
    print $chr_value;
  }
  else
  {
    print $row[5];
  }
  print "\n";
}

__DATA__

gff2chr.pl <file>

   Takes in a gff file and converts it to a chr file

   chr format: <chr> <ID> <start> <end> <type> <value>
   gff format: <chr> <source> <type> <start> <end> <value> <strand> <phase> <group>

   -id <num>: Column(s) from the gff to use for the chr id column (default: 9)
              NOTE: 1-based. Specify multiple columns by comma-delimited

   -t <num>:  Column(s) from the gff to use for the chr type (default: 3)
              NOTE: 1-based. Specify multiple columns by comma-delimited

   -v <num>:  Set the value column of the chr to <num> (default: use gff column 6)

