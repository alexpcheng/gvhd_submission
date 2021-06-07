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

my @rows;
while(<$file_ref>)
{
 	chop;
	push(@rows, $_);
}


foreach(sort mysort @rows) 
{
	print;
	print"\n";
}

sub mysort
{
	my $aa=$a; my $bb=$b;
	my @row_a = split(/\t/, $aa);
	my @row_b = split(/\t/, $bb);
	my $min_a_23 = ($row_a[2] < $row_a[3] ? $row_a[2] : $row_a[3]);
	my $min_b_23 = ($row_b[2] < $row_b[3] ? $row_b[2] : $row_b[3]);
	$row_a[0] cmp $row_b[0]	|| $row_a[1] cmp $row_b[1] || $min_a_23 <=> $min_b_23;
}

__DATA__

sort_tab.pl <file>

   Takes in a tab file and sort the rows according to: zero then 1st then minimum of 2nd and 3rd columns.

