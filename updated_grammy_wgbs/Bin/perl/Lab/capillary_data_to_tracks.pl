#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my @SAMPLE_INFO_COLS = ("SampleName", "LogicalName", "Dye", "Direction", "ControlName");

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $sample_info_file = get_arg("sample_info", "", \%args);
my $promoter_gbk_file = get_arg("promoter_info", "", \%args);
my $capillary_data_file = get_arg("capillary_data", "", \%args);
my $prefix_str = get_arg("p", "", \%args);
my $offset = get_arg("offset", -25, \%args);
my $norm_cutoff = get_arg("norm_disp_cutoff", 0.05, \%args);

if (! $prefix_str) { die ("Please supply -p paremeter\n")};
if (! $sample_info_file) { die ("Please supply -sample_info parameter\n")};
if (! $promoter_gbk_file) { die ("Please supply -promoter_info paremeter\n")};
if (! $capillary_data_file) { die ("Please supply -capillary_data paremeter\n")};

if (! -e $sample_info_file) { die ("File $sample_info_file not found\n")};
if (! -e $promoter_gbk_file) { die ("File $promoter_gbk_file not found\n")};
if (! -e $capillary_data_file) { die ("File $capillary_data_file not found\n")};

my $promoter_name = `dos2unix.pl < $promoter_gbk_file | genbank2stab.pl  | cut -f 1`;
$promoter_name =~ s/\s*$//g;

system ("dos2unix $sample_info_file 2> /dev/null");
my %sample_info_hash = &load_sample_info_file($sample_info_file);

# Sequence track 
#open (TMP_SEQ_CHR, ">tmp_${prefix_str}_seq.chr") or die "Failed to open temporary output file, exiting";
#for my $c (split("","ACGT")) 
#{
#    print TMP_SEQ_CHR "${promoter_name}\tdummy${c}\t0\t0\t${c}\t1\n";
#}
#close TMP_SEQ_FILE;
my $promoter_length = `dos2unix.pl < $promoter_gbk_file | genbank2stab.pl | stab2length.pl | cut -f 2`;
chop $promoter_length;
system ("dos2unix.pl < $promoter_gbk_file | genbank2stab.pl | stab2tab.pl | cut -f 2- | transpose.pl -q | lin.pl | add_column.pl -b -s '$promoter_name' | cut.pl -f 1-3,3- | add_column.pl -s 1 > tmp_${prefix_str}_seq.chr");
system ("tab2feature_gxt.pl tmp_${prefix_str}_seq.chr -n '$promoter_name: DNA sequence' -dt -minc 0 -maxc 1 -l 'Filled box' -lh 10 > ${prefix_str}_seq.gxt");

# Features track
my $first_line = `dos2unix.pl < $promoter_gbk_file | grep -n ^FEATURES | cut -f 1 -d ':'` + 1;
my $last_line = `dos2unix.pl < $promoter_gbk_file | grep -n '^BASE COUNT' | cut -f 1 -d ':'` - 1;

open (TMP_FEAT_FILE, ">tmp_${prefix_str}_features.chr") or die "Failed to open temporary output file, exiting";
my $features_str = `dos2unix.pl < $promoter_gbk_file | body.pl $first_line $last_line `;

my $type;
my $start;
my $end;
my $id;
for my $line (split(/\n/, $features_str))
{
    if ($line =~ /\/note="(.+)"/ )
    {
       $id = $1;
       print TMP_FEAT_FILE "$promoter_name\t$id\t$start\t$end\t$type\t1\n";
    }
    elsif ($line =~ /^\s*(\S+)\s*complement\((\d+)\.\.(\d+)\)/)
    {
	$type = $1;
	$start = $3;
	$end = $2;
    }
    elsif ($line =~ /^\s*(\S+)\s*(\d+)\.\.(\d+)/)
    {
	$type = $1;
	$start = $2;
	$end = $3;
    }
#    print STDERR "$id\t$start\t$end\t$type\n";
}
close TMP_FEAT_FILE;

