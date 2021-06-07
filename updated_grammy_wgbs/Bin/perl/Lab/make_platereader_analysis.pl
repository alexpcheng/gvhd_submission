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

my $arg_command = get_full_arg_command(\@ARGV);
open OUTFILE, ">>make_commands.tab";
print OUTFILE "$0 " . get_full_arg_command(\@ARGV) . "\n";
close(OUTFILE);

my %args = load_args(\@ARGV);

my $num_plates = get_arg("p", 1, \%args);
my $input_dir = get_arg("input_dir", "", \%args);
my $remove_outliers = get_arg("remove_outliers", "", \%args);
my $norm_delta = get_arg("norm_delta", "", \%args);
my $norm_delta1_by_2 = get_arg("norm_delta1_by_2", "", \%args);
my $norm_delta1_by_avg2 = get_arg("norm_delta1_by_avg2", "", \%args);
my $norm_delta1_by_2_with_ref = get_arg("norm_delta1_by_2_with_ref", "", \%args);
my $norm_delta1_by_2_with_ref_fold = get_arg("norm_delta1_by_2_with_ref_fold", "", \%args);
my $norm_smooth = get_arg("norm_smooth", "", \%args);
my $norm_smooth_no_outliers= get_arg("norm_smooth_no_outliers","", \%args);
my $norm_smooth_no_outliers_with_ref=  get_arg("norm_smooth_no_outliers_with_ref", "", \%args);
my $print_intermediate = get_arg("print_intermediate", 1, \%args);
my $sync_times = get_arg("sync_times", "", \%args);
my $by_plate = get_arg("by_plate", 0, \%args);
my $difference_ref = get_arg("difference_ref", "", \%args);
my $division_ref = get_arg("division_ref", "", \%args);

my $avg_by_names = get_arg("avg_by_names", "", \%args);
my $std_by_names = get_arg("std_by_names", "", \%args);
my $stats_by_names = get_arg("stats_by_names", "", \%args);
my $stats_on_cols = get_arg("stats_on_cols", "", \%args);
my $row_properties = get_arg("row_properties", "", \%args);
my $suffix = get_arg("suffix", "", \%args);
my $inter_at_time_points = get_arg("inter_at_time_points", "", \%args);
my $values2ranks = get_arg("values2ranks", "", \%args);
my $values2testedranks = get_arg("values2testedranks", "", \%args);
my $growth4phases = get_arg("growth4phases", "", \%args);
my $growth_logistic = get_arg("logistic_growth", "", \%args);
my $param_times_driven_operation = get_arg("param_times_driven_operation", "", \%args);
my $find_outliers_wells = get_arg("find_outliers_wells", "", \%args);
my $ratio = get_arg("ratio", "",  \%args);
my $smoothed_ratio = get_arg("smoothed_ratio", "",  \%args);

my $time_sliding_win = get_arg("time_sliding_win", "",  \%args);

my $norm1_by_2_stat = get_arg("norm1_by_2_stat", "", \%args);
my $truncate = get_arg("truncate", "", \%args);
my $mulByConst = get_arg("mulByConst", "", \%args);
my $calc_all_pair_ttest = get_arg("calc_all_pair_ttest", "", \%args);
my $log2 = get_arg("log2", "", \%args);

#Exec("rm -f Makefile");
#if ($print_intermediate ==0) {
  # Exec("ln -s /home/genie/Genie/Develop/Templates/Make/platereader_analysis_only_output.mak Makefile");
#   Exec("ln -s /home/genie/Genie/Develop/Templates/Make/platereader_analysis_only_output.mak Makefile");
#}
#else {
  # Exec("ln -s /home/genie/Genie/Develop/Templates/Make/platereader_analysis_with_intermediates.mak Makefile");
#}

my @plates;
my @normalization_files;
my @plates_tab;

