#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $DEBUG = 0; ##use 1 for a debuging mode, in which the TMP_$r directory is not removed at the end.

#---------------------------------------------------------------------#
# LOAD ARGUMENTS                                                      #
#---------------------------------------------------------------------#
my %args = load_args(\@ARGV);

#--------------------------#
# File                     #
#--------------------------#
my $file = $ARGV[0];
my $num_of_columns = 0;
if (length($file) < 1 or $file =~ /^-/) 
{
  die("This procedure does not work with pipeline. The file must be given as an argument.\n");
}
else
{
  open(FILE, $file) or die("Could not open the file '$file'.\n");
  my $file_ref = \*FILE; 
  my $first_line = <$file_ref>;
  chomp($first_line);
  my @row = split(/\t/,$first_line);
  $num_of_columns = @row;
  print STDERR "Num of columns: $num_of_columns\n";
  close(FILE);
}

my $r = int(rand(1000000));
my $str0 = `mkdir TMP_$r; echo -n > TMP_$r/raw_sorted_all_rows; echo -n > TMP_$r/quantile_normalized_rows`;

print STDERR "Sort columns to quantiles...";

for (my $c = 1; $c <= $num_of_columns; $c++)
{
   #my $str1 = `cat $file | cut.pl -f $c | lin.pl | sort.pl -c0 1 -n0 > TMP_$r/raw_sorted_column_$c`;
   my $str1 = `cat $file | cut.pl -f $c | lin.pl | sort -k2 -g > TMP_$r/raw_sorted_column_$c`;
   my $str2 = `cat TMP_$r/raw_sorted_column_$c | cut.pl -f 2 | transpose.pl -q >> TMP_$r/raw_sorted_all_rows`;
}

print STDERR "done sorting.\nAverage quantiles...";

my $str3 = `cat TMP_$r/raw_sorted_all_rows | compute_column_stats.pl -skip 0 -skipc 0 -m | cut.pl -f 2- | transpose.pl -q > TMP_$r/ave_quantile_column`;

print STDERR "done averaging.\nSort back columns...";

for (my $c = 1; $c <= $num_of_columns; $c++)
{
   #my $str4 = `paste TMP_$r/raw_sorted_column_$c TMP_$r/ave_quantile_column | sort.pl -c0 0 -n0 | cut.pl -f 3 | transpose.pl -q >> TMP_$r/quantile_normalized_rows`;
   my $str4 = `paste TMP_$r/raw_sorted_column_$c TMP_$r/ave_quantile_column | sort -k1 -g | cut.pl -f 3 | transpose.pl -q >> TMP_$r/quantile_normalized_rows`;
}

my $str5 = `cat TMP_$r/quantile_normalized_rows | transpose.pl -q > TMP_$r/output`;
print STDERR "done sorting.\nPrint output...";

my $output_file_ref;
open(OUTPUT_FILE, "TMP_$r/output") or die("Error: could not open the output file 'TMP_$r/output'.\n");
$output_file_ref = \*OUTPUT_FILE;

while(my $row = <$output_file_ref>)
{
  chomp($row);
  print STDOUT "$row\n";
}

close(OUTPUT_FILE);

print STDERR "done.\n";

if ($DEBUG == 0)
{
  my $str_final = `rm -rf TMP_$r`;
}

#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         quantile_normalization.pl <file>
 
 Description:    Given a tab delimited file, calculates and outputs the quantile normalization of the columns.
                 Notice: does not work with pipeline, the file must be given as an argument.
