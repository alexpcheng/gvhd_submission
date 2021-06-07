#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
#require "$ENV{PERL_HOME}/Lib/format_number.pl";
#require "$ENV{PERL_HOME}/GeneXPress/gxt_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $load_mat = get_arg("load_mat", "", \%args); $load_mat = $load_mat == 1 ? "" : $load_mat;
if (length($load_mat) > 0)
{
   open(TMP_LOAD_MAT_REF,"$load_mat") or die("Could not open the '-load_mat' input file for reading: '$load_mat'.\n");
   close(TMP_LOAD_MAT_REF);
}

#-------------------------------------------------------------------------------------------#
# Make a TMP directory to work in
#-------------------------------------------------------------------------------------------#
my $ir = get_arg("ir", "", \%args); $ir = $ir == 1 ? "" : $ir;
my $r = $ir;
my $tmp_working_dir = ".";
my $current_dir = `pwd`;
chomp($current_dir);
if (length($ir) == 0)
{
   $r = int(rand(1000000));
   $tmp_working_dir = "$current_dir"."/tmp_COMPUTE_LOCATION_LOG_SCALE_$r";
   system("mkdir -p $tmp_working_dir;");
}


#-------------------------------------------------------------------------------------------#
# Load statistics file and break it into chromosomes (to ensure a memory safe run)
#-------------------------------------------------------------------------------------------#
my $qmin = get_arg("qmin", 0, \%args);
my $stats_location_file = get_arg("f", "", \%args); $stats_location_file = $stats_location_file == 1 ? "" : $stats_location_file;
my $break_stats_file = get_arg("break_stats_file", 0, \%args);
my $run_statistics = get_arg("run_statistics", 0, \%args);
my $adjusted = get_arg("adjusted", 0, \%args);

if (length($stats_location_file) == 0 and length($load_mat) == 0)
{
  die "Statistics location file not given.\n";
}
if (length($ir) == 0 and length($load_mat) == 0)
{
   # Send this jobs to the queue (very heavy i/o for the master)
   if ($qmin > 0)
   {
      print STDERR "Break statistics file...\n";
      my $tmp_commands_file = $tmp_working_dir. "/tmp_commands";
      open(COMMANDS, ">$tmp_commands_file") or die("Could not open tmp file for writing '$tmp_commands_file'.\n");
      print COMMANDS "q.pl 'compute_location_log_scale_ave_stats.pl -f $stats_location_file -ir $r -break_stats_file;';\n";
      close(COMMANDS);
      system("cd $tmp_working_dir; qp.pl -f $tmp_commands_file -min_t 0 -min_u 10000 -finish -manual -ping; cd $current_dir;");
   }
}
elsif ($break_stats_file or (length($ir) == 0 and length($load_mat) == 0 and $qmin == 0))
{
   my $tmp_chr = "";
   open(STATS_LOCATION_FILE, $stats_location_file) or die("Could not open statistics location file '$stats_location_file'.\n");
   while (my $l = <STATS_LOCATION_FILE>)
   {
      chomp($l);
      my @r = split(/\t/,$l,2);
      $r[1] = "";
      if ($tmp_chr ne $r[0])
      {
	 $tmp_chr = $r[0];
	 my $stats_location_file_by_chr = $tmp_working_dir. "/stats_chr_" . $tmp_chr;
	 open(STATS_LOCATION_FILE_BY_CHR, ">$stats_location_file_by_chr") or die("Could not open tmp file for writing '$stats_location_file_by_chr'.\n");
      }
      print STATS_LOCATION_FILE_BY_CHR "$l\n";
   }
   close(STATS_LOCATION_FILE_BY_CHR);
   exit; # because we are in an internal run (job in a queue)
}

#-------------------------------------------------------------------------------------------#
# Load location file
#-------------------------------------------------------------------------------------------#
my $location_file = $ARGV[0];

my $ifrom = get_arg("ifrom", 1, \%args);
my $ito = get_arg("ito", -1, \%args);
my $ito_tag = ($ito == -1) ? "end" : $ito;

(($ifrom >= 1) and (($ito == -1) or ($ito >= $ifrom))) or die("Flags -ifrom & -ito are wrong: $ifrom $ito\n");

my $location_file_wc = 0;

my $tmp_location_file_ref = $tmp_working_dir . "/tmp_input_location_file_" . $ifrom . "_" . $ito_tag . ".chr";
open(TMP_LOCATION_FILE_REF,">$tmp_location_file_ref") or die("Could not open file for writing '$tmp_location_file_ref'.\n");
if (length($location_file) < 1 or $location_file =~ /^-/)
{
   my $counter = 1;
   while (my $l = <STDIN>)
   {
      if (($counter >= $ifrom) and (($ito == -1) or ($counter <= $ito)))
      {
	 chomp($l);
	 print TMP_LOCATION_FILE_REF "$l\n";
	 $location_file_wc++;
      }
      $counter++;
   }
}
else
{
   open(TMP_LOCATION_FILE_REF2, $location_file) or die("Could not open the location file '$location_file'.\n");
   my $counter = 1;
   while (my $l = <TMP_LOCATION_FILE_REF2>)
   {
      if (($counter >= $ifrom) and (($ito == -1) or ($counter <= $ito)))
      {
	 chomp($l);
	 print TMP_LOCATION_FILE_REF "$l\n";
	 $location_file_wc++;
      }
      $counter++;
   }
   close(TMP_LOCATION_FILE_REF2);
}
close(TMP_LOCATION_FILE_REF);

#-------------------------------------------------------------------------------------------#
# More args
#-------------------------------------------------------------------------------------------#
my $significant_numbers = get_arg("p", 3, \%args);
my $output_prefix = get_arg("output_prefix", "log_scale_ave_stats", \%args);
my $log_from = get_arg("log_from", 0, \%args);
my $log_to = get_arg("log_to", 7, \%args);
my $log_res = get_arg("log_res", 1, \%args);
my $log_base = get_arg("log_base", 10, \%args);

my $align_by = get_arg("align_by", "s", \%args);
($align_by eq "s") or ($align_by eq "e") or ($align_by eq "c") or ($align_by eq "a") or die("The '-align_by' flag expects either s/e/c/a, found: $align_by\n");
if ($align_by eq "a")
{
   $log_from = 0;
   $log_to = 0;
}

my $standard_profile_mode = get_arg("prof", 0, \%args);
(($align_by ne "a") or ($standard_profile_mode eq 0)) or die("Cannot use both '-align_by a' and '-prof v1,v2,v3' modes.\n");

my $standard_profile_mode_res = 0;
my $standard_profile_mode_half_window_size = 0;
my $standard_profile_mode_max = 0;
if ($standard_profile_mode ne 0)
{
   my @tmp_r = split(/\,/,$standard_profile_mode);
   (@tmp_r == 3) or die("The -prof flag expects input of the form 'v1,v2,v3' for resolution of v1, half window size of v2 and profile max coordinate of v3. Found: $standard_profile_mode\n");
   $standard_profile_mode_res = $tmp_r[0];
   $standard_profile_mode_half_window_size = $tmp_r[1];
   $standard_profile_mode_max = $tmp_r[2];
   $log_from = 0;
   $log_to = 0;
}

my @window_end = ();
my $c = 0;

