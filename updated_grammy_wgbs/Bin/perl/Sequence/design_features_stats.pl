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

#---------------------------------------------------------------------#
# LOAD ARGUMENTS                                                      #
#---------------------------------------------------------------------#
my %args = load_args(\@ARGV);

#--------------------------#
# Features design file     #
#--------------------------#
my $features_design_file = $ARGV[0];
if (length($features_design_file) < 1 or $features_design_file =~ /^-/) 
{
  die("This procedure does not work with pipeline. The features design file must be given as a file argument.\n");
}
else
{
  open(FEATURES_DESIGN_FILE, $features_design_file) or die("Could not open the features design file '$features_design_file'.\n");
  close(FEATURES_DESIGN_FILE);
}

#---------------------------------------------------------------------#
# MAIN                                                                #
#---------------------------------------------------------------------#
my $str0 = `mkdir -p TMP_DESIGN_FEATURES_STATS`;

my $str1 = `cat $features_design_file | cut.pl -f 1-7 | uniq.pl -k 1 | chr_length.pl | cut.pl -f 2,3,7,8,4-6,1 | chr_length.pl | cut.pl -f 2,3,4,5,1,8,6,7,9 | sort.pl -c0 1 | cap.pl "Chr","Feature_id","Start","End","Length","Type","Start_orig","End_orig","Length_orig" | transpose.pl -q > TMP_DESIGN_FEATURES_STATS/tmp_stats_t`;

my $str2 = `cat $features_design_file | cut.pl -f 2,12 | list2neighborhood.pl | transpose.pl -q | compute_column_stats.pl -m -count -skipc 0 | transpose.pl -q | body.pl 2 -1 -b | sort.pl -c0 0 | cap.pl "Feature_id","Count","TM_mean" | cut.pl -f 3,2 | transpose.pl -q >> TMP_DESIGN_FEATURES_STATS/tmp_stats_t`;

my $str3 = `cat TMP_DESIGN_FEATURES_STATS/tmp_stats_t > TMP_DESIGN_FEATURES_STATS/tmp_stats_t1; cat TMP_DESIGN_FEATURES_STATS/tmp_stats_t1 | transpose.pl -q | cut.pl -f 1-11,11 | body.pl 2 -1 -b | modify_column.pl -c 11 -dc 4 | sort.pl -c0 1 | cut.pl -f 12 | cap.pl "%Coverage" | transpose.pl -q >> TMP_DESIGN_FEATURES_STATS/tmp_stats_t`; 

my $str4 = `cat TMP_DESIGN_FEATURES_STATS/tmp_stats_t | transpose.pl -q`;

my @output = split(/\n/,$str4);

for (my $i = 0; $i < @output; $i++)
{
  my $line = $output[$i];
  chomp($line);
  print STDOUT "$line\n";
}

my $str5 = `rm -rf TMP_DESIGN_FEATURES_STATS`;

#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         design_features_stats.pl <file>
 
 Description:    Given a features design file computes and outputs statistics per feature.
                 Notice: does not work with pipeline, the file must be given as an argument.

 Output:         <Chr><\t><Feature_id><\t><Start><\t><End><\t><Length><\t><Type><\t><Start_orig><\t><End_orig><\t><Length_orig><\t><TM_mean><\tCount><\t><%Coverage>

                 The "orig" parameters refer to the original feature before adding the upstream and downstream padding. Count is the number of probes.

                 E.g.:

                 1       YAL001C...YAR002W       150919  152508  1590    Sgd_Divergent Intergenic        151169  152258  1090    73.271  498     0.313207547169811
                 1       YAL005C...YAL003W       141184  142425  1242    Sgd_Divergent Intergenic        141434  142175  742     74.247  394     0.317230273752013

