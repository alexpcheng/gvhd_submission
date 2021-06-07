#!/usr/bin/perl

##############################################################################
##############################################################################
##
## cat.pl
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

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                 ,[    '-n', 'scalar',     1,     0]
	         ,[    '-name', 'scalar',     0,     1]
                 ,[    '-skip', 'scalar',     0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = $args{'-q'};
my $print_newline = $args{'-n'};
my $skip_lines    = $args{'-skip'};
my $name          = $args{'-name'};
my $extra         = $args{'--extra'};
my $entries       = (defined($extra) and scalar(@{$extra}) > 0) ? $extra : ['-'];

my $rows_printed  = 0;

foreach my $entry (@{$entries})
{
   if ($name)
   {
      print STDOUT "$entry:\n";
   }

   if((-f $entry) or (-l $entry) or ($entry eq '-'))
   {
      my $file = &openFile($entry);

      if ($rows_printed > 0) { for (my $i = 0; $i < $skip_lines; $i++) { my $line = <$file>; } }

      while(<$file>)
      {
         print STDOUT $_;

	 $rows_printed++;
      }
      close($file);
   }
   else
   {
      print STDOUT $entry;

      if($print_newline)
      {
         print STDOUT "\n";
      }
   }
}

exit(0);


__DATA__
syntax: cat.pl [OPTIONS] [ENTRY1 ENTRY2 ...]

Prints out files or strings.  If ENTRYi is a file it prints its output
to standard output.  Otherwise, if it is a string, it prints the string.

OPTIONS are:

-n: Don't print the newline character between each entry.

-skip <num>: Number of lines to skip (and not print) in each file *EXCEPT* the first file printed