system ("cat tmp_${prefix_str}_features.chr".'| chr2minusplus.pl | modify_column.pl -c 4 -str "\+" -set fw | modify_column.pl -c 4 -str "-" -set rv | cut.pl -f 1,5,2-4,6- | merge_columns.pl -1 1 -2 2 -d ": " | uniquify.pl -c 1 >'."${prefix_str}_features.chr"); 
system ("tab2feature_gxt.pl ${prefix_str}_features.chr -n '$promoter_name: Genomic features' -minc 0 -zeroc 0 -maxc 1 -l 'Filled box'  -dt -lh 20 > ${prefix_str}_features.gxt"); 
unlink "tmp_${prefix_str}_features.chr";

# Data tracks (raw and normalized)
open (RAW_DATA,  ">tmp_${prefix_str}_raw_data.chr") or die "Failed to open file tmp_${prefix_str}_raw_data.chr for writing.";
open (NORM_DATA, ">tmp_${prefix_str}_norm_data.chr") or die "Failed to open file tmp_${prefix_str}_norm_data.chr for writing.";
my $unmatcahed_lines = `dos2unix.pl < $capillary_data_file | tail -n +2 | filter.pl -c 0 -ne -q | filter.pl -c 4 -ne -q | cut -c 2- | modify_column.pl -c 0 -rmre ',.*' | cut.pl -f 2,1,5,6 | join.pl - ${sample_info_file} -1 1 -2 1 -q -neg | wc -l`;
chop $unmatcahed_lines;
if ($unmatcahed_lines and $unmatcahed_lines > 0 )
{
   print STDERR "Warning: $unmatcahed_lines unmatched lines in capillary input data.";
}

my $lines_str = `dos2unix.pl < $capillary_data_file | tail -n +2 | filter.pl -c 0 -ne -q | filter.pl -c 4 -ne -q | cut -c 2- | modify_column.pl -c 0 -rmre ',.*' | cut.pl -f 2,1,5,6 | join.pl - ${sample_info_file} -1 1 -2 1 -q  |  filter.pl -c 1 -estr -u 5 -q | cut.pl -f 5,3,7,8,4 | sort.pl -c0 3 -c1 0 -c2 1 -n2 -q `;
 
my @lines = split(/\n/, $lines_str);
my %data;