if ($standard_profile_mode eq 0)
{
   for (my $i=$log_from; $i<=$log_to; $i=$i+$log_res)
   {
      $window_end[$c] = $i;
      $c++;
   }
}
else
{
   for (my $i=0; $i<=$standard_profile_mode_max; $i=$i+$standard_profile_mode_res)
   {
      $window_end[$c] = $i;
      $c++;
   }
}

# For positional correlation profile
my $correlations_file = get_arg("corr", "", \%args); $correlations_file = $correlations_file == 1 ? "" : $correlations_file;
my $correlations_num_sim = get_arg("corr_sim", 100, \%args);
$correlations_num_sim = ($correlations_num_sim > 0) ? $correlations_num_sim : 1; # Otherwise the output of compute_pairwise_stats.pl will be different then expected
my $tmp_input_correlations_file = $tmp_working_dir . "/tmp_input_correlations_file.tab";
if (length($correlations_file) > 0 and $run_statistics == 0)
{
   open(TMP_FILE_FOR_CORRELATIONS, "$correlations_file") or die("Could not open the input correlations file for reading '$correlations_file'.\n");
   open(FILE_FOR_CORRELATIONS, ">$tmp_input_correlations_file") or die("Could not open tmp file for writing '$tmp_input_correlations_file'.\n");
   my $l=<TMP_FILE_FOR_CORRELATIONS>; chomp($l); my @r = split(/\t/,$l,2); print FILE_FOR_CORRELATIONS "Id\t$r[1]\n";
   while($l=<TMP_FILE_FOR_CORRELATIONS>) {chomp($l); print FILE_FOR_CORRELATIONS "$l\n";}
   close(TMP_FILE_FOR_CORRELATIONS);
   close(FILE_FOR_CORRELATIONS);
}

# For positional AUC profile
my $auc_file = get_arg("auc", "", \%args); $auc_file = $auc_file == 1 ? "" : $auc_file;
my $tmp_input_auc_file = $tmp_working_dir . "/tmp_input_auc_file.tab";
if (length($auc_file) > 0 and $run_statistics == 0)
{
   open(TMP_FILE_FOR_AUC, "$auc_file") or die("Could not open the input auc file for reading '$auc_file'.\n");
   open(FILE_FOR_AUC, ">$tmp_input_auc_file") or die("Could not open tmp file for writing '$tmp_input_auc_file'.\n");
   my $l=<TMP_FILE_FOR_AUC>; chomp($l); my @r = split(/\t/,$l,2); print FILE_FOR_AUC "Id\t$r[1]\n";
   while($l=<TMP_FILE_FOR_AUC>) {chomp($l); print FILE_FOR_AUC "$l\n";}
   close(TMP_FILE_FOR_AUC);
   close(FILE_FOR_AUC);
}

# For positional average (+std) profile
my $ave_file = get_arg("ave", "", \%args); $ave_file = $ave_file == 1 ? "" : $ave_file;
my $tmp_input_ave_file = $tmp_working_dir . "/tmp_input_ave_file.tab";
if (length($ave_file) > 0 and $run_statistics == 0)
{
   open(TMP_FILE_FOR_AVE, "$ave_file") or die("Could not open the input ave file for reading '$ave_file'.\n");
   open(FILE_FOR_AVE, ">$tmp_input_ave_file") or die("Could not open tmp file for writing '$tmp_input_ave_file'.\n");
   my $l=<TMP_FILE_FOR_AVE>; chomp($l); my @r = split(/\t/,$l,2); print FILE_FOR_AVE "Id\t$r[1]\n";
   while($l=<TMP_FILE_FOR_AVE>) {chomp($l); print FILE_FOR_AVE "$l\n";}
   close(TMP_FILE_FOR_AVE);
   close(FILE_FOR_AVE);
}

my $arg_figure_format = get_arg("figmat", "fig", \%args);

# For histograms
my $hist_num_bins = get_arg("hist", 50, \%args);
my $dont_calc_histograms = ($hist_num_bins == 0) ? 1 : 0;

# For taking symmetric profiles (averaging forward and backward profiles before taking statistics)
my $sym_mode = get_arg("sym", 0, \%args);

# Minimum percent of statistics (relative to location) for taking the ave stats (otherwise print "" for the corresponding location).
my $min_stat_percent_threshold = get_arg("mstat", 0.4, \%args);
($min_stat_percent_threshold > 0) and ($min_stat_percent_threshold <= 1) or die("The '-mstat' flag expects a number >0 and <=1. Found: $min_stat_percent_threshold\n");

#-------------------------------------------------------------------------------------------#
# Locations loop: (1) break location file and send to queue, or (2) process the locations
#-------------------------------------------------------------------------------------------#
#my $qmin = get_arg("qmin", 0, \%args);
my $qmax = get_arg("qmax", 140, \%args);
my $qnlines = get_arg("qnlines", 30, \%args);
my $tmp_output_profiles_file = $tmp_working_dir. "/tmp_output_profiles_" . $ifrom . "_" . $ito_tag . ".tab";
my $tmp_commands_file = $tmp_working_dir. "/tmp_commands";

