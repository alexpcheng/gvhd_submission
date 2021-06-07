#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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
my $min_length = get_arg("min_l", "", \%args);
my $max_length = get_arg("max_l", "", \%args);
my $exact_length = get_arg("exact_l", 0, \%args);
my $append_length = get_arg("l", "", \%args);
my $append_length_column = get_arg("lc", "", \%args);
my $append_to_start = get_arg("s", 0, \%args);
my $append_to_both = get_arg("b", 0, \%args);
my $zero_bound = get_arg("zero_bound", 0, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/, $_,-1);

  my $left = $row[2] < $row[3] ? $row[2] : $row[3];
  my $right = $row[2] < $row[3] ? $row[3] : $row[2];
  my $length = $right - $left + 1;

##  my $length_to_add = length($append_length_column) > 0 ? $row[$append_length_column] : (length($append_length) > 0 ? $append_length : $min_length - $length);
  my $length_to_add = length($append_length_column) > 0 ? $row[$append_length_column] : (length($append_length) > 0 ? $append_length : 0);
  if (length($min_length) > 0)
  {
     if ($append_to_both == 1)
     {
	$length_to_add = ($min_length < $length) ? 0 : ceil(($min_length - $length)/2);
     }
     else
     {
	$length_to_add = ($min_length < $length) ? 0 : ($min_length - $length);
     }
  }
  if (length($max_length) > 0)
  {
     if ($append_to_both == 1)
     {
	$length_to_add = ($max_length > $length) ? 0 : ceil(($max_length-$length)/2);
     }
     else
     {
	$length_to_add = ($max_length > $length) ? 0 : ($max_length-$length);
     }
  }
  if (($length_to_add != 0) or ($exact_length > 0))
  {
    print "$row[0]\t$row[1]\t";

    if ($row[2] <= $row[3])
    {
      if ($append_to_both == 1)
      {
	if ($exact_length > 0)
	{
	  my $new_start = floor(($row[2] + $row[3]) / 2) - floor($exact_length / 2);

	  print ( ($new_start > 0 || $zero_bound == 0) ? $new_start : 1);
	  print "\t";
	  print ($new_start + $exact_length - 1);
	}
	else
	{
	  print ((($row[2] - $length_to_add > 0  || ($zero_bound == 0)) ? $row[2] - $length_to_add : 1));
	  print "\t";
	  print ($row[3] + $length_to_add);
	}
      }
      elsif ($append_to_start == 1)
      {
	if ($exact_length > 0)
	{	
	  print ((($row[3] - $exact_length + 1 > 0  || ($zero_bound == 0)) ? $row[3] - $exact_length + 1 : 1));
	  print "\t$row[3]";
	}
	else
	{
	  print ((($row[2] - $length_to_add > 0  || ($zero_bound == 0)) ? $row[2] - $length_to_add : 1));
	  print "\t$row[3]";
	}
      }
      else
      {
	if ($exact_length > 0)
	{
	  print "$row[2]\t";
	  print ($row[2] + $exact_length - 1);
	}
	else
	{
	  print "$row[2]\t";
	  print ($row[3] + $length_to_add);
	}
      }
    }
    else
    {
      if ($append_to_both == 1)
      {
	if ($exact_length > 0)
	{
	  my $new_start = floor(($row[2] + $row[3]) / 2) + floor($exact_length / 2);
	  print ( $new_start );
	  print "\t";
	  print (($new_start - $exact_length + 1 > 0 || $zero_bound == 0) ? $new_start - $exact_length + 1 : 1);
	}
	else
	{
	  print ($row[2] + $length_to_add);
	  print "\t";
	  print ((($row[3] - $length_to_add > 0  || ($zero_bound == 0)) ? $row[3] - $length_to_add : 1));
	}
      }
      elsif ($append_to_start == 1)
      {
	if ($exact_length > 0)
	{	
	  print ($row[3] + $exact_length - 1);
	  print "\t$row[3]";
	}
	else
	{
	  print ($row[2] + $length_to_add);
	  print "\t$row[3]";
	}
      }
      else
      {
	if ($exact_length > 0)
	{	
	  print "$row[2]\t";
	  print ((($row[2] - $exact_length + 1 > 0  || ($zero_bound == 0)) ? $row[2] - $exact_length + 1 : 1));
	}
	else
	{
	  print "$row[2]\t";
	  print ((($row[3] - $length_to_add > 0  || ($zero_bound == 0)) ? $row[3] - $length_to_add : 1));
	}
      }
    }

    for my $i (4..$#row)
    {
      print "\t$row[$i]";
    }

    print "\n";
  }
  else
  {
    print "$_\n";
  }
}

__DATA__

chr_append_flanking_regions.pl <file>

   Appends flanking regions to each location

   -min_l <num>:   Append flanking region such that the MINIMUM length is <num>
   -max_l <num>:   Append flanking region such that the MAXIMUM length is <num>
   -exact_l <num>: Append flanking region such that the length is EXACTLY <num>
   -l <num>:       Append <num> bp
   -lc <num>:      Append the number of bp specified in column <num>

   -s:             Append to the start of the location (default: append to the end)
   -b:             Append to both the start and the end of the location
   -zero_bound:    Make sure that modified coodinates remain positive (default: coords can be negative).