my %samples;
for (my $i = 0; $i < $#lines; $i++)
{
   my ($sample,$pos,$dir,$control_sample,$val) = split (/\t/, $lines[$i]);

   if ($dir eq "-")
   {
      $pos = $promoter_length - $pos - $offset;
   }
   else
   {
      $pos += $offset;
   }
   $pos = int($pos) + (($pos - int($pos))/0.5 >=1 ? 1 : 0);

   $val = &format_number($val, 3);

   $data{$sample}{$pos} = $val;

   print RAW_DATA "$promoter_name\tID_$i\t$pos\t$pos\t$sample\t$val\n";

   if (length($control_sample) > 0)
   {
      
      my $control_val = $data{$control_sample}{$pos}; 
      $val = &format_number(($val + 0.0) / ($control_val != 0 ? $control_val : 1), 3);
      
      if (!$samples{$sample})
      {
	 $samples{$sample} = 1;
      }

      $data{$sample}{$pos} = $val;

      print NORM_DATA "$promoter_name\tID_$i\t$pos\t$pos\t$sample\t$val\n";
   }
}

close RAW_DATA;
close NORM_DATA;

system ("cat tmp_${prefix_str}_raw_data.chr | sort.pl -c0 0 -c1 2 -n1 -c2 4 -q > ${prefix_str}_raw_data.chr");
system ("cat tmp_${prefix_str}_norm_data.chr | sort.pl -c0 0 -c1 2 -n1 -c2 4 -q > ${prefix_str}_norm_data.chr");

my $raw_min_val = `cut -f 6 ${prefix_str}_raw_data.chr | compute_column_stats.pl -c 0 -skip 0 -min | cut -f 2 `;
my $raw_max_val = `cut -f 6 ${prefix_str}_raw_data.chr | compute_column_stats.pl -c 0 -skip 0 -max | cut -f 2 `;
$raw_min_val =~ s/\s*$//g;
$raw_max_val =~ s/\s*$//g;

system ("tab2feature_gxt.pl ${prefix_str}_raw_data.chr -n '$promoter_name: Raw capillary data' -minc $raw_min_val -zeroc $raw_min_val -maxc $raw_max_val -l 'Filled box' -lh 40 -fixed_order -dt -fixed_order > ${prefix_str}_raw_data.gxt");

my $norm_max_val = `cut -f 6 ${prefix_str}_norm_data.chr | compute_column_stats.pl -c 0 -skip 0 -max | cut -f 2 `;
my $norm_second_max_val = `cut -f 6 ${prefix_str}_norm_data.chr | sort -n | uniq | tail -n 2 | head -n 1 `;
$norm_second_max_val =~ s/\s*$//g;
my $norm_min_val = $norm_second_max_val * $norm_cutoff;
$norm_max_val =~ s/\s*$//g;


system ("tab2feature_gxt.pl ${prefix_str}_norm_data.chr -n '$promoter_name: Normalized capillary data' -minc $norm_min_val -zeroc $norm_min_val -maxc $norm_max_val -l 'Filled box' -lh 40 -fixed_order -dt -fixed_order > ${prefix_str}_norm_data.gxt");

# Create final output: Combine tracks to gxp and create histograms figure
my @sample_names = keys %samples;
system ("numgen.pl -s '\"offset\"' -e $promoter_length | add_column.pl -s 0 | add_column.pl -b -s $sample_names[0] > tmp_${prefix_str}");
system ("cat ${prefix_str}_norm_data.chr | cut.pl -f 5,3,6 | cat - tmp_${prefix_str} | list2tab.pl -V 2 -sortn | transpose.pl -q | sort.pl -skip 1 -c0 0 -q | transpose.pl -q | make_gnuplot_graph.pl -all -multiplot -png -o ${prefix_str}_hist.png -ds boxes -image_size '${promoter_length},".(150*($#sample_names + 1))."' -fs solid -t '$promoter_name: Normalized capillary data'");
system ("gxt2gxp.pl ${prefix_str}_seq.gxt ${prefix_str}_features.gxt ${prefix_str}_norm_data.gxt ${prefix_str}_raw_data.gxt  > ${prefix_str}.gxp");
system ("rm tmp_${prefix_str}_seq.chr ${prefix_str}_seq.gxt ${prefix_str}_features.gxt ${prefix_str}_raw_data.gxt  ${prefix_str}_norm_data.gxt tmp_${prefix_str}_norm_data.chr tmp_${prefix_str}_raw_data.chr tmp_${prefix_str}");

################################
# Input is a the sample info file name
# Returns a hash with these pairs: <LogicalName_ColumnName> -> <column value>
################################
sub load_sample_info_file
{
   my $input_file = @_[0];
   open (INPUT, "<$input_file") or die "Failed to open $input_file";

   my %res;
   my @r;
   my $key;
   while (<INPUT>)
   {
      chop;
      @r = split(/\t/);
      $key = @r[1];
      for (my $i = 0; $i < $#SAMPLE_INFO_COLS; $i++)
      {
	 if ($i != 1)
	 {
	    $res{$key."_".$SAMPLE_INFO_COLS[$i]} = $r[$i];
	 }
      }
   }

   return %res;
}

__DATA__

capillary_data_to_tracks.pl

   Creates Genomica tracks from capillary experiments data file. 
   
    -p <str>:                  Use <str> as a file name prefix.

    -offset <num>:             Offset the capillary output file coordinates by <num> downstream (default: -25)
    -norm_disp_cutoff <num>:   Minimum display cutoff for normalized data is <num> * <Second high value> (default: 0.05)

    -promoter_info <str>:      File <str> contains the sequence of the promoter and its features (genbank file format)

    -sample_info <str>:       Tab delimited file <str> holds information on the samples. It has these columns:
                                  1) Sample file name
                                  2) Logical name
                                  3) Dye (G, O, Y, R or B)
                                  4) Direction (+\-)
                                  5) Logical name of the relevant control sample (leave empty for the control samples themselves)

                                       For example:
                                                    250-1_A11_2009-09-03.fsa   Non digested control	    G   +
                                                    250-2_B11_2009-09-03.fsa   MNase digested genomic DNA   B   +   Non digested control


    -capillary_data <str>:     File <str> has the experiement data with these columns:
                                  1) Dye/Sample Peak: Only dye specified in sample_info is used
                                  2) Sample File Name: see -sample_info
                                  3) Marker: Not used
                                  4) Allele: Not used
                                  5) Size:   Position on the sequence (will be rounded to the nearest integer)
                                  6) Height: Signal value
                                  7) Area:   Not used
                                  8) Data Point: Not used