open(OUTFILE, ">Makefile.private");
if ($num_plates > 0)
{
   print OUTFILE "\nPLATE_IDS = ";
   for (my $i = 1; $i <= $num_plates; $i++)
   {
      print OUTFILE "$i ";
      Exec("mkdir -p Local/Plate$i");
      Exec("mkdir -p Layout/Plate$i");
      Exec("mkdir -p TabData/Plate$i");
   }
   print OUTFILE "\n\n";
   
   print OUTFILE "FILE_INPUT_DIRS = ";
   for (my $i = 1; $i <= $num_plates; $i++)	
   {
  	print OUTFILE "TabData/Plate$i/*.tab ";
     }
   print OUTFILE "\n\n";
   
   print OUTFILE "FILE_OUTPUT_DIRS = ";
   for (my $i = 1; $i <= $num_plates; $i++)	
   {
      print OUTFILE "Plots/Plate$i ";
   }
   print OUTFILE "\n\n";

   print OUTFILE "FILE_LAYOUT_DIRS = ";
   for (my $i = 1; $i <= $num_plates; $i++)	
   {
  	print OUTFILE "Layout/Plate$i";
     }
   print OUTFILE "\n\n";

   close(OUTFILE);
   $plates_tab[0]= "TabData/";
   $plates_tab[0] =~ s/\//\\\//g;
}
else {
	print OUTFILE "\nPLATE_IDS = 1\n\n";
	print OUTFILE "FILE_INPUT_DIRS = $input_dir/*.tab\n\n";
	print OUTFILE "FILE_OUTPUT_DIRS = $input_dir\n\n";

	close(OUTFILE);
	$plates_tab[0]= "$input_dir/";
	$plates_tab[0] =~ s/\//\\\//g;
}

   $plates[0]= "Layout/";
   $plates[0] =~ s/\//\\\//g;


$normalization_files[0]= "normalization_params.xml";

