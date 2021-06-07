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
my $no_center_pairs = get_arg("nc", 0, \%args);
my $member_pairs = get_arg("m", 0, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  if ($no_center_pairs != 1)
  {
    for (my $i = 1; $i < @row; $i++)
    {
      print "$row[0]\t$row[$i]\n";
    }
  }

  if ($member_pairs == 1)
  {
    my @new_row;
    for (my $i = 1; $i < @row; $i++)
    {
      push(@new_row, $row[$i]);
    }

    for (my $i = 0; $i < @new_row; $i++)
    {
      for (my $j = $i + 1; $j < @new_row; $j++)
      {
	print "$new_row[$i]\t$new_row[$j]\n";
      }
    }
  }
}


__DATA__

neighborhood2list.pl <file>

   Takes in a neighborhood file, and converts it into a list.
   The first column will be the center, and all other columns
   in that row will form one row in the list file with the center.

   -nc:      Do *NOT* create the center with the members as a list
   -m:       Create in the list pairs between the members themselves

