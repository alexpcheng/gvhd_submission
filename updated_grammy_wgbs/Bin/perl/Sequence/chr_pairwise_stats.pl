#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/vector_ops.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $vector_score = get_arg("s", "pearson", \%args);
my $offset_str = get_arg("offset", "0,0,1", \%args);
my $vector_offset = get_arg("vector_offset", 0, \%args);
my $num_simulations = get_arg("sim", 0, \%args);
my $first_file = get_arg("f1", "", \%args);
my $second_file = get_arg("f2", "", \%args);
my $first_file_name = get_arg("n1", "File1", \%args);
my $second_file_name = get_arg("n2", "File2", \%args);
my $precision = get_arg("precision", 3, \%args);
my $two_sided = get_arg("two", 0, \%args);
my $quiet = get_arg("q", 0, \%args);

my $q_str = $quiet == 1 ? " -q " : "";

if ($vector_offset == 1)
{
  my $exec_str = "join.pl $first_file $second_file -1 1,3 -2 1,3 $q_str";
  $exec_str   .= "| cut -f 6,10 ";
  $exec_str   .= "| cap.pl '$first_file_name,$second_file_name' ";
  $exec_str   .= "| transpose.pl $q_str";
  $exec_str   .= "| compute_pairwise_stats.pl -all -s $vector_score -offset '\"$offset_str\"' -sim $num_simulations -precision $precision -two $two_sided $q_str";

  if ($quiet == 0) 
  { 
    print STDERR "$exec_str\n";
  }
  system($exec_str);
}
else
{
  my @offset = split(/\,/, $offset_str);
  for (my $i = $offset[0]; $i <= $offset[1]; $i += $offset[2])
  {
    my $exec_str.= "modify_column.pl $second_file -c 2,3 -a '\"$i\"' $q_str";
    $exec_str   .= "| join.pl $first_file - -1 1,3 -2 1,3 $q_str";
    $exec_str   .= "| cut -f 6,10 ";
    $exec_str   .= "| cap.pl '$first_file_name,$second_file_name' ";
    $exec_str   .= "| transpose.pl $q_str";
    $exec_str   .= "| compute_pairwise_stats.pl -all -s $vector_score -sim $num_simulations -precision $precision -two $two_sided -offset_name '\"$i\"' $q_str";

    if ($quiet == 0)
    {
       print STDERR "$exec_str\n";
    }
    system($exec_str);
  }
}

__DATA__

chr_pairwise_stats.pl

   Compute statistics between two chr files

   Note: currently works by joining the start positions of two chr files
         and computing the pairwise stats of the resulting vector

   -f1 <str>:        First file to compare. Note: if one file is huge, it should be this one
   -f2 <str>:        Second file to compare.

   -n1 <str>:        Name of first file as will appear in the printout
   -n2 <str>:        Name of second file as will appear in the printout

   -s <score>:       Score to compute between the two vectors (bdot/dot/pearson) (default: pearson)

   -offset <s,e,i>:  Offset the two vectors compared by offsetting the second by:
                     <s> entries, <s+i> entries,... <e> entries
                     For example, -offset "-10,10,1" will compute stats between the vectors at
                     offset -10 to offset +10 in increments of 1.
   -vector_offset:   Perform the offset on the joined vectors (default: offset before the join, slower!)

   -sim <num>:       Number of simulations to perform and get a p-value per computation

   -precision <num>: Precision for outputted correlations (default: 3)

   -two:             If specified, two-sided p-value is used with -sim