if ($by_plate == 1 ) {
  for (my $i = 1; $i <= $num_plates; $i++)
    {
      $plates[$i-1]= "Layout/Plate$i/";
      $plates[$i-1] =~ s/\//\\\//g;
      $plates_tab[$i-1]= "TabData/Plate$i/";
      $plates_tab[$i-1] =~ s/\//\\\//g;
      $normalization_files[$i-1]= "plate$i" ."_" ."normalization_params.xml";
    }
  
}
print length(@normalization_files);
for (my $p = 0; $p < $num_plates; $p++) {
  my $normalization_file= $normalization_files[$p];
  my $plate = $plates[$p];
  my $plate_tab = $plates_tab[$p];

  open(OUTFILE, ">$normalization_file");
  print OUTFILE "<Normalizations>\n";
  close(OUTFILE);
  
  
  my @row = split('\,', $remove_outliers);
  for (my $i = 0; $i < @row; $i++)
    {
  Exec("sed 's/__INPUTMATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_remove_outliers_params.xml >> $normalization_file");
}
  
  if ($sync_times ne "") { 
    my @row = split('\,', $sync_times);
    my $output_sync_matrices = "";
    for (my $i = 0; $i < @row; $i++)
      {
	$output_sync_matrices = $output_sync_matrices . "Sy_$row[$i]" . "\," ;
      }
    chop $output_sync_matrices;
    Exec("sed 's/__INPUTMATRICES__/$sync_times/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_sync_times_params.xml | sed 's/__OUTPUTMATRICES__/$output_sync_matrices/g' >> $normalization_file");
  }


  if ($difference_ref ne "") { 
    my @matrices = split('\,', $difference_ref);
    $matrices[1] =~ s/\//\\\//g;
    $matrices[1] = "$plate$matrices[1]";

    my $outliers_file_name = "";
    if (scalar(@matrices) > 2)
      {
	$outliers_file_name = $matrices[2];
	$outliers_file_name =~ s/\//\\\//g;
	$outliers_file_name = "$plate$outliers_file_name";
      }
    
    #my $output_diff_matrix = "$matrices[0]_WR";
    
    Exec("sed 's/__INPUTMATRIX__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_differentiate_ref.xml | sed 's/__REFERENCE_LAYOUT__/$matrices[1]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' >> $normalization_file");
  }
  
  if ($division_ref ne "") { 
    my @matrices = split('\,', $division_ref);
    $matrices[1] =~ s/\//\\\//g;
    $matrices[1] = "$plate$matrices[1]";
    
    my $outliers_file_name = "";
    if (scalar(@matrices) > 2)
      {
	$outliers_file_name = $matrices[2];
	$outliers_file_name =~ s/\//\\\//g;
	$outliers_file_name = "$plate$outliers_file_name";
      }
    
    #my $output_diff_matrix = "$matrices[0]_WR";
    
    Exec("sed 's/__INPUTMATRIX__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_division_by_ref.xml | sed 's/__REFERENCE_LAYOUT__/$matrices[1]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' >> $normalization_file");
  }


  my @row = split('\,', $norm_delta);
  for (my $i = 0; $i < @row; $i++)
    {
      Exec("sed 's/__INPUTMATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_delta_params.xml >> $normalization_file");
    }
  
  my @row = split('\,', $norm_smooth);
  for (my $i = 0; $i < @row; $i++)
    {
      Exec("sed 's/__INPUTMATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_smooth_params.xml >> $normalization_file");
    }

  if ($avg_by_names ne "")
    { 
      my @row = split('\,', $avg_by_names);
      for (my $i = 0; $i < @row; $i++)
	{
	  #$row[$i] =~ s/\//\\\//g;
	  #$row[$i] = "$plate$row[$i]";
	  Exec("sed 's/__INPUT_MATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_avg_by_names.xml >> $normalization_file");
	}
    }

  if ($std_by_names ne "")
    { 
      my @row = split('\,', $std_by_names);
      for (my $i = 0; $i < @row; $i++)
	{
	  Exec("sed 's/__INPUT_MATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_std_by_names.xml >> $normalization_file");
	}
    }
  if ($stats_by_names ne "")
  {
      my @row = split('\;', $stats_by_names);
      print "$row[0]";
      my @matrices = split('\,', $row[0]);
      my $outliers_file_name = "";
      if (scalar(@row) > 2)
      {
	$outliers_file_name = $row[2];
	$outliers_file_name =~ s/\//\\\//g;
	$outliers_file_name = "$plate$outliers_file_name";
      }
      my $appear_num = "";
      if (scalar(@row) > 3)
      {
	  $appear_num = $row[3];
      }
      my $appear_num_filter_type = "";
      if (scalar(@row) > 4)
      {
	  $appear_num_filter_type = $row[4];
      }
      for (my $i = 0; $i < @matrices; $i++)
	{
	  Exec("sed 's/__INPUT_MATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_compute_stats_by_names.xml | sed 's/__STAT_TYPE__/$row[1]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' | sed 's/__APPEAR_NUM__/$appear_num/g' | sed 's/__APPEAR_NUM_FILTER_TYPE__/$appear_num_filter_type/g' >> $normalization_file");
      }
  }

if ($stats_on_cols ne "")
{
    my @row = split('\;', $stats_on_cols);
    my @matrices = split('\,', $row[0]);
    for (my $i = 0; $i < @matrices; $i++)
	{
	  Exec("sed 's/__INPUT_MATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_compute_stats_on_cols.xml | sed 's/__STAT_TYPE__/$row[1]/g' | sed 's/__IGNORE_STR__/$row[2]/g' >> $normalization_file");
      }
}

if ($truncate ne "")
    {
       my @row = split('\;', $truncate);
       my @matrices = split('\,', $row[0]);
       my @truncate_lengths = split('\s',$row[1]);
       for (my $i = 0; $i < @matrices; $i++)
       {
	   Exec("sed 's/__INPUTMATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_truncate.xml | sed 's/__TRUNCATION_LENGTH__/$truncate_lengths[$p]/g'  >> $normalization_file");
       }
       
   }
    
if ($mulByConst ne "")
    {
       my @row = split('\;', $mulByConst);
       my @matrices = split('\,', $row[0]);
       my $mulConst = $row[1];
       for (my $i = 0; $i < @matrices; $i++)
       {
	   Exec("sed 's/__INPUTMATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_multByConst.xml | sed 's/__CONST__/$mulConst/g'  >> $normalization_file");
       }
       
   }

if ($calc_all_pair_ttest ne "")
{
    my @row = split('\;', $calc_all_pair_ttest);
    $row[2] =~ s/\//\\\//g;
    Exec("sed 's/__INPUTMATRIX__/$row[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_calc_all_pair_ttest.xml | sed 's/__COL_NUM__/$row[1]/g' | sed 's/__OUTLIERS__/$row[2]/g' >> $normalization_file");
}


  if ($norm1_by_2_stat ne "")
  {
      my @row = split('\;', $norm1_by_2_stat);
      my @matrices = split('\,', $row[0]);
      print "outlier: $row[3]\n";
      print "norm by plate: $row[4]\n";
      my $outliers_file_name = "";
      my @matrices_labels = split('\,', $row[1]);

      if (scalar(@row) > 3)
      {
	  $outliers_file_name = $row[3];
	  $outliers_file_name =~ s/\//\\\//g;
	  $outliers_file_name = "$plate$outliers_file_name";
      }
      my $norm_by_plates = "";
      if (scalar(@row) > 4)
      {
	  $norm_by_plates = $row[4];
      }
      my $ref_plate = "";
      if (scalar(@row) > 5)
      {
	  $ref_plate = $row[5];
	  $ref_plate =~ s/sc/\;/g;
      }
      my $str2exclude_from_norm_ref = "";
      if (scalar(@row) > 6)
      {
	  $str2exclude_from_norm_ref = $row[6];
      }
      my $ref_strains = "";
      if (scalar(@row) > 7)
      {
	 $ref_strains = $row[7];
      }

      for (my $i = 0; $i < @matrices; $i+=2)
      {
	  Exec("sed 's/__INPUTMATRIX1__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_normalize1_by_stats_on_2.xml | sed 's/__INPUTMATRIX2__/$matrices[$i+1]/g' | sed 's/__INPUTMATRIX_LABEL1__/$matrices_labels[$i]/g' | sed 's/__INPUTMATRIX_LABEL2__/$matrices_labels[$i+1]/g' | sed 's/__STAT_TYPE__/$row[2]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' | sed 's/__NORM_BY_PLATES__/$norm_by_plates/g' | sed 's/__REF_PLATE__/$ref_plate/g' | sed 's/__STR_2_EXCLUDE_FROM_NORM_REF__/$str2exclude_from_norm_ref/g' | sed 's/__REF_STRAINS__/$ref_strains/g' >> $normalization_file");
      }
      
   }

  if ($row_properties ne "")
    { 
      my @row = split('\;', $row_properties);
      my @matrices = split('\,', $row[0]);
      for (my $i = 0; $i < @matrices; $i++)
	{
	  Exec("sed 's/__INPUT_MATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_properties_by_names.xml | sed 's/__ROW_PROPERTIES__/$row[1]/g' | sed 's/__IGNORE_COLS__/$row[2]/g' | sed 's/__SUFFIX__/$suffix/g' >> $normalization_file");
	}
    }

 if ($log2 ne "")
    { 
      my @row = split('\;', $log2);
      my @matrices = split('\,', $row[0]);
      for (my $i = 0; $i < @matrices; $i++)
	{
	  Exec("sed 's/__INPUT_MATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_log2.xml | sed 's/__SUFFIX__/$suffix/g' >> $normalization_file");
	}
    }

  if ($inter_at_time_points ne "")
    {
      print "Here:$inter_at_time_points";
      my @row = split('\;', $inter_at_time_points);
      my @matrices = split('\,', $row[0]);
      for (my $i = 0; $i < @matrices; $i++)
	{
	  Exec("sed 's/__INPUT_MATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_interp_val_at_time_points.xml | sed 's/__INTER_TIME_POINTS__/$row[1]/g' >> $normalization_file");
	}
    }
 if ($growth4phases ne "")
    {
      my @row = split('\;', $growth4phases);
      my $outliers_file_name = $row[4];
      $outliers_file_name =~ s/\//\\\//g;
      $outliers_file_name = "$plate$outliers_file_name";

      Exec("sed 's/__INPUT_MATRIX_GROWTH__/$row[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_growth4phases.xml | sed 's/__GROWTH_OUTLIERS__/$row[1]/g'  | sed 's/__TIME_EDGE_WIDTH__/$row[2]/g'  | sed 's/__PARAMS_OUT_FILE__/$row[3]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' >> $normalization_file");

    }

 if ($growth_logistic ne "")
    {
      my @row = split('\;', $growth_logistic);
      my $outliers_file_name = $row[4];
      $outliers_file_name =~ s/\//\\\//g;
      $outliers_file_name = "$plate$outliers_file_name";

      Exec("sed 's/__INPUT_MATRIX_GROWTH__/$row[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_growth_logistic.xml | sed 's/__GROWTH_OUTLIERS__/$row[1]/g'  | sed 's/__TIME_EDGE_WIDTH__/$row[2]/g'  | sed 's/__PARAMS_OUT_FILE__/$row[3]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' >> $normalization_file");

    }

 if ($param_times_driven_operation ne "")
    {
      my @row = split('\;', $param_times_driven_operation);
      $row[3] =~ s/\//\\\//g;
      $row[3] = "$plate_tab$row[3]";

      Exec("sed 's/__INPUTMATRIX1__/$row[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_data1_by_data2_according2params.xml | sed 's/__INPUTMATRIX2__/$row[1]/g'  | sed 's/__OPERATION_LABEL__/$row[2]/g'  | sed 's/__PARAMS_INPUT_FILE__/$row[3]/g'  | sed 's/__TIME_POLICY__/$row[4]/g'  | sed 's/__OPERATIONS__/$row[5]/g'  >> $normalization_file");
    }




if ($time_sliding_win ne "")
    {
      print "$time_sliding_win";
      my @row = split('\;', $time_sliding_win);

      Exec("sed 's/__INPUTMATRIX1__/$row[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_sliding_win.xml | sed 's/__INPUTMATRIX2__/$row[1]/g'  | sed 's/__STAT_LABEL__/$row[2]/g'  | sed 's/__START_TIME__/$row[3]/g'  | sed 's/__STEP_LEN__/$row[4]/g'  | sed 's/__HALF_WIN_LEN__/$row[5]/g'  >> $normalization_file");
    }





  if ($values2ranks ne "")
    {
      my @row = split('\;', $values2ranks);
      my @matrices = split('\,', $row[0]);
      my $outliers_file_name = "";
      if (scalar(@row) > 2)
      {
	$outliers_file_name = $row[2];
	$outliers_file_name =~ s/\//\\\//g;
	$outliers_file_name = "$plate$outliers_file_name";
      }
      for (my $i = 0; $i < @matrices; $i++)
	{
	  Exec("sed 's/__INPUT_MATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_value2rank.xml | sed 's/__RANK_DIRECTION__/$row[1]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' >> $normalization_file");
	}
    }

  if ($values2testedranks ne "")
  {
      my @row = split('\;', $values2testedranks);
      my @matrices = split('\,', $row[0]);
      my $outliers_file_name = "";
      if (scalar(@row) > 3)
      {
	$outliers_file_name = $row[3];
	$outliers_file_name =~ s/\//\\\//g;
	$outliers_file_name = "$plate$outliers_file_name";
      }
      for (my $i = 0; $i < @matrices; $i+=2)
      {
	  Exec("sed 's/__INPUT_AVERAGED_MATRIX__/$matrices[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_value2testedrank.xml | sed 's/__INPUT_MERGED_MATRIX__/$matrices[$i+1]/g' | sed 's/__RANK_TEST__/$row[1]/g' | sed 's/__RANK_DIRECTION__/$row[2]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' >> $normalization_file");
      }
  }

 if ($find_outliers_wells ne "")
    {
      my @row = split('\;', $find_outliers_wells);
      $row[1] =~ s/\//\\\//g;
      $row[1] = "$plate$row[1]";
      $row[2] =~ s/\//\\\//g;
      $row[2] = "$plate$row[2]";

      Exec("sed 's/__INPUTMATRIX__/$row[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_find_outliers_wells.xml | sed 's/__INPUT_OUTLIERS_FILE__/$row[1]/g'  | sed 's/__OUTPUT_OUTLIERS_FILE__/$row[2]/g'  | sed 's/__STD_THRESH__/$row[3]/g'  | sed 's/__IGNORE_WELLS_STR__/$row[4]/g' | sed 's/__EACH_CONDITION_SEPARATELY__/$row[5]/g' >> $normalization_file");
    }


  my @row = split('\,', $norm_smooth_no_outliers);
  for (my $i = 0; $i < @row; $i++)
    {
      Exec("sed 's/__INPUTMATRIX__/$row[$i]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_smooth_no_outliers_params.xml >> $normalization_file");
    }
  
  my @row = split('\;', $norm_smooth_no_outliers_with_ref);
  for (my $i = 0; $i < @row; $i++)
{
  my @matrices = split('\,', $row[$i]);
  $matrices[1] =~ s/\//\\\//g;
  $matrices[1] = "$plate$matrices[1]";
  my $exec_str = "sed 's/__INPUTMATRIX__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_smooth_no_outliers_with_ref_params.xml ";
  $exec_str   .= "| sed 's/__REFERENCE_LAYOUT__/$matrices[1]/g' ";
  Exec("$exec_str >> $normalization_file");
}



if ($ratio ne "")
    {
       my @row = split('\;', $ratio);
       for (my $i = 0; $i < @row; $i++)
       {
	  my @matrices = split('\,', $row[$i]);
	  Exec("sed 's/__INPUTMATRIX1__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_ratio.xml | sed 's/__INPUTMATRIX2__/$matrices[1]/g'  >> $normalization_file");
       }
    }

if ($smoothed_ratio ne "")
    {
       my @row = split('\;', $smoothed_ratio);
       for (my $i = 0; $i < @row; $i++)
       {
	  my @matrices = split('\,', $row[$i]);
	  Exec("sed 's/__INPUTMATRIX1__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_ratio_and_smooth.xml | sed 's/__INPUTMATRIX2__/$matrices[1]/g'  >> $normalization_file");
       }
    }


if ($norm_delta1_by_2 ne "")
    {
       my @row = split('\;', $norm_delta1_by_2);
       my $outliers_file_name = "";
       $outliers_file_name = $row[scalar(@row)-1];
       $outliers_file_name =~ s/\//\\\//g;
       $outliers_file_name = "$plate$outliers_file_name";
       for (my $i = 0; $i < @row-1; $i++)
       {
	  my @matrices = split('\,', $row[$i]);
	  Exec("sed 's/__INPUTMATRIX1__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_delta1_by_2_params.xml | sed 's/__INPUTMATRIX2__/$matrices[1]/g' | sed 's/__OUTLIERS_FILE__/$outliers_file_name/g' >> $normalization_file");
       }
    }



my @row = split('\;', $norm_delta1_by_2_with_ref);
for (my $i = 0; $i < @row; $i++)
  {
    my @matrices = split('\,', $row[$i]);
  $matrices[2] =~ s/\//\\\//g;
    $matrices[2] = "$plate$matrices[2]";
    $matrices[3] =~ s/\//\\\//g;
    $matrices[3] = "$plate$matrices[3]";
    my $exec_str = "sed 's/__INPUTMATRIX1__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_delta1_by_2_with_ref_params.xml ";
    $exec_str   .= "| sed 's/__INPUTMATRIX2__/$matrices[1]/g' ";
    $exec_str   .= "| sed 's/__REFERENCE_LAYOUT1__/$matrices[2]/g' ";
    $exec_str   .= "| sed 's/__REFERENCE_LAYOUT2__/$matrices[3]/g' ";
    Exec("$exec_str >> $normalization_file");
  }

my @row = split('\;', $norm_delta1_by_2_with_ref_fold);
for (my $i = 0; $i < @row; $i++)
  {
    my @matrices = split('\,', $row[$i]);
    $matrices[2] =~ s/\//\\\//g;
    $matrices[2] = "$plate$matrices[2]";
    $matrices[3] =~ s/\//\\\//g;
    $matrices[3] = "$plate$matrices[3]";
    $matrices[4] =~ s/\//\\\//g;
    $matrices[4] = "$plate$matrices[4]";
    my $exec_str = "sed 's/__INPUTMATRIX1__/$matrices[0]/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/normalization_delta1_by_2_with_ref_fold_induction_params.xml ";
    $exec_str   .= "| sed 's/__INPUTMATRIX2__/$matrices[1]/g' ";
    $exec_str   .= "| sed 's/__REFERENCE_LAYOUT1__/$matrices[2]/g' ";
    $exec_str   .= "| sed 's/__REFERENCE_LAYOUT2__/$matrices[3]/g' ";
    $exec_str   .= "| sed 's/__REFERENCE_LAYOUT3__/$matrices[4]/g' ";
    Exec("$exec_str >> $normalization_file");
  }

open(OUTFILE, ">>$normalization_file");
print OUTFILE "</Normalizations>\n";
close(OUTFILE);
}
#--------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------
sub Exec
{
  my ($exec_str) = @_;
  
  print("Running: [$exec_str]\n");
  system("$exec_str");
}

