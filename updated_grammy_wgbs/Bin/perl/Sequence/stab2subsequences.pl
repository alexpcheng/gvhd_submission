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

my $substring_length = get_arg("l", 500, \%args);
my $substring_overlap = get_arg("o", 50, \%args);
my $string_start = get_arg("s", 0, \%args);
my $string_end = get_arg("e", -1, \%args);
my $no_start_print = get_arg("no_start", 0, \%args);
my $no_end_print = get_arg("no_end", 0, \%args);
my $continue_until_end = get_arg("c", 0, \%args);

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    my $sequence_length = length($row[1]);
    #print STDERR "$row[0] $sequence_length\t$row[1]\n";

    my $sequence_end = ($string_end == -1) ? ($sequence_length - $substring_length + 1) : ($string_end - $substring_length + 1);
    if ($sequence_end > $sequence_length - $substring_length + 1)
    {
    	$sequence_end = $sequence_length - $substring_length + 1;
    }

    if ($continue_until_end)
    {
      $sequence_end = ($string_end == -1) ? ($sequence_length - $substring_overlap) : ($string_end - $substring_overlap);
    	if ($sequence_end > $sequence_length - $substring_overlap)
    	{
    		$sequence_end = $sequence_length - $substring_overlap;
    	}
    }

    for (my $i = $string_start; $i < $sequence_end; $i += $substring_overlap)
    {
	print "$row[0]";
	if ($no_start_print == 0)
	{
	  print " $i";
	}
	if ($no_end_print == 0)
	{
	  print " ";
	  print ($i + $substring_length);
	}
	print "\t";

	print substr($row[1], $i, $substring_length);
	print "\n";
    }

    if ($sequence_length < $substring_length)
    {
	print "$row[0] 0 $sequence_length\t$row[1]\n";
    }
    elsif ($sequence_length % $substring_overlap > 0 and $sequence_end == -1)
    {
	print "$row[0] ";
	print ($sequence_length - $substring_length);
	if ($no_end_print == 0)
	{
	  print " ";
	  print ($sequence_length - $substring_length + $substring_length);
	}
	print "\t";

	print substr($row[1], $sequence_length - $substring_length, $substring_length);
	print "\n";
    }
}

__DATA__

stab2subsequences.pl <file>

   Extracts subsequences from a stab file

   -l <num>:   The length of the substrings to extract (default: 500)
   -o <num>:   The overlap between the substrings (default: 50)

   -s <num>:   The position in the sequence at which to start extracting subsequences (default: 0)
   -e <num>:   The position in the sequence at which to end extracting subsequences (default: sequence end)

   -no_start:  Do not print the location of the start of each subsequence
   -no_end:    Do not print the location of the end of each subsequence

   -c:         Continue partitioning until end of sequence. NOTE: If this is option not used,
               sequence will be partitioned until last subsequence of size -l. i.e, if sequence
               is not divisible by -l, the end will be lost.