if (length($load_mat) > 0)
{
   # Do nothing here -- no need to prepare the profiles
}
elsif (length($ir) == 0 and $qmin > 0)
{
   print STDERR "Compute profiles...\n";
   open(COMMANDS, ">$tmp_commands_file") or die("Could not open tmp file for writing '$tmp_commands_file'.\n");
   for (my $i=1; $i <= $location_file_wc; $i=$i+$qnlines)
   {
      my $tmp_ifrom = $i;
      my $tmp_ito = $i+$qnlines-1;
      if ($standard_profile_mode eq 0)
      {
	 print COMMANDS "q.pl 'compute_location_log_scale_ave_stats.pl $tmp_location_file_ref -f $stats_location_file -adjusted $adjusted -p $significant_numbers -sym $sym_mode -mstat $min_stat_percent_threshold -log_base $log_base -log_from $log_from -log_to $log_to -log_res $log_res -align_by $align_by -output_prefix $output_prefix -ir $r -ifrom $tmp_ifrom -ito $tmp_ito;';\n";
      }
      else
      {
	 print COMMANDS "q.pl 'compute_location_log_scale_ave_stats.pl $tmp_location_file_ref -f $stats_location_file -adjusted $adjusted -p $significant_numbers -sym $sym_mode -mstat $min_stat_percent_threshold -log_base $log_base -prof $standard_profile_mode -log_res $log_res -align_by $align_by -output_prefix $output_prefix -ir $r -ifrom $tmp_ifrom -ito $tmp_ito;';\n";
      }
   }
   close(COMMANDS);

   # Run parallel jobs in the queue
   system("cd $tmp_working_dir; qp.pl -f $tmp_commands_file -min_t 0 -min_u $qmin -max_u $qmax -finish -manual -ping; cd $current_dir;");

   # Collect results
   open(OUTPUT_PROFILES, ">$tmp_output_profiles_file") or die("Could not open tmp file for writing '$tmp_output_profiles_file'.\n");
   for (my $i=1; $i <= $location_file_wc; $i=$i+$qnlines)
   {
      my $tmp_ifrom = $i;
      my $tmp_ito = $i+$qnlines-1;
      my $tmp_collect_output_profiles_file = $tmp_working_dir. "/tmp_output_profiles_" . $tmp_ifrom . "_" . $tmp_ito . ".tab";
      open(COLLECT_OUTPUT_PROFILES, "$tmp_collect_output_profiles_file") or die("Could not open tmp file for reading '$tmp_collect_output_profiles_file'.\n");
      while(my $l=<COLLECT_OUTPUT_PROFILES>) {chomp($l); my @r=split(/\t/,$l); if(@r>1){shift(@r);my $rl=join("",@r);if(length($rl)>0){print OUTPUT_PROFILES "$l\n";}}}
      close (COLLECT_OUTPUT_PROFILES);
   }
}
else
{
   open(LOCATION_FILE_REF, $tmp_location_file_ref) or die("Could not open the location file '$tmp_location_file_ref'.\n");
   open(OUTPUT_PROFILES, ">$tmp_output_profiles_file") or die("Could not open tmp file for writing '$tmp_output_profiles_file'.\n");

   while (my $l = <LOCATION_FILE_REF>)
   {
      chomp($l);
      my @r = split(/\t/,$l);
      my $chr = $r[0];
      my $id = $r[1];
      my $start = $r[2];
      my $end = $r[3];

      my $tmp_location_file = $tmp_working_dir. "/tmp_location_" . $ifrom . "_" . $ito_tag . ".chr";
      open(TMP_LOCATION, ">$tmp_location_file") or die("Could not open tmp file for writing '$tmp_location_file'.\n");

      # Align by
      my $pivot_plus;
      my $pivot_minus;
      if ($align_by eq "s")
      {
	 $pivot_plus = ($start <= $end) ? $start : $start + 1;
      }
      elsif ($align_by eq "e")
      {
	 $pivot_plus = ($start <= $end) ? $end + 1 : $end;
      }
      elsif ($align_by eq "c")
      {
	 $pivot_plus = ($start <= $end) ? int(($start+$end)/2)+1 : int(($start+$end)/2);
      }
      elsif ($align_by eq "a")
      {
	 # Do nothing -- we deal with this case later
      }
      else { die("Unknown '-align_by' flag\n"); }
      $pivot_minus = $pivot_plus;

      # Middle point
      my $coordinate = 0;
      my $tmp_start = ($standard_profile_mode eq 0) ? $pivot_minus - int($log_base ** $window_end[0]) + 1 : $pivot_minus - $window_end[0] - $standard_profile_mode_half_window_size;
      my $tmp_end = ($standard_profile_mode eq 0) ? $pivot_plus + int($log_base ** $window_end[0]) - 1 : $pivot_plus + $window_end[0] + $standard_profile_mode_half_window_size;
      if ($align_by eq "a")
      {
	 print TMP_LOCATION "$chr\t$coordinate\t$start\t$end\n";
      }
      else
      {
	 print TMP_LOCATION "$chr\t$coordinate\t$tmp_start\t$tmp_end\n";
      }

      # Other points
      for (my $i=1; $i<@window_end; $i++)
      {
	 $coordinate = ($start <= $end) ? -$i : $i;
	 $tmp_start = ($standard_profile_mode eq 0) ? $pivot_minus - int($log_base ** $window_end[$i]) + 1 : $pivot_minus - $window_end[$i] - $standard_profile_mode_half_window_size;
	 $tmp_end = ($standard_profile_mode eq 0) ? $pivot_minus : $pivot_minus - $window_end[$i] + $standard_profile_mode_half_window_size;
	 print TMP_LOCATION "$chr\t$coordinate\t$tmp_start\t$tmp_end\n";

	 $coordinate = ($start <= $end) ? $i : -$i;
	 $tmp_start = ($standard_profile_mode eq 0) ? $pivot_plus : $pivot_plus + $window_end[$i] - $standard_profile_mode_half_window_size;
	 $tmp_end = ($standard_profile_mode eq 0) ? $pivot_plus + int($log_base ** $window_end[$i]) - 1 : $pivot_plus + $window_end[$i] + $standard_profile_mode_half_window_size;
	 print TMP_LOCATION "$chr\t$coordinate\t$tmp_start\t$tmp_end\n";
      }

      # Process the location into the profile
      close(TMP_LOCATION);
      my $stats_location_file_by_chr = $tmp_working_dir. "/stats_chr_" . $chr;
      my $output_str = `compute_location_stats.pl $tmp_location_file -f $stats_location_file_by_chr -fv -q -showall -adjusted $adjusted -p $significant_numbers | sort -k 2 -n | chr_length.pl | modify_column.pl -c 5 -dc 0 | cut.pl -f 3,6,7 | transpose.pl -q`;
      chomp($output_str);

      my @ll = split(/\n/,$output_str); chomp($ll[0]); chomp($ll[1]); chomp($ll[2]);
      my @r1 = split(/\t/,$ll[0]); my @r2 = split(/\t/,$ll[1]); my @r3 = split(/\t/,$ll[2]);
      for (my $i=0; $i<@r2-1; $i++)
      {
	 if ($r2[$i] < $min_stat_percent_threshold)
	 {
	    $r3[$i] = "";
	 }
      }

      print OUTPUT_PROFILES "$id"; for (my $i=0; $i<@r3; $i++) {print OUTPUT_PROFILES "\t$r3[$i]";} print OUTPUT_PROFILES "\n";
   }
   close(LOCATION_FILE_REF);
   close(STATS_LOCATION_FILE);
   close (OUTPUT_PROFILES);

   exit; # because we are in an internal run (job in a queue, and we dont want to remove files, etc.)
}

#-------------------------------------------------------------------------------------------#
# Print the output file (log-scale data, oriented)
#-------------------------------------------------------------------------------------------#
# We cap the output profiles file by a header line, write it in a tmp file (used later for correlations), and then output it to STDOUT.

my $tmp_output_profiles_file2 = (length($load_mat) > 0) ? $load_mat : $tmp_working_dir. "/tmp_output_profiles2.tab";

if (length($load_mat) == 0)
{
   print STDERR "Print profiles...\n";
   open(OUTPUT_PROFILES2, ">$tmp_output_profiles_file2") or die("Could not open tmp file for writing '$tmp_output_profiles_file2'.\n");
   my $k = (@window_end-1)+@window_end; # num of data points (middle point is counted only once here)
   my $tmp_coordinate_log = 0;
   open(OUTPUT_PROFILES, "$tmp_output_profiles_file") or die("Could not open tmp file for reading '$tmp_output_profiles_file'.\n");
   print OUTPUT_PROFILES2 "Id";
   for (my $i=0; $i<int($k/2); $i++) {$tmp_coordinate_log = -$window_end[(@window_end-1)-$i]; print OUTPUT_PROFILES2 "\t$tmp_coordinate_log";}
   $tmp_coordinate_log = ($standard_profile_mode eq 0) ? "[-$window_end[0] $window_end[0]]" : $window_end[0];
   print OUTPUT_PROFILES2 "\t$tmp_coordinate_log"; my $tmp_j = int($k/2);
   for (my $i=$tmp_j+1; $i<$k; $i++) {$tmp_coordinate_log = $window_end[$i-$tmp_j]; print OUTPUT_PROFILES2 "\t$tmp_coordinate_log";} print OUTPUT_PROFILES2 "\n";
   if ($sym_mode)
   {
      my $tmp_ave_val0 = 0;
      my $tmp_ave_val1 = 0;
      my $tmp_ave_val2 = 0;
      while(my $l=<OUTPUT_PROFILES>)
      {
	 chomp($l);
	 my @r = split(/\t/,$l);
	 print OUTPUT_PROFILES2 "$r[0]";

	 for(my $i=0;$i<$k;$i++)
	 {
	    $tmp_ave_val0 = ($i<@r and length($r[$i+1]) > 0) ? $r[$i+1] : "";
	    $tmp_ave_val1 = ($i<@r and length($r[$k-$i]) > 0) ? $r[$k-$i] : "";
	    $tmp_ave_val2 = (length($tmp_ave_val0) > 0 and length($tmp_ave_val1) > 0) ? ($tmp_ave_val0+$tmp_ave_val1)/2 : (length($tmp_ave_val0) == 0 and length($tmp_ave_val1) == 0) ? "" : (length($tmp_ave_val0) > 0) ? $tmp_ave_val0 : $tmp_ave_val1;
	    print OUTPUT_PROFILES2 "\t$tmp_ave_val2";
	 }
	 print OUTPUT_PROFILES2 "\n";
      }
   }
   else
   {
      while(my $l=<OUTPUT_PROFILES>)
      {
	 chomp($l);
	 print OUTPUT_PROFILES2 "$l\n";
      }
   }
   close (OUTPUT_PROFILES);
   close (OUTPUT_PROFILES2);
   open(OUTPUT_PROFILES2, "$tmp_output_profiles_file2") or die("Could not open tmp file for reading '$tmp_output_profiles_file2'.\n");
   while(my $l=<OUTPUT_PROFILES2>) {chomp($l); print STDOUT "$l\n";}
   close (OUTPUT_PROFILES2);
}