__DATA__

make_platereader_analysis.pl <file>

   Sets up a directory for plate reader analyses

    -p <num>:                         The number of different plates that are measured in this directory (default: 1)
    -by_plate run all normalizations using different layout for each plate (The Layout dir should contain Plate$(i) dirs. The layout files should be in these dirs)
_____________________________________________________________________________

    -remove_outliers <str>:           Remove outliers from each of the matrices in str. Example: 'YFP,OD,RFP'.
    -sync_times <str>:                Syncronizes the times of matrices in str. Example: 'YFP,OD,RFP'.
    -norm_delta <str>:                Delta each of the matrices in str. Separate matrices by ",". Example: 'YFP,OD'
    -norm_delta1_by_2 <str>:          Smoothing of delta of matrix1 divided by average of adjacent values of matrix2, after removing outliers from each matrix. str format: <matrix1,matrix2;matrix3,matrix4;out_lier_file>. Example: 'YFP,OD;YFP,RFP;Ouliers.tab'
    -ratio <str>:          division of values of Matrix1 by values of matrix2 str format: <matrix1,matrix2;matrix3,matrix4;>. Example: 'YFP,OD;YFP,RFP;'
    -smoothed_ratio <str>:            division of values of Matrix1 by values of matrix2 str format + smoothing : <matrix1,matrix2;matrix3,matrix4;>. Example: 'YFP,OD;YFP,RFP;'
    -norm_delta1_by_2_with_ref <str>: Smooth of delta of matrix1 divided by average of adjacent values of matrix2, after subtracting a reference and removing outliers from each matrix. str format: <matrix1,matrix2,ref1,ref2;matrix3,matrix4,ref3,ref4>. Example: 'YFP,OD,fluorescent_refs.tab,od_refs.tab;YFP,RFP,fluorescent_refs.tab,od_refs.tab'
    -norm_delta1_by_2_with_ref_fold <str>: Smooth of delta of matrix1 divided by average of adjacent values of matrix2, after subtracting a reference and removing outliers from each matrix. Data will we stored as fold induction of wells specified in refA. str format: <matrix1,matrix2,ref1,ref2,refA;matrix3,matrix4,ref3,ref4,refB>. Example: 'YFP,OD,fluorescent_refs.tab,od_refs.tab,fold_ref.tab;YFP,RFP,fluorescent_refs.tab,od_refs.tab,fold_ref.tab'
    -norm_smooth <str>:               Smooth each of the matrices in str. Separate matrices by ",". Example: 'YFP,OD'
    -norm_smooth_no_outliers <str>:   Remove outliers and smooth each of the matrices in str. Separate matrices by ",". Example: 'YFP,OD'
    -norm_smooth_no_outliers_with_ref <str>: Subtract a reference, remove outliers and smooth each of the matrices in str. str format: <matrix1,ref1;matrix2,ref2>. Example: 'YFP,fluorescent_refs.make tab;OD,od_ref
     -print_intermediate <0/1>:        Do you want to print intermediate matrices created during the process. 0-no, 1-yes. Default is yes. 

    -difference_ref norm matrix by differentiating the ref ignoring plate outliers (if outliers file exist) . Example: 'YFP,YFP_ref.tab' or 'YFP,YFP_ref.tab,plate_outliers.tab'
    -division_ref norm matrix by dividing by the ref ignoring plate outliers (if outliers file exist). Example: 'YFP,plate_norm_ref.tab' or 'YFP,plate_norm_ref.tab,plate_outliers.tab'
   -avg_by_names   <str>:               computes averages of rows with the same name Example: 'YFP,OD,RFP'.
   -std_by_names   <str>:               computes stds of rows with the same name Example: 'YFP,OD,RFP'.

   -stats_by_names <str>:               computes the specified statistics (se,std,avg,cv,med or meddif) on rows with the same name. 
                                        This operation ignores(excludes) the given plate outliers. 
                                        This operation can be performed only on strains whose name appears exactly or more than a specified number of times in the matrix.
                                       Use 4th (optional) parameter to specify number of times.
                                       use 5th (optional) parameter to specify whether appearance num should be exactly (eq) or at least (ge) the number specified). 
                                       Example: 'YFP,OD,RFP;se;plate_outliers.tab;4;eq'. 

   -row_properties <str>:               computes the given row properties Example: 'YFP,OD,RFP;Max,TimeOfMax'.
   -suffix <str>:                       suffix to add to row-properties header.
   -inter_at_time_points <str>:         interpolates values in given time points, Example: 'YFP,OD,RFP;10000,35000'
   -values2ranks <str>:                 converts the values to ranks for each time column, Example: 'YFP,OD,RFP;descend'
   -values2testedranks <str>:           converts the values to ranks for each time column. Wells whose values are not significantly separated using the specified test are given the same rank. This operation ignores the given plate outliers. Example: 'YFP_AVG,YFP_MERGED,OD_AVG,OD_MERGED,RFP_AVG,RFP_MERGED;ttest2;descend;plate_outliers.tab'

   -growth4phases <str>:                assuming that the od contain 4 phases - 
                                        lag, exponential, linear, stationary - fits the parameters of the growth.
                                        There is no output matrix. the parameters file is the output. Example: 'OD;__m__;0.1;OD_G4P;plate_outliers.tab' = growth matrix; growth outliers str; growth edge width to ignore for delta computation;learned coeffecient parameters file; outliers file
   -logistic_growth <str>:              assumes that the OD behaves like a logistic function and fits parameters to the growth.
                                        There is no output matrix. the parameters file is the output. Example: 'OD;__m__;0.1;OD_logP;plate_outliers.tab' = growth matrix; growth outliers str; growth edge width to ignore for delta computation;learned coeffecient parameters file; outliers file

   -param_times_driven_operation <str>: Does operation between to matrices according to times specified in the params file 
                                        and operation specified in the <str>.
                                        <str> structure = matrix1;matrix2;operation label;params input file;time policy;operations string.
                                        The time policy is either Real or Index (consider what you want because merging interpolates by times)
                                        The operation string has the following format: 
                                         operation#time1#time2(if needed)#param1(if needed)#param2(if needed),operation#time1# ...
                                         params and times can either be numbers (or "end" for the last time) 
                                         or names of params in input params
                                        For example to compute the YFP production for OD unit during the four phases 
                                        of "growth 4 phases" with 10% margin - Example <str>:
                                        'YFP;OD;G4P_D2I;G4P.params;Index;Delta2Integral#0#t0#0.1,Delta2Integral#t0#t1#0.1,Delta2Integral#t1#t2#0.1,Val2Val#t2'.

   -find_outliers_wells <str>          Find outliers data wells , Exmaple: 'OD;old_plate_outliers.tab;new_plate_outliers.tab;3;__m__;true' the "3" parameters is a the thresh for std above mean of the Zscore sum, the before last parametr is str that if exist in well name do not consider in computation or as outlier, the last parameters is true/false wether to do the computation for each condition separately


