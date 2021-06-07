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

my $split_col = get_arg("c", 0, \%args);
my $n_skip    = get_arg("skip", 0, \%args);
my $delim     = get_arg("d", ' ', \%args);

my $counter = -1;

while(<$file_ref>)
{
   chop;

   $counter++;

   if ($counter < $n_skip)
   {
      print "$_\n";
   }
   else
   {
      my @row = split (/\t/);
      
      if ($split_col > $#row)
      {
	 print STDERR "Error: There are only $#row columns in the file, selected column number $split_col.\n";
      }
      
      my @vals = split (/$delim/, $row[$split_col]);
      
      foreach my $val (@vals)
      {
	 for (my $i = 0; $i <= $#row; $i++)
	 {
	    if ($i == $split_col)
	    {
	       print $val;
	    }
	    else
	    {
	       print $row[$i];
	    }
	    if ($i < $#row)
	    {
	       print "\t";
	    }
	 }
	 print "\n";
      }
   }
}

__DATA__

flatten_ids_col.pl <source file>

   Split a selected coloumn by a given delimiter to seperate lines each contains the rest of the original line.

   -c <n>:    Column to split (default: 0, the first column).
   -skip <n>: Print the first <n> lines in the file as they are (default: 0).
   -d <chr>:  The delimiter to split the column by (default: space).
   
