#!/usr/bin/perl

# Join two files that are in the same order (not sorted)
# First file has less lines.

use strict;
use warnings;

use Getopt::Long;

my $verbose  = "";

GetOptions ("v!"     => \$verbose);

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

if (($file1 eq '-') && ($file2 eq '-')) { die ("Common, both files cannot be STDIN!"); }

my $file1_ref;
my $file2_ref;

if($file1 eq '-')
{
  $file1_ref = \*STDIN;
}
else
{
  open(FILE1, $file1) or die("Could not open file '$file1'.");
  $file1_ref = \*FILE1;
}

if($file2 eq '-')
{
  $file2_ref = \*STDIN;
}
else
{
  open(FILE2, $file2) or die("Could not open file '$file2'.");
  $file2_ref = \*FILE2;
}


if($verbose)
{ 
  print STDERR "Reading keys from ", $file1 eq '-' ? "standard input" : "file $file1";
}

my $curkey = <$file1_ref>; 
chomp ($curkey);

my $reached_end = 0;

while (<$file2_ref>)
{
	chomp;
	my @currec = split("\t",$_);
	
	if ($currec[0] eq $curkey)
	{
		print join ("\t", @currec) . "\n";
		$curkey = <$file1_ref>; 
		if (!$curkey)
		{
			$reached_end = 1;
			last;
		}
		
		chomp ($curkey);
	}
}

if (!$reached_end)
{
	print STDERR "Warning: did not reach end of keys file $file1\n";
	print STDERR "Stuck when looking for $curkey\n";
}

close (FILE1);
close (FILE2);
