#!/usr/bin/perl

##############################################################################
##############################################################################
##
## aggregate.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "$ENV{PERL_HOME}/Lib/libfile.pl";

use strict;
use warnings;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim   = $args{'-d'};
my $file    = $args{'--file'};

my ($ids, $rows) = &readIds($file, $col, $delim);

my $max_cols = 0;

my $data = &readDataMatrix($file, $col, $delim, \$max_cols);

for(my $i = 0; $i < scalar(@{$rows}); $i++)
{
   my $id = $$ids[$i];

   my @sum;

   my @num;

   for(my $j = 1; $j < $max_cols; $j++)
   {
      $sum[$j-1] = 0;

      $num[$j-1] = 0;
   }

   my @r = @{$$rows[$i]};

   for(my $k = 0; $k < scalar(@{$$rows[$i]}); $k++)
   {
      my $row = $$rows[$i][$k];

      for(my $j = 1; $j < $max_cols; $j++)
      {
         if(defined($$data[$row][$j]))
         {
            if($$data[$row][$j] =~ /^\s*[\d+\.eE-]+\s*$/)
            {
               $num[$j-1] += 1;

               $sum[$j-1] += $$data[$row][$j];
            }
         }
      }
   }

   my @ave;

   for(my $j = 1; $j < $max_cols; $j++)
   {
      $ave[$j-1] = ($num[$j-1] > 0) ? sprintf("%.5f", ($sum[$j-1] / $num[$j-1])) : "";
   }

   print STDOUT $id, (($max_cols > 0) ? ($delim . join($delim, @ave)) : ""), "\n";
}

exit(0);


__DATA__
syntax: aggregate.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