time_sliding_win <str>:                      : Computes sliding window value. The value can be computed over 2 matrices.
                                          <str> structure:  matrix1;matrix2;operation label;start_time(sec),step_len(sec),half_win_len(sec)
                                          For example: 'YFP;OD;D2I;1800;1800;1800' will compute delta of YFP over integral of OD for every hour in jumps of one hour

norm1_by_2_stat <str>:                  Normalizes values in first matrix by stats on values in second matrix. This operation excludes the given plate outliers from the norm (second) table. 
                                        Arguments: 1) pairs of matrix and the matrix by which it is normalized. 
                                                   2) pairs of matrix label and the matrix by which it is normalized labels. 
                                                   3) stat typ (avg,med,relavg,relmed). 
                                                   4) outlier file. 
						   5) Normalize by plate (boolean).
                                                   6) (optional)- reference plate for relavg,relmed statistics (use "sc" instead of semi-colon mark), it is possible to sepecify median/mean for normalization in the median/mean of all plates.
						   7) (optional) str that if appear in the well name of the second matrix consider as outlier for the normalization. 
					           8) (optional) - reference strains to normalize by. In this case the statistic of plate2 will not be calculated on the entire plate, but only on the reference strains. Example: 'YFP,YFP_NORM_MATRIX,OD,OD_NORM_MATRIX;YFP,YFP_NORM_MAT,OD,OD_NORM_MAT;avg;plate_outliers.tab;true;1sc1;__m__,__MSYFP__'

truncate <str>:                        Truncates list of matrices to contain specified number of columns. 
                                       For example:  'OD,YFP,RFP;100'

mulByConst <str>:                      Multiplies list of matrices by constant. 
                                       For example: 'G4P_YFP_D2SI_OD_NormBy_relmed_G4P_RFP_D2SI_OD_seN;2'

calc_all_pair_ttest <str>:             Receives a matrix and coloumn value and calculates t-tests between 
                                       the values of this coloumn (second parameter) in all rows.
                                       Receives outliers file to ignore. 
                                       For example: 'G4P_YFP_D2SI_OD_NormBy_relmed_G4P_RFP_D2SI_OD_AvgN;2;plate_detected_outliers.tab'

stats_on_cols <str>:                   Computes desired statistics (se,std,avg,cv,med) on coloums of matrix. Several matrices and/or statistics can be specified using comma.
                                       Wells to ignore while calculating statistic may be added
                                       Example: 'M_G4P_YFP_D2SI_OD_NormBy_relmed_G4P_RFP_D2SI_OD_avgN;avg,med,std;__m'
-log2 <1>                              Convert mat to log2(mat)
