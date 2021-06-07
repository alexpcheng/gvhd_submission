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

my $prev_location = "";
my $current_location = "";
my $next_location = "";
while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    $next_location = $_;

    if (length($current_location) > 0)
    {
      &PrintBoundaries();
    }

    $prev_location = $current_location;
    $current_location = $next_location;
}

&PrintBoundaries();

#------------------------------------------------------------------------
#
#------------------------------------------------------------------------
sub PrintBoundaries
{
  my @prev_row = split(/\t/, $prev_location);
  my @current_row = split(/\t/, $current_location, 5);
  my @next_row = split(/\t/, $next_location);
  
  my $current_start = $current_row[2] < $current_row[3] ? $current_row[2] : $current_row[3];
  my $current_end = $current_row[2] > $current_row[3] ? $current_row[2] : $current_row[3];
  
  my $prev_end = ($current_row[0] eq $prev_row[0]) ? ($prev_row[2] > $prev_row[3] ? ($prev_row[2] + 1) : ($prev_row[3] + 1)) : 0;
  my $next_start = ($current_row[0] eq $next_row[0]) ? ($next_row[2] < $next_row[3] ? ($next_row[2] - 1) : ($next_row[3] - 1)) : $current_end;

  if ($prev_end > $current_start)
  {
    $prev_end = $current_start;
  }
  if ($next_start < $current_end)
  {
    $next_start = $current_end;
  }
  
  if ($current_row[2] < $current_row[3])
  {
    print "$current_row[0]\t$current_row[1]\t$prev_end\t$next_start\t$current_row[4]\n";
  }
  else
  {
    print "$current_row[0]\t$current_row[1]\t$next_start\t$prev_end\t$current_row[4]\n";
  }
}

__DATA__

find_chr_boundaries.pl <file>

   Prints the boundaries of each location to the previous and next locations

   NOTE: Assumes that the file has been sorted by chromosome and then start