## FROM HERE ON START WORKING THE QUEUE

if ($qmin > 0 and $run_statistics == 0)
{
   print STDERR "Compute statistics...\n";
   my $tmp_output_profiles_file3 = (length($load_mat) > 0) ? "$current_dir/$load_mat" : "tmp_output_profiles2.tab";
   my $tmp_commands_file = $tmp_working_dir. "/tmp_commands";
   open(COMMANDS, ">$tmp_commands_file") or die("Could not open tmp file for writing '$tmp_commands_file'.\n");
   if ($standard_profile_mode eq 0)
   {
      print COMMANDS "q.pl 'compute_location_log_scale_ave_stats.pl $tmp_location_file_ref -f $stats_location_file -sym $sym_mode -corr $correlations_file -corr_sim $correlations_num_sim -log_base $log_base -log_from $log_from -log_to $log_to -log_res $log_res -align_by $align_by -output_prefix $current_dir/$output_prefix -ir $r -auc $auc_file -ave $ave_file -hist $hist_num_bins -mstat $min_stat_percent_threshold -figmat $arg_figure_format -qmin $qmin -qmax $qmax -qnlines $qnlines -load_mat $tmp_output_profiles_file3 -run_statistics;';\n";
   }
   else
   {
      print COMMANDS "q.pl 'compute_location_log_scale_ave_stats.pl $tmp_location_file_ref -f $stats_location_file -sym $sym_mode -corr $correlations_file -corr_sim $correlations_num_sim -log_base $log_base -prof $standard_profile_mode -log_res $log_res -align_by $align_by -output_prefix $current_dir/$output_prefix -ir $r -auc $auc_file -ave $ave_file -hist $hist_num_bins -mstat $min_stat_percent_threshold -figmat $arg_figure_format -qmin $qmin -qmax $qmax -qnlines $qnlines -load_mat $tmp_output_profiles_file3 -run_statistics;';\n";
   }
   close(COMMANDS);
   system("cd $tmp_working_dir; qp.pl -f $tmp_commands_file -min_t 0 -min_u 10000 -finish -manual -ping; cd $current_dir;");
}
else
{
   #-------------------------------------------------------------------------------------------#
   # Positional correlation profile
   #-------------------------------------------------------------------------------------------#
   my @profile_corr = ();
   my @profile_corr_pval = ();
   my @profile_corr_name = ();

   if (length($correlations_file) > 0)
   {
      my $tmp_pairs_file_for_correlations = $tmp_working_dir. "/tmp_pairs_file_for_correlations.tab";
      my $num_of_correlations = `cat $tmp_input_correlations_file | tabsize.pl -c`; chomp($num_of_correlations);
      $num_of_correlations = $num_of_correlations - 1;
      my $k = (@window_end-1)+@window_end; # num of data points (middle point is counted only once here)
      my $tmp_coordinate_log = 0;

      for (my $c=0; $c<$num_of_correlations; $c++)
      {
	 my $corr_column = $c+2;
	 my $corr_name = `head $tmp_input_correlations_file -n1 | cut -f $corr_column`; chomp($corr_name);

	 # Prepare the pairs file for: compute_pairwise_stats.pl (the '-p' flag)
	 open(TMP_PAIRS_FILE_FOR_CORR, ">$tmp_pairs_file_for_correlations") or die("Could not open the tmp pairs file for correlations for writing '$tmp_pairs_file_for_correlations'.\n");
	 for (my $i=0; $i<int($k/2); $i++) {$tmp_coordinate_log = -$window_end[(@window_end-1)-$i]; print TMP_PAIRS_FILE_FOR_CORR "$corr_name\t$tmp_coordinate_log\n";}
	 $tmp_coordinate_log = ($standard_profile_mode eq 0) ? "[-$window_end[0] $window_end[0]]" : $window_end[0]; print TMP_PAIRS_FILE_FOR_CORR "$corr_name\t$tmp_coordinate_log\n"; my $tmp_j = int($k/2);
	 for (my $i=$tmp_j+1; $i<$k; $i++) {$tmp_coordinate_log = $window_end[$i-$tmp_j]; print TMP_PAIRS_FILE_FOR_CORR "$corr_name\t$tmp_coordinate_log\n";}
	 close(TMP_PAIRS_FILE_FOR_CORR);

	 my $res_corr_str = `cat $tmp_input_correlations_file | cut -f1,$corr_column | join.pl -1 1 -2 1 $tmp_output_profiles_file2 - | cut -f 2- | transpose.pl -q | compute_pairwise_stats.pl -p $tmp_pairs_file_for_correlations -s pearson -sim $correlations_num_sim -two | cut -f 3,7 | transpose.pl -q`;

	 my @tmp_res_corr = split(/\n/,$res_corr_str);
	 chomp($tmp_res_corr[0]);
	 chomp($tmp_res_corr[1]);
	 my @tmp_res_corr0 = split(/\t/,$tmp_res_corr[0]);
	 my @tmp_res_corr1 = split(/\t/,$tmp_res_corr[1]);

	 $profile_corr[$c]=\@tmp_res_corr0;
	 $profile_corr_pval[$c]=\@tmp_res_corr1;
	 $profile_corr_name[$c]=$corr_name;
      }
   }

   #-------------------------------------------------------------------------------------------#
   # Positional AUC profile
   #-------------------------------------------------------------------------------------------#
   my @profile_auc = ();
   my @profile_auc_name = ();

   if (length($auc_file) > 0)
   {
      my $num_of_aucs = `cat $tmp_input_auc_file | tabsize.pl -c`; chomp($num_of_aucs);
      $num_of_aucs = $num_of_aucs - 1;
      my $k = (@window_end-1)+@window_end; # num of data points (middle point is counted only once here)

      for (my $c=0; $c<$num_of_aucs; $c++)
      {
	 my $auc_column = $c+2;
	 my $auc_name = `head $tmp_input_auc_file -n1 | cut -f $auc_column`; chomp($auc_name);
	 my $tmp_working_auc_file = $tmp_working_dir . "/tmp_working_auc_file.tab";
	 system("cat $tmp_input_auc_file | cut -f1,$auc_column | join.pl -1 1 -2 1 - $tmp_output_profiles_file2 | cut -f 2- | body.pl 2 -1 > $tmp_working_auc_file;");
	 my $tmp_working_auc_file2 = $tmp_working_dir . "/tmp_working_auc_file2.tab";
	 my @tmp_profile_auc = ();

	 for (my $c2=0; $c2<$k; $c2++)
	 {
	    my $auc_column2 = $c2+2;
	    my $tmp_for_res_auc_str = system("cat $tmp_working_auc_file | cut -f 1,$auc_column2 | sort -k 2 -nr -k1 -n | uniq -c | sed -r 's/ +/\t/g' | cut -f 2- > $tmp_working_auc_file2;");
	    # Compute AUC
	    my $tmp_positive_group_size = 0;
	    my $tmp_negative_group_size = 0;
	    my $tmp_auc = 0;
	    my $tmp_v = 0;
	    my $tmp_val_pos = 0;
	    my $tmp_dup_pos = 0;
	    open(WORKING_FILE_FOR_AUC2, "$tmp_working_auc_file2") or die("Could not open tmp file for reading '$tmp_working_auc_file2'.\n");
	    while(my $l = <WORKING_FILE_FOR_AUC2>)
	    {
	       chomp($l);
	       my @r = split(/\t/,$l);
	       if (length($l) > 0 and length($r[1]) > 0 and $r[1] == 1)
	       {
		  $tmp_v = $tmp_v + $r[0];
		  $tmp_positive_group_size = $tmp_positive_group_size + $r[0];
		  $tmp_val_pos = $r[2];
		  $tmp_dup_pos = $r[0];
	       }
	       elsif (length($l) > 0 and length($r[1]) > 0 and $r[1] == -1)
	       {
		  $tmp_auc = $tmp_auc + $tmp_v*$r[0];
		  $tmp_negative_group_size = $tmp_negative_group_size + $r[0];
		  # Tie case
		  if ($r[2] == $tmp_val_pos)
		  {
		     $tmp_auc = $tmp_auc - ($tmp_dup_pos*$r[0]/2);
		  }
	       }
	    }
	    close(WORKING_FILE_FOR_AUC2);
	    $tmp_profile_auc[$c2] = ($tmp_positive_group_size*$tmp_negative_group_size > 0 and
				     $tmp_auc <= ($tmp_positive_group_size*$tmp_negative_group_size) and
				     $tmp_auc >= 0) ? $tmp_auc/($tmp_positive_group_size*$tmp_negative_group_size) : -1;
	 }
	 $profile_auc[$c]=\@tmp_profile_auc;
	 $profile_auc_name[$c] = $auc_name;
      }
   }

   #-------------------------------------------------------------------------------------------#
   # Average+Std profiles (by groups)
   #-------------------------------------------------------------------------------------------#
   my @profile_ave = ();
   my @profile_std = ();
   my @profile_ave_std_name = ();

   if (length($ave_file) > 0)
   {
      my $num_of_aves = `cat $tmp_input_ave_file | tabsize.pl -c`; chomp($num_of_aves);
      $num_of_aves = $num_of_aves - 1;
      my $k = (@window_end-1)+@window_end; # num of data points (middle point is counted only once here)

      for (my $c=0; $c<$num_of_aves; $c++)
      {
	 my $ave_column = $c+2;
	 my $ave_name = `head $tmp_input_ave_file -n1 | cut -f $ave_column`; chomp($ave_name);
	 my $tmp_working_ave_file = $tmp_working_dir . "/tmp_working_ave_file.tab";
	 system("cat $tmp_input_ave_file | cut -f1,$ave_column | filter.pl -c 1 -estr 1 -skip 1 -q | cut -f1 | join.pl -1 1 -2 1 - $tmp_output_profiles_file2 | cut -f 2- | body.pl 2 -1 > $tmp_working_ave_file;");

	 my @tmp_profile_counter = ();
	 my @tmp_profile_ave = ();
	 my @tmp_profile_std = ();

	 for (my $i=0; $i<$k; $i++)
	 {
	    $tmp_profile_counter[$i] = 0;
	    $tmp_profile_ave[$i] = 0;
	    $tmp_profile_std[$i] = 0;
	 }

	 open(WORKING_FILE_FOR_AVE, "$tmp_working_ave_file") or die("Could not open tmp file for reading '$tmp_working_ave_file'.\n");
	 my $c2 = 0;
	 my $mean = 0;
	 my $std2 = 0;
	 my $v = 0;
	 my $a = 0;
	 while(my $l = <WORKING_FILE_FOR_AVE>)
	 {
	    chomp($l);
	    my @r = split(/\t/,$l);
	    for (my $i=0; $i<@r; $i++)
	    {
	       if (length($r[$i]) > 0)
	       {
		  $c2 = $tmp_profile_counter[$i];
		  $mean = $tmp_profile_ave[$i];
		  $std2 = $tmp_profile_std[$i];
		  $v = $r[$i];
		  $a = $c2/($c2+1);

		  $tmp_profile_counter[$i] = $c2+1;
		  $tmp_profile_ave[$i] = $a*$mean + (1-$a)*$v;
		  $tmp_profile_std[$i] = $a*$std2 + (1-$a)*$v*$v + $a*$mean*$mean - $tmp_profile_ave[$i]*$tmp_profile_ave[$i];
	       }
	    }
	 }
	 close (WORKING_FILE_FOR_AVE);
	 # From Variance to STD
	 for (my $i=0; $i<@tmp_profile_std; $i++)
	 {
	    $v = $tmp_profile_std[$i];
	    $tmp_profile_std[$i] = sqrt($v);
	 }

	 $profile_ave[$c]=\@tmp_profile_ave;
	 $profile_std[$c]=\@tmp_profile_std;
	 $profile_ave_std_name[$c] = $ave_name;
      }
   }

   #-------------------------------------------------------------------------------------------#
   # Average+Std profiles (the default profile for all locations)
   #-------------------------------------------------------------------------------------------#
   my @profile_all_counter = ();
   my @profile_all_ave = ();
   my @profile_all_std = ();
   for (my $i=-(@window_end-1); $i<@window_end; $i++)
   {
      push(@profile_all_counter,0);
      push(@profile_all_ave,0);
      push(@profile_all_std,0);
   }
   open(OUTPUT_PROFILES, "$tmp_output_profiles_file2") or die("Could not open tmp file for reading '$tmp_output_profiles_file2'.\n");
   my $header = <OUTPUT_PROFILES>; #just remove the header row
   my $c = 0;
   my $mean = 0;
   my $std2 = 0;
   my $v = 0;
   my $a = 0;
   while(my $l=<OUTPUT_PROFILES>)
   {
      chomp($l);
      my @r = split(/\t/,$l);
      for (my $i=1; $i<@r; $i++)
      {
	 if (length($r[$i]) > 0)
	 {
	    $c = $profile_all_counter[$i-1];
	    $mean = $profile_all_ave[$i-1];
	    $std2 = $profile_all_std[$i-1];
	    $v = $r[$i];
	    $a = $c/($c+1);

	    $profile_all_counter[$i-1] = $c+1;
	    $profile_all_ave[$i-1] = $a*$mean + (1-$a)*$v;
	    $profile_all_std[$i-1] = $a*$std2 + (1-$a)*$v*$v + $a*$mean*$mean - $profile_all_ave[$i-1]*$profile_all_ave[$i-1];
	 }
      }
   }
   close (OUTPUT_PROFILES);
   # From Variance to STD
   for (my $i=0; $i<@profile_all_std; $i++)
   {
      $v = $profile_all_std[$i];
      $profile_all_std[$i] = ((length($v)) > 0 and ($v > 0)) ? sqrt($v) : ((length($v)) > 0 and ($v == 0)) ? 0 : "";
   }

   #-------------------------------------------------------------------------------------------#
   # Histograms
   #-------------------------------------------------------------------------------------------#
   my @histogram_name = ();

   if ($dont_calc_histograms == 0)
   {
      my $tmp_working_hist_file = $tmp_working_dir . "/tmp_working_hist_file.tab";
      my $tmp_working_hist_file2 = $tmp_working_dir . "/tmp_working_hist_file2.tab";

      #All locations
      system("cat $tmp_output_profiles_file2 | cut -f 2- | body.pl 2 -1 > $tmp_working_hist_file;");
      system("echo -n > $tmp_working_hist_file2;");
      my $num_of_histograms = `cat $tmp_working_hist_file | tabsize.pl -c`;
      my $tmp_hist_name = "All";
      $histogram_name[0] = $tmp_hist_name;
      for (my $c2=0; $c2<$num_of_histograms; $c2++)
      {
	 my $hist_column = $c2+1;
	 my $command = "cat $tmp_working_hist_file | cut -f $hist_column | filter.pl -c 0 -ne -q | histogram.pl -c 0 -min auto -max auto -bins $hist_num_bins -empty | cut -f 2,4,5 | sed 's/\\[//g' | sed 's/\\]//g' | sed 's/ /\\t/g' | add_column.pl -ave 0,1 -sn 10 | cut.pl -f 5,3,4 | transpose.pl -q >> $tmp_working_hist_file2;";
	 system($command);
      }

      my $tmp_output_hist_file = $output_prefix . "_Hist_$tmp_hist_name.tab";
      system("cat $tmp_working_hist_file2 | transpose.pl -q > $tmp_output_hist_file;");

      #Groups (defined by the -ave flag)
      if (length($ave_file) > 0)
      {
	 my $num_of_aves = `cat $tmp_input_ave_file | tabsize.pl -c`; chomp($num_of_aves);
	 $num_of_aves = $num_of_aves - 1;
	 my $k = (@window_end-1)+@window_end; # num of data points (middle point is counted only once here)

	 for (my $c=0; $c<$num_of_aves; $c++)
	 {
	    my $ave_column = $c+2;
	    my $ave_name = `head $tmp_input_ave_file -n1 | cut -f $ave_column`; chomp($ave_name);
	    my $command = "cat $tmp_input_ave_file | cut -f1,$ave_column | filter.pl -c 1 -estr 1 -skip 1 -q | cut -f1 | join.pl -1 1 -2 1 - $tmp_output_profiles_file2 | cut -f 2- | body.pl 2 -1 > $tmp_working_hist_file;";
	    system($command);

	    system("echo -n > $tmp_working_hist_file2;");
	    $num_of_histograms = `cat $tmp_working_hist_file | tabsize.pl -c`;
	    $tmp_hist_name = $ave_name;
	    $histogram_name[$c+1] = $tmp_hist_name;
	    for (my $c2=0; $c2<$num_of_histograms; $c2++)
	    {
	       my $hist_column = $c2+1;
	       $command = "cat $tmp_working_hist_file | cut -f $hist_column | filter.pl -c 0 -ne -q | histogram.pl -c 0 -min auto -max auto -bins $hist_num_bins -empty | cut -f 2,4,5 | sed 's/\\[//g' | sed 's/\\]//g' | sed 's/ /\\t/g' | add_column.pl -ave 0,1 -sn 10 | cut.pl -f 5,3,4 | transpose.pl -q >> $tmp_working_hist_file2";
	       system($command);
	    }
	    my $tmp_output_hist_file = $output_prefix . "_Hist_$tmp_hist_name.tab";
	    $command = "cat $tmp_working_hist_file2 | transpose.pl -q > $tmp_output_hist_file;";
	    system($command);
	 }
      }
   }

   #-------------------------------------------------------------------------------------------#
   # Output profile stats (ave, std, corr, corr-pval, auc,...)
   #-------------------------------------------------------------------------------------------#
   my $output_ave_profiles_file = $output_prefix . "_profile_stats.tab";
   open(OUTPUT_AVE_PROFILES, ">$output_ave_profiles_file") or die("Could not open file for writing '$output_ave_profiles_file'.\n");

   if ($standard_profile_mode eq 0)
   {
      print OUTPUT_AVE_PROFILES "X\tXlog\tAve\tStd";
   }
   else
   {
      print OUTPUT_AVE_PROFILES "X\tXindex\tAve\tStd";
   }
   for (my $c=0; $c<@profile_ave_std_name; $c++)
   {
      print OUTPUT_AVE_PROFILES "\t$profile_ave_std_name[$c]:Ave\t$profile_ave_std_name[$c]:Std";
   }
   for (my $c=0; $c<@profile_corr_name; $c++)
   {
      print OUTPUT_AVE_PROFILES "\t$profile_corr_name[$c]:Corr\t$profile_corr_name[$c]:CorrPval";
   }
   for (my $c=0; $c<@profile_auc_name; $c++)
   {
      print OUTPUT_AVE_PROFILES "\t$profile_auc_name[$c]:AUC";
   }
   print OUTPUT_AVE_PROFILES "\n";

   my $tmp_coordinate = 0;
   my $tmp_coordinate_log = 0;
   for (my $i=0; $i<int(@profile_all_ave/2); $i++)
   {
      $tmp_coordinate = ($standard_profile_mode eq 0) ? -int($log_base ** $window_end[(@window_end-1)-$i]) : -$window_end[(@window_end-1)-$i];
      $tmp_coordinate_log = ($standard_profile_mode eq 0) ? -$window_end[(@window_end-1)-$i] : -((@window_end-1)-$i);
      print OUTPUT_AVE_PROFILES "$tmp_coordinate\t$tmp_coordinate_log\t$profile_all_ave[$i]\t$profile_all_std[$i]";
      for (my $c=0; $c<@profile_ave_std_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_ave[$c][$i]\t$profile_std[$c][$i]";
      }
      for (my $c=0; $c<@profile_corr_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_corr[$c][$i]\t$profile_corr_pval[$c][$i]";
      }
      for (my $c=0; $c<@profile_auc_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_auc[$c][$i]";
      }
      print OUTPUT_AVE_PROFILES "\n";
   }

   # Middle point is replicated to the -/+ boundaries of the interval it represents (only if the interval > 1 and not in '-prof' mode)
   $tmp_coordinate = ($standard_profile_mode eq 0) ? -int($log_base ** $window_end[0]) : $window_end[0];
   $tmp_coordinate_log = (($standard_profile_mode eq 0) and ($window_end[0] > 0)) ? -$window_end[0] : ($standard_profile_mode eq 0) ? $window_end[0] : 0;
   print OUTPUT_AVE_PROFILES "$tmp_coordinate\t$tmp_coordinate_log\t$profile_all_ave[int(@profile_all_ave/2)]\t$profile_all_std[int(@profile_all_ave/2)]";
   for (my $c=0; $c<@profile_ave_std_name; $c++)
   {
      print OUTPUT_AVE_PROFILES "\t$profile_ave[$c][int(@profile_all_ave/2)]\t$profile_std[$c][int(@profile_all_ave/2)]";
   }
   for (my $c=0; $c<@profile_corr_name; $c++)
   {
      print OUTPUT_AVE_PROFILES "\t$profile_corr[$c][int(@profile_all_ave/2)]\t$profile_corr_pval[$c][int(@profile_all_ave/2)]";
   }
   for (my $c=0; $c<@profile_auc_name; $c++)
   {
      print OUTPUT_AVE_PROFILES "\t$profile_auc[$c][int(@profile_all_ave/2)]";
   }
   print OUTPUT_AVE_PROFILES "\n";

   if (($standard_profile_mode eq 0) and ($window_end[0] > 0))
   {
      $tmp_coordinate = int($log_base ** $window_end[0]);
      $tmp_coordinate_log = $window_end[0];
      print OUTPUT_AVE_PROFILES "$tmp_coordinate\t$tmp_coordinate_log\t$profile_all_ave[int(@profile_all_ave/2)]\t$profile_all_std[int(@profile_all_ave/2)]";
      for (my $c=0; $c<@profile_ave_std_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_ave[$c][int(@profile_all_ave/2)]\t$profile_std[$c][int(@profile_all_ave/2)]";
      }
      for (my $c=0; $c<@profile_corr_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_corr[$c][int(@profile_all_ave/2)]\t$profile_corr_pval[$c][int(@profile_all_ave/2)]";
      }
      for (my $c=0; $c<@profile_auc_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_auc[$c][int(@profile_all_ave/2)]";
      }
      print OUTPUT_AVE_PROFILES "\n";
   }

   my $tmp_j = int(@profile_all_ave/2);
   for (my $i=$tmp_j+1; $i<@profile_all_ave; $i++)
   {
      $tmp_coordinate = ($standard_profile_mode eq 0) ? int($log_base ** $window_end[$i-$tmp_j]) : $window_end[$i-$tmp_j];
      $tmp_coordinate_log = ($standard_profile_mode eq 0) ? $window_end[$i-$tmp_j] : $i-$tmp_j;
      print OUTPUT_AVE_PROFILES "$tmp_coordinate\t$tmp_coordinate_log\t$profile_all_ave[$i]\t$profile_all_std[$i]";
      for (my $c=0; $c<@profile_ave_std_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_ave[$c][$i]\t$profile_std[$c][$i]";
      }
      for (my $c=0; $c<@profile_corr_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_corr[$c][$i]\t$profile_corr_pval[$c][$i]";
      }
      for (my $c=0; $c<@profile_auc_name; $c++)
      {
	 print OUTPUT_AVE_PROFILES "\t$profile_auc[$c][$i]";
      }
      print OUTPUT_AVE_PROFILES "\n";
   }
   close (OUTPUT_AVE_PROFILES);

   #-------------------------------------------------------------------------------------------#
   # Matlab plots
   #-------------------------------------------------------------------------------------------#
   my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
   my $mfile = "fig_for_compute_location_log_scale_ave_stats";
   my $matlabPath = "matlab";
   my $arg_matrix_file_name = $tmp_working_dir . "/tmp_working_matlab_file.tab";

   my $arg_plot_type = 0;
   my $arg_title = 0;
   my $arg_figure_name = 0;
   my $arg_plot_xlabel = 0;
   my $arg_plot_ylabel = 0;
   my $params = 0;
   my $command = 0;
   my $run_matlab = 0;
   my $column_counter = 5;

   # Ave+Std: all
   system("cat $output_ave_profiles_file | cut.pl -f 1-4 > $arg_matrix_file_name;");
   $arg_plot_type = ($standard_profile_mode eq 0) ? 1 : 1.1;
   $arg_title = "Ave+Std:All";
   $arg_figure_name = $output_prefix . "_AveStd_All";
   $arg_plot_xlabel = "";
   $arg_plot_ylabel = "";
   $params = "(\'$arg_matrix_file_name\',$arg_plot_type,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'$arg_plot_xlabel\',\'$arg_plot_ylabel\')";
   $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";
   print STDERR "Calling Matlab with: $command\n"; #DEBUG
   $run_matlab = system($command);
   while ($run_matlab != 0) {sleep 10; $run_matlab = system($command);} sleep 10;

   # Hist: all + groups
   for (my $i=0; $i<@histogram_name; $i++)
   {
      my $tmp_hist_name = $histogram_name[$i];
      $arg_matrix_file_name = $output_prefix . "_Hist_$tmp_hist_name.tab";
      $arg_plot_type = ($standard_profile_mode eq 0) ? 5 : 5.1;
      $arg_title = "Hist:$tmp_hist_name";
      $arg_figure_name = $output_prefix . "_Hist_$tmp_hist_name";
      $arg_plot_xlabel = "";
      $arg_plot_ylabel = "";
      $params = "(\'$arg_matrix_file_name\',$arg_plot_type,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'$arg_plot_xlabel\',\'$arg_plot_ylabel\')";
      $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";
      print STDERR "Calling Matlab with: $command\n"; #DEBUG
      $run_matlab = system($command);
      while ($run_matlab != 0) {sleep 10; $run_matlab = system($command);} sleep 10;
   }

   # Ave+Std: groups
   for (my $c=0; $c<@profile_ave_std_name; $c++)
   {
      my $column_counter1 = $column_counter;
      my $column_counter2 = $column_counter1+1;
      system("cat $output_ave_profiles_file | cut.pl -f 1,2,$column_counter1,$column_counter2 > $arg_matrix_file_name;");
      $arg_plot_type = ($standard_profile_mode eq 0) ? 1 : 1.1;;
      $arg_title = "Ave+Std:$profile_ave_std_name[$c]";
      $arg_figure_name = $output_prefix . "_AveStd_$profile_ave_std_name[$c]";
      $arg_plot_xlabel = "";
      $arg_plot_ylabel = "";
      $params = "(\'$arg_matrix_file_name\',$arg_plot_type,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'$arg_plot_xlabel\',\'$arg_plot_ylabel\')";
      $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";
      print STDERR "Calling Matlab with: $command\n"; #DEBUG
      $run_matlab = system($command);
      while ($run_matlab != 0) {sleep 10; $run_matlab = system($command);} sleep 10;
      $column_counter = $column_counter + 2;
   }
   for (my $c=0; $c<@profile_corr_name; $c++)
   {
      my $column_counter1 = $column_counter;
      my $column_counter2 = $column_counter1+1;
      system("cat $output_ave_profiles_file | cut.pl -f 1,2,$column_counter1,$column_counter2 > $arg_matrix_file_name;");
      $arg_plot_type = ($standard_profile_mode eq 0) ? 2 : 2.1;
      $arg_title = "Corr+Pval:$profile_corr_name[$c]";
      $arg_figure_name = $output_prefix . "_CorrPval_$profile_corr_name[$c]";
      $arg_plot_xlabel = "";
      $arg_plot_ylabel = "";
      $params = "(\'$arg_matrix_file_name\',$arg_plot_type,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'$arg_plot_xlabel\',\'$arg_plot_ylabel\')";
      $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";
      print STDERR "Calling Matlab with: $command\n"; #DEBUG
      $run_matlab = system($command);
      while ($run_matlab != 0) {sleep 10; $run_matlab = system($command);} sleep 10;
      $column_counter = $column_counter + 2;
   }
   for (my $c=0; $c<@profile_auc_name; $c++)
   {
      system("cat $output_ave_profiles_file | cut.pl -f 1,2,$column_counter > $arg_matrix_file_name;");
      $arg_plot_type = ($standard_profile_mode eq 0) ? 3 : 3.1;
      $arg_title = "AUC:$profile_auc_name[$c]";
      $arg_figure_name = $output_prefix . "_AUC_$profile_auc_name[$c]";
      $arg_plot_xlabel = "";
      $arg_plot_ylabel = "";
      $params = "(\'$arg_matrix_file_name\',$arg_plot_type,\'$arg_title\',\'$arg_figure_name\',\'$arg_figure_format\',\'$arg_plot_xlabel\',\'$arg_plot_ylabel\')";
      $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";
      print STDERR "Calling Matlab with: $command\n"; #DEBUG
      $run_matlab = system($command);
      while ($run_matlab != 0) {sleep 10; $run_matlab = system($command);} sleep 10;
      $column_counter = $column_counter + 1;
   }

   exit; # Internal run (queue)
}

