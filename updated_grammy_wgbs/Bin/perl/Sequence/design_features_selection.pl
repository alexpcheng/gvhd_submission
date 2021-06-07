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

#--------------------------#
# Other files & arguments  #
#--------------------------#
my $ordered_features_stats_file = get_arg("ofs", "", \%args);
my $ordered_features_stats_file_ref;
if (length($ordered_features_stats_file) == 0) 
{
  die("Ordered Features Stats file not given\n");
}
open(OFS, $ordered_features_stats_file) or die("Could not open Ordered Features Stats file '$ordered_features_stats_file'.\n");
$ordered_features_stats_file_ref = \*OFS;
my @tmp = <$ordered_features_stats_file_ref>;
my $ordered_features_stats_file_num_features = @tmp;
close(OFS);
open(OFS, $ordered_features_stats_file) or die("Could not open Ordered Features Stats file '$ordered_features_stats_file'.\n");
$ordered_features_stats_file_ref = \*OFS;

my $pre_selected_probes_file = get_arg("psp", "", \%args);
if (length($pre_selected_probes_file) == 0) 
{
  die("Pre-Selected Probes file not given\n");
}
open(PSP, $pre_selected_probes_file) or die("Could not open Pre-Selected Probes file '$pre_selected_probes_file'.\n");
close(PSP);

my $max_probes = get_arg("max_probes", 0, \%args);
my $output_probe_selection_file_name = get_arg("o_ps", "", \%args);

#---------------------------------------------------------------------#
# MAIN                                                                #
#---------------------------------------------------------------------#
my $str0 = `mkdir -p TMP_DESIGN_FEATURES_SELECTION`;
my $str1 = `cat $pre_selected_probes_file | uniq.pl -k 7 | compute_column_stats.pl -c 7 -skip 0 -count`;
chomp($str1);
my @r = split(/\t/,$str1);
my $total_uniq_probes = (length($r[1]) == 0) ? 0 : $r[1];
my $total_probes = $total_uniq_probes;

if (($max_probes > 0) and ($total_uniq_probes > $max_probes))
{
  die("Wrong parameters: the total unique pre-selected probes is larger than the maximum probes bound given.\n");
}

print STDERR "\nPre-selected total unique probes: $total_uniq_probes\n";

my $counter = 0;
my $final_row_counter = -1;
my $final_total_probes = -1;
my $line;
my @l;

while($line = <$ordered_features_stats_file_ref>)
{
  chomp($line);
  @l = split(/\t/,$line);
  $total_probes += $l[10];
  $counter++;

  if (($max_probes > 0) and ($total_probes >= $max_probes) and ($total_uniq_probes <= $max_probes))
  {
    $total_uniq_probes = &UpdateTotalUniqueProbes($counter);
    if ($total_uniq_probes > $max_probes)
    {
      $final_row_counter = $counter - 1;
      $final_total_probes = $total_probes;
    }
    print STDOUT "$line\t$counter\t$total_uniq_probes\n";
    print STDERR "$counter $total_uniq_probes $total_probes, ";
    $total_probes = $total_uniq_probes;
  }
  elsif (($counter == $ordered_features_stats_file_num_features) and (($max_probes == 0) or ($final_total_probes == -1)))
  {
    $total_uniq_probes = &UpdateTotalUniqueProbes($counter);
    $final_total_probes = $total_uniq_probes;
    $final_row_counter = $counter;
    print STDOUT "$line\t$counter\t$total_uniq_probes\n";
    print STDERR "$counter $total_uniq_probes $total_probes, ";
    $total_probes = $total_uniq_probes;
  }
  else
  {
    print STDOUT "$line\t$counter\t0\n";
    print STDERR "$counter $total_uniq_probes $total_probes, ";
  }
}

print STDERR "\n";

&OutputPostProbesSelectionFile($final_row_counter);

my $str6 = `rm -rf TMP_DESIGN_FEATURES_SELECTION`;

#-------------------------------------------------#
# updated_total UpdateTotalUniqueProbes($counter) #
#-------------------------------------------------#
sub UpdateTotalUniqueProbes
{
  my $my_counter = $_[0];
  my $my_str0 = `head $ordered_features_stats_file -n $my_counter | cut.pl -f 1,2 > TMP_DESIGN_FEATURES_SELECTION/tmp_n`;
  my $my_str1 = `cat $pre_selected_probes_file > TMP_DESIGN_FEATURES_SELECTION/tmp_all_probes_selection.tab`;
  my $my_str2 = `cat $features_design_file | grep -f TMP_DESIGN_FEATURES_SELECTION/tmp_n >> TMP_DESIGN_FEATURES_SELECTION/tmp_all_probes_selection.tab`;
  my $my_str3 = `cat TMP_DESIGN_FEATURES_SELECTION/tmp_all_probes_selection.tab | uniq.pl -k 7 | compute_column_stats.pl -c 7 -skip 0 -count`;
  chomp($my_str3);
  @r = split(/\t/,$my_str3);
  return $r[1];
}

#-------------------------------------------------#
# OutputPostProbesSelectionFile($counter)         #
#-------------------------------------------------#
sub OutputPostProbesSelectionFile
{
  my $my_counter = $_[0];
  my $my_str0 = `head $ordered_features_stats_file -n $my_counter | cut.pl -f 1,2 > TMP_DESIGN_FEATURES_SELECTION/tmp_n`;
  my $my_str1 = `cat $pre_selected_probes_file > TMP_DESIGN_FEATURES_SELECTION/tmp_all_probes_selection.tab`;
  my $my_str2 = `cat $features_design_file | grep -f TMP_DESIGN_FEATURES_SELECTION/tmp_n >> TMP_DESIGN_FEATURES_SELECTION/tmp_all_probes_selection.tab`;
  my $my_str3 = `cat TMP_DESIGN_FEATURES_SELECTION/tmp_all_probes_selection.tab | uniq.pl -k 7 > $output_probe_selection_file_name`;
}

#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

  Syntax:         design_features_selection.pl <file>
 
  Description:    Given a features design file (<file>), an ordered feature stats file, 
                  a preselected probes file and an upper bound on the number of total probes,
                  outputs an augmented features stats file with uppended 2 columns: 
                  feature number and total **unique** probes, and a probes selection file.

                  Notice: does not work with pipeline, the files must be given as arguments.

  Flags:

   -ofs <file>          Ordered Features Stats file.

   -psp <file>          Pre-Selected Probes file.

   -max_probes <int>    Maximum total number of ptobes, **including the preselected probes**
                        (default: 0 == take all features).

   -o_ps <str>          The file name for the post probes selection file.
