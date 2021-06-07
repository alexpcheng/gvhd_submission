#!/usr/bin/perl

use strict;

# *********************************************************************************************************************************
#
#                                                          L I N R E G
#
#  Program:      LINREG
#
#  Programmer:   Dr. David G. Simpson
#                Department of Physical Science
#                Prince George's Community College
#                Largo, Maryland  20774
#
#  Date:         February 16, 2002
#
#  Language:     Perl
#
#  Description:  This program performs a linear regression analysis for a set of data given as (x,y) pairs.  The output from
#                the program is the slope and y-intercept of the least-squares best fit straight line through the data points.
#
# *********************************************************************************************************************************

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

# ---------------------------------------------------------------------------------------------------------------------------------
#   sqr()  -  Return the square of a number.
# ---------------------------------------------------------------------------------------------------------------------------------
sub sqr {
$_[0] * $_[0];
}

# ---------------------------------------------------------------------------------------------------------------------------------
#   Read in x and y data and accumulate sums.
# ---------------------------------------------------------------------------------------------------------------------------------
my $line;
my $n = 0;
my $sumx = 0;
my $sumx2 = 0;
my $sumxy = 0;
my $sumy = 0;
my $sumy2 = 0;

while(<$file_ref>)
{
   chomp;                      

   my @row = split(/\t/);

   $n++;                       
   $sumx  += $row[0];          
   $sumx2 += $row[0] * $row[0];
   $sumxy += $row[0] * $row[1];
   $sumy  += $row[1];          
   $sumy2 += $row[1] * $row[1];
}


# ---------------------------------------------------------------------------------------------------------------------------------
#   Compute and print results.
# ---------------------------------------------------------------------------------------------------------------------------------

my $m = &format_number(($n * $sumxy  -  $sumx * $sumy) / ($n * $sumx2 - sqr($sumx)), 3);
my $b = &format_number(($sumy * $sumx2  -  $sumx * $sumxy) / ($n * $sumx2  -  sqr($sumx)), 3);
my $r = &format_number(($sumxy - $sumx * $sumy / $n) /  sqrt(($sumx2 - sqr($sumx)/$n) * ($sumy2 - sqr($sumy)/$n)), 3);

print "Slope\tY-intercept\tCorrelation\n";
print "$m\t$b\t$r\n";

__DATA__

linear_regression_pair.pl: Perform linear regression for a set of datapoints given as (x,y) pairs
    