#-------------------------------------------------------------------------------------------#
# End (remove temporary files, etc.)
#-------------------------------------------------------------------------------------------#

system("/bin/rm -rf $tmp_working_dir");

END:

__DATA__

compute_location_log_scale_ave_stats.pl <location file>

   Takes a CHR file format location file and computes the log scale average profile with respect to a CHV file format location file (the statistics file).
   Instead of the log scale profile, can also calculate standard profiles (see '-prof') or total region averages (see '-align_by a').

   Several statistics could be computed, including:

   (1) The average profile over all features, and for subsets with respect to a feature group membership file.
   (2) The positional correlation profile, with respect to a feature score file.
   (3) The positional AUC profile, with respect to a feature membership file for positive and negative groups.
   (4) Histograms of values per position over all, or subsets, of features.

   IMPORTANT:

   (1) The statistics (chv) file is assumed to be sorted by chromosome and then by start location (i.e. 1st key = 1st column, 2nd key = minimum of 3rd and 4th columns).
   (2) RUN THIS SCRIPT ONLY ON THE MASTER (because this cript, in its default behaviour, sends by itself jobs to the queue; unless using '-qmin 0')

   ************************************************************************************************************************

   Note: This script is still in developing stage, so please do not add changes without consulting me first -- Yair [Jan09]

   ************************************************************************************************************************

   -f <file>:             Statistics file to use as the input statistic. Assumes chv format.

   -log_base <num>:       The logarithm base to use (default: 10).
   -log_from <num>:       The (log_base) window half size of the middle point (default: 0).
   -log_to <num>:         The (log_base) maximal window half size (default: 7).
   -log_res <num>:        The (log_base) additive step between successful windows (default: 1).

                          E.g., '-log_base 10 -log_from 1 -log_to 2.5 -log_res 0.5' corresponds to the following vector of window averages:
                          [-(10^2.5) -1] [-(10^2) -1] [-(10^1.5) -1] [-(10^1) +(10^1)] [1 10^1.5] [1 10^2] [1 10^2.5]
                          When ploted, the middle point is duplicated to its edges, e.g., [-(10^1) +(10^1)] is represented by -(10^1) and +(10^1).

   -prof <v1,v2,v3>:      Calculate standard profiles instead of the default log-scale profiles, with a resolution of 'v1', half window size of 'v2' and profile max coordinate of 'v3'.

                          E.g., '-prof 10,5,30' calculate the following profile: [-30-5,-30+5] [-20-5,-20+5] [-10-5,-10+5] [0-5,0+5] [10-5,10+5] [20-5,20+5] [30-5,30+5]

   -align_by <str>:       Specify how to align the features (of location file), with str = <s/e/c/a> for aligning by the Start/End/Center coordinate,
                          or taking the average over All the original location coordinates (default: s).

   -sym:                  Forward and backward Profiles are averaged before taken statistics (default: off).

   -corr <file>:          For generating positional (Pearson) correlation profiles with the values specified in <file> (default: no file).
                          <file> should have one row header for the feature Id and the names of the correlated values
                          and each row should specify the feature id and values.
                          Multiple value columns can be given. Missing values are ignored. Names must be [A-Za-z0-9]+

                          E.g., Id     BindingStrength  TranscriptionalNoise BlaBla
                                Site1  3.4              -2                   2.5
                                Site2                    1                   0.7

   -corr_sim <int>:       The number of simulations to perform for the positional correlations by the '-corr' flag (default: 100)

   -auc <file>:           For generating AUC (discrimination) profiles between positive and negative sets specified in <file> (default: no file).
                          <file> should have one row header for the feature Id and the names of the discriminating groups
                          and each row should specify the feature id and association for groups, where 1/-1/0 means positive/negative/non.
                          Multiple columns (different groups to discriminate) can be given. Missing values are ignored (same as '0')
                          Names must be [A-Za-z0-9]+

                          E.g., Id     Functional_vs_NonFunational  HighNoise_vs_LowNoise
                                Site1  -1                           -1
                                Site2   1                            0
                                Site3   1                            1
                                Site4  -1                           -1

   -ave <file>:           For generating average (+std) profiles for particular groups specified in <file> (default: no file => show ave profile for all).
                          <file> should have one row header for the feature Id and the names of the groups
                          and each row should specify the feature id and '1' for group association.
                          Multiple columns (different groups to show) can be given. Missing values and non '1' values are ignored.
                          Names must be [A-Za-z0-9]+

   -hist <int>:           The number of bins for the histograms (default: 50)
                          ** 1 histogram is generated for all locations, and one for each group specified by '-ave'. **
                          ** <int>=0 is a special case in which no histogram is calculated. **

   -mstat <num>           The minimum percent of statistics (relative to a location) for taking the ave stats; otherwise print "" for the corresponding location (default: 0.4)

   -output_prefix <str>:  The file prefix for output figure and data files (default: log_scale_ave_stats).

   -figmat <fm>:          The figure(s) file format, where <fm> = ai/bmp/emf/eps/fig/jpg/m/pbm/pcx/pgm/png/ppm/tif (default: fig).

   -qmin <int>:           The minimum number of jobs to send to the queue (default: 0).
                        . ** <int>=0 is a special case to enforce no jobs are sent to the queue. When using this choice you can run this process itself through the queue. **

   -qmax <int>:           The maximum number of jobs to send in parallel to the queue (default: 140)
   -qnlines <int>:        The number of location lines in each parallel job sent to the queue (default: 30)

   -load_mat <file>       With this option a matrix given in <file> of the average profile per feature (which is the standard output of this procedure) is loaded and used for the statistics (e.g., -auc/-corr).
                          (default: no file is given, i.e., calculate the profile-per-feature matrix first).

   -p <int>:              The number of significant numbers taken for each data point (default: 3)

   -adjusted:             Assumes that missing data is zero, i.e., uses 'compute_location_stats.pl -adjusted' (default: ignore missing values)

