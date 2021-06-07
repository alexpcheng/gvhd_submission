#!/usr/bin/perl

use strict;
use Cwd 'abs_path';
use File::Temp;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $DB_STUB_EXT = ".db";

my %COMPUTE_MODE_OPTIONS = ("DumpStats" => 1, "PerPos" => 2, "PerFeature" => 3, "PerFeatures" => 4);

my $max_mega = get_arg("max_mb", 2048, \%args);
my $print = get_arg("print", 0, \%args);

my $t1 = get_arg("t1", "", \%args);
my $t2 = get_arg("t2", "", \%args);
my $n1 = get_arg("n1", "t1", \%args);
my $n2 = get_arg("n2", "t2", \%args);
my $v1 = get_arg("v1", 0, \%args);
my $v2 = get_arg("v2", 0, \%args);
my $no_overlaps1 = get_arg("no_overlaps1", 0, \%args);
my $no_overlaps2 = get_arg("no_overlaps2", 0, \%args);

my $load_to_db1 = get_arg("load_to_db1", 0, \%args);
my $load_to_db2 = get_arg("load_to_db2", 0, \%args);
my $dont_save1 = get_arg("dont_save1", 0, \%args);
my $dont_save2 = get_arg("dont_save2", 0, \%args);
my $db_output = get_arg("db_output", "", \%args);
my $chv_output = get_arg("chv_output", 0, \%args);
my $chv_max_values = get_arg("chv_max_values", -1, \%args);
my $precision = get_arg("p", 3, \%args);
my $uniquify = get_arg("uniquify", 0, \%args);
my $debug = get_arg("debug", 0, \%args);

my $db_host = get_arg("host", "mcluster02b", \%args);
my $db_user = get_arg("user", $ENV{USER}, \%args);
my $db_password = get_arg("password", "", \%args);
my $db_name = get_arg("db_name", "tracks", \%args);

my $function = get_arg("function", "", \%args);

my $extend_point = get_arg("extend_point", "", \%args);
my $add_upstream = get_arg("add_upstream", 0, \%args);
my $add_downstream = get_arg("add_downstream", 0, \%args);
my $bound_by_zero = get_arg("bound_by_zero", 0, \%args);

my $per_bp_func = get_arg("per_bp_func", "", \%args);
my $chromosome = get_arg("chromosome", "", \%args);
my $start = get_arg("start", "", \%args);
my $end = get_arg("end", "", \%args);
my $anchor = get_arg("anchor", "", \%args);

my $transform_func = get_arg("transform_func", "mean", \%args);
my $stdev = get_arg("stdev", 3, \%args);
my $window_half_size = get_arg("window_half_size", 0, \%args);
my $resolution = get_arg("resolution", 1, \%args);
my $min_cov = get_arg("min_cov", 1, \%args);
my $center_covered = get_arg("center_covered", 0, \%args);
my $orientation = get_arg("orientation", 0, \%args);
my $win_trans_output_all_feature = get_arg("output_whole_win_feature", 0, \%args);
my $div_by_result = get_arg("div_by_result", 0, \%args);

my $alignment_type = get_arg("alignment_type", "START", \%args);
my $align_point_win_extend_upstream = get_arg("align_point_win_extend_upstream", 0, \%args);
my $align_point_win_extend_downstream = get_arg("align_point_win_extend_downstream", 0, \%args);
my $match_orientation = get_arg("match_orientation", 0, \%args);
my $empty_value = get_arg("empty_value", "", \%args);
my $print_only_matches = get_arg("print_only_matches", 0, \%args);
my $sep_by_feature_type = get_arg("sep_by_feature_type", 0, \%args);
my $selected_feature_types = get_arg("selected_types", "", \%args);
my $compute_mode = get_arg("compute_mode", "DumpStats", \%args);
my $assume_zeros = get_arg("assume_zeros", 0, \%args);
my $symmetric_mode = get_arg("symmetric_mode", 0, \%args);
my $align_report_mode = get_arg("report", 0, \%args);

my $per_pos_func = get_arg("per_pos_func", "mean", \%args);
my $per_feature_func = get_arg("per_feature_func", "", \%args);
my $per_features_func = get_arg("per_features_func", "mean", \%args);

my $min_offset = get_arg("min_offset", 0, \%args);
my $max_offset = get_arg("max_offset", 0, \%args);
my $offset_step = get_arg("offset_step", 1, \%args);
my $sep_features_track = get_arg("sep_features_track", "", \%args);


my $pairs_func = get_arg("pairs_func", "PearsonCorr", \%args);
my $window_size = get_arg("window_size", 1, \%args);
my $window_step = get_arg("window_step", 1, \%args);

my $distance_mode = get_arg("distance_mode", "MIN_EDGES_DIST", \%args);
my $search_direction = get_arg("search_direction", "SearchAll", \%args);

my $allow_overlaps = get_arg("allow_overlaps", 0, \%args);
my $ignore_same_id = get_arg("ignore_same_id", 0, \%args);
my $min_distance = get_arg("min_distance", -1, \%args);
my $max_distance = get_arg("max_distance", -1, \%args);


my $cutoff = get_arg("cutoff", 0, \%args);
my $output_mode = get_arg("output_mode", "All", \%args);
my $min_region_len = get_arg("min_region_len", 0, \%args);
my $max_region_len = get_arg("max_region_len", 0, \%args);

my $min_intersection_size = get_arg("min_intersection_size", 1, \%args);
my $output_features = get_arg("output_features", 0, \%args);
my $intersection_types = get_arg("intersection_types", "", \%args);
my $select_single_feature_by = get_arg("select_single_feature_by", "", \%args);

my $threshold = get_arg("threshold", 0, \%args);

my $args = "";
my $t1_processed_args = "";
my $t2_processed_args = "";

my $with_values;
my $chr_field_len;
my $name_field_len;
my $types;

$args .= "-a TRACK_FUNCTION -function $function -precision $precision " . ($chv_output == 1 ? " -chv_output -chv_max_values $chv_max_values " : "") . ($uniquify == 1 ? " -uniquify " : "") . ($debug == 1 ? " -debug " : "");

if ($load_to_db1 == 0 and substr($t1, length($t1) - length($DB_STUB_EXT)) eq $DB_STUB_EXT)
{
   $load_to_db1 = 1;
}
if ($load_to_db2 == 0 and substr($t2, length($t2) - length($DB_STUB_EXT)) eq $DB_STUB_EXT)
{
   $load_to_db2 = 1;
}

if (($load_to_db1 == 1 or $load_to_db2 == 1) and (length($db_host) == 0 or length($db_user) == 0 or length($db_name) == 0))
{
   print STDERR "Error: Missing MySQL connection parameters\n";
   exit 1;
}

if ($t1 eq "-" and $t2 eq "-")
{
   print STDERR "Error: Only one track can be read from STDIN, not both.\n";
   exit 1;
}

if (length($t1) == 0)
{
   print STDERR "Error: First track was not supplied\n";
   exit 1;
}
else
{
   if ($t1 ne "-")
   {
      $t1 = abs_path ($t1);

      if ($load_to_db1 == 1 and substr($t1, length($t1) - length($DB_STUB_EXT)) ne $DB_STUB_EXT)
      {
         ($with_values, $chr_field_len, $name_field_len, $types) = &parse_file_for_db($t1, "");
	 $t1_processed_args = ($with_values == 1 ? "-with_values1 -types1 '$types' " : "") . "-chr_field_len1 $chr_field_len -name_field_len1 $name_field_len ";
      }
   }
   elsif ($load_to_db1 == 1)
   {
      my $tmp_fifo = abs_path (mktemp("/tmp/tmp_stdin_XXXXX")) . ($v1 == 1 ? ".chv" : ".chr");

      ($with_values, $chr_field_len, $name_field_len, $types) = &parse_file_for_db($t1, $tmp_fifo);
      $dont_save1 = 1;
      $t1 = $tmp_fifo;
   }

}

$args .= "-t1 $t1 -n1 $n1 " . ($v1 == 1 ? "-v1 " : "") . ($no_overlaps1 == 1 ? "-no_overlaps1 " : "") . ($load_to_db1 == 1 ? "-load_to_db1 -host $db_host -user $db_user -db_name $db_name " . (length($db_password) > 0 ? "-password $db_password " : "") . ($dont_save1 == 1 and substr($t1, length($t1) - length($DB_STUB_EXT)) ne $DB_STUB_EXT ? " -dont_save1 " : "" ) : "");

$args .= "$t1_processed_args ";

#if ($load_to_db == 1 and substr($t1, length($t1) - length($DB_STUB_EXT)) ne $DB_STUB_EXT)
#{
#   my ($with_values, $chr_field_len, $name_field_len, $types) = &parse_file_for_db($t1);
#   $args .= ($with_values == 1 ? "-with_values1 -types1 '$types' " : "") . "-chr_field_len1 $chr_field_len -name_field_len1 $name_field_len ";
#}

if (length($t2) > 0)
{
   $t2 = $t2 ne "-" ? abs_path($t2) : $t2;
   $args .= "-t2 $t2 -n2 $n2 " . ($load_to_db2 == 1 ? "-load_to_db2 " . ($load_to_db1 == 1 ? "" : "-host $db_host -user $db_user -db_name $db_name ") : "") .($v2 == 1 ? "-v2 " : "") . ($no_overlaps2 == 1 ? "-no_overlaps2 " : "") . ($dont_save2 == 1 and substr($t2, length($t2) - length($DB_STUB_EXT)) ne $DB_STUB_EXT ? " -dont_save2 " : "" );

   if ($load_to_db2 == 1 and substr($t2, length($t2) - length($DB_STUB_EXT)) ne $DB_STUB_EXT)
   {
      my ($with_values, $chr_field_len, $name_field_len, $types) = &parse_file_for_db($t2);
      $args .= ($with_values == 1 ? "-with_values2 -types2 '$types' " : "") . "-chr_field_len2 $chr_field_len -name_field_len2 $name_field_len ";
   }
}

if (($load_to_db1 == 1 or $load_to_db2 == 1) and length($db_output) > 0)
{
   $args .= " -db_output $db_output ";
}

if ($function eq "ExtendTrackFeatures")
{
   $args .= "-add_upstream $add_upstream -add_downstream $add_downstream " . ($bound_by_zero == 1 ? "-bound_by_zero " : "") . (length($extend_point) > 0 ? "-extend_point $extend_point " : "" );
}
elsif ($function eq "TrackToPerBp")
{
   $args .= "-per_bp_func " . (length($per_bp_func) > 0 ? $per_bp_func : "mean " );
}
elsif ($function eq "MovingWindowTransform")
{
   $args .= "-transform_func $transform_func " . ($transform_func eq "gaussian" ? "-stdev $stdev " : "") . "-window_half_size $window_half_size -resolution $resolution -min_cov $min_cov -orientation $orientation " . ($center_covered == 1 ? "-center_covered " : "") . ($win_trans_output_all_feature == 1 ? "-whole_win_feature " : "") . ($div_by_result == 1 ? "-div_by_result " : "") . (length($anchor) > 0 ? "-anchor_pos $anchor " : "") .(length($chromosome) > 0 ? "-chromosome $chromosome -start $start -end $end " : "") . ($assume_zeros == 1 ? "-assume_zeros " : "" );
}
elsif ($function eq "AlignStatsByFeatures")
{
   $args .= "-alignment_type $alignment_type -add_upstream $add_upstream -align_point_win_extend_upstream $align_point_win_extend_upstream -align_point_win_extend_downstream $align_point_win_extend_downstream -add_downstream $add_downstream -compute_mode $compute_mode " . ($assume_zeros == 1 ? "-assume_zeros " : "" ) . ($match_orientation == 1 ? "-match_orientation " : "" ) . (length($empty_value) > 0 ? "-empty_value $empty_value " : "" ) .  ($print_only_matches == 1 ? "-print_only_matches " : "" ) .(length($per_bp_func) > 0 ? "-per_bp_func $per_bp_func " : "") . (length($transform_func) > 0 ? "-transform_func $transform_func " . ($transform_func eq "gaussian" ? "-stdev $stdev " : "") . "-window_half_size $window_half_size -resolution $resolution -min_cov $min_cov " . ($center_covered == 1 ? "-center_covered " : "") : "") . ($sep_by_feature_type == 1 ? "-sep_by_feature_type " : "") . (length($selected_feature_types) > 0 ? "-selected_types \"" . $selected_feature_types . "\" " : "") . ($align_report_mode == 1 ? " -report " : "") ;

   if (!$COMPUTE_MODE_OPTIONS{$compute_mode})
   {
      print STDERR "Error: Unknown compute_mode for AlignStatsByFeatures ($compute_mode), see --help.\n";
      exit 1;
   }

   if ($compute_mode eq "PerPos")
   {
      $args .= "-per_pos_func $per_pos_func " . ($symmetric_mode == 1 ? "-symmetric_mode " : "");
   }
   elsif ($compute_mode eq "PerFeature")
   {
      if (length($per_feature_func) == 0)
      {
	 print STDERR "Error: In AlignStatsByFeatures function, must specify -per_feature_func in $compute_mode mode.\n";
	 exit 1;
      }
      $args .= "-per_feature_func $per_feature_func ";
   }
   elsif ($compute_mode eq "PerFeatures")
   {
      if (length($per_features_func) == 0)
      {
	 print STDERR "Error: In AlignStatsByFeatures function, must specify -per_features_func in $compute_mode mode.\n";
	 exit 1;
      }
      $args .= "-per_features_func $per_features_func " . (length($per_feature_func) == 0 ? "" : "-per_feature_func $per_feature_func ");
   }
}
elsif ($function eq "CorrelateTracks")
{
   $args .= "-min_offset $min_offset -max_offset $max_offset -offset_step $offset_step " . (length($sep_features_track) > 0 ? "-sep_features_track $sep_features_track " : "");
}
elsif ($function eq "PairsFunc")
{
   $args .= "-pairs_func $pairs_func -window_size $window_size -window_step $window_step -min_cov $min_cov -min_offset $min_offset -max_offset $max_offset -offset_step $offset_step ". (length($empty_value) > 0 ? "-empty_value $empty_value " : "" ) . (length($anchor) > 0 ? "-anchor_pos $anchor " : "");
}
elsif ($function eq "FindNearestFeature")
{
   if ($distance_mode eq "MIN_EDGES_DIST")
   {
      $distance_mode = "FeaturesDistanceMinEdgesDistMode";
   }
   elsif ($distance_mode eq "START_TO_START")
   {
      $distance_mode = "FeaturesDistanceStartsMode";
   }
   else
   {
      print STDERR "Error: Unknown distance_mode, available options are: MIN_EDGES_DIST, START_TO_START\n";
      exit 1;
   }
   
   if ($search_direction ne "SearchAll" and $search_direction ne "SearchUpstream" and $search_direction ne "SearchDownstream")
   {
      print STDERR "Error: Unknown search_direction, available options are: SearchUpstream, SearchDownstream, SearchAll.\n";
      exit 1;
   }
   $args .= "-distance_mode $distance_mode -search_direction $search_direction " .($allow_overlaps == 1 ? "-allow_overlaps " : "")  .($ignore_same_id == 1 ? "-ignore_same_id " : "") . ($min_distance >= 0 ? "-min_distance $min_distance " : "") . ($max_distance >= 0 ? "-max_distance $max_distance " : "") ;
}
elsif ($function eq "DiscretizeToRegions")
{
   my $output_mode_str = "";
   if ($output_mode eq "All" or $output_mode eq "BelowCutoff")
   {
      $output_mode_str = "-output_below_cutoff ";
   }
   if ($output_mode eq "All" or $output_mode eq "EqAboveCutoff")
   {
      $output_mode_str .= "-output_above_cutoff ";
   }
   if (length($output_mode_str) == 0)
   {
      print STDERR "Error: Unknown output mode ($output_mode) for DiscretizeToRegions function";
      exit 1;
   }
   $args .= "-cutoff $cutoff $output_mode_str -min_region_len $min_region_len -max_region_len $max_region_len ";
}
elsif ($function eq "IntersectTracks")
{
   $args .= "-min_intersection_size $min_intersection_size " .($ignore_same_id == 1 ? "-ignore_same_id " : "") . (length($selected_feature_types) > 0 ? "-selected_types \"" . $selected_feature_types . "\" " : "") . ($output_features ? ("-output_features " . (length($intersection_types) > 0 ? "-intersection_types \"$intersection_types\" " : "")) : "") . ($select_single_feature_by ? "-select_single_feature_by $select_single_feature_by " : "");
}
elsif ($function eq "GreedyFeatureSelection")
{
   $args .= "-threshold $threshold";
}
elsif ($function eq "FilterTrack")
{
   $args .= "";
}
elsif ($function ne "DeleteTrack" and $function ne "LoadTrack" and $function ne "Iterate1" and $function ne "Iterate2" and $function ne "IterateSingle"  and $function ne "Iterate1b")
{
   print STDERR "Error: Unknown function: $function\n";
   exit 1;
}

$ENV{DISPLAY} = ":27";

if ($print == 1)
{
   print ("$ENV{JAVA_HOME}/bin/java -Xmx${max_mega}m -jar $ENV{DEVELOP_HOME}/Genomica/Genomica.jar $ENV{GENOMICA_HOME}/Release/Samples/sample.tab $args");
}
else
{
   system ("$ENV{JAVA_HOME}/bin/java -Xmx${max_mega}m -jar $ENV{DEVELOP_HOME}/Genomica/Genomica.jar  $ENV{GENOMICA_HOME}/Release/Samples/sample.tab $args");
}

sub parse_file_for_db
{
   my ($chr_file, $pipe_file)  = @_;
   
   my $with_values = -1;
   my $chr_field_len = 0;
   my $name_field_len = 0;
   my %types_hash;
   my $n_types = 0;

   my @row;
   my $c = 1;

   if ($pipe_file and fork() == 0) 
   {
      # create fifo and exit

      system('mknod', $pipe_file, 'p') && die "can't create $pipe_file: $!";;
      print STDERR "Created $pipe_file\n";

      open (FIFO, ">$pipe_file") || die "can't write $pipe_file: $!";
      print STDERR "Opened $pipe_file\n";

      while (<STDIN>)
      {
	 print STDERR "Printing to fifo: $_";
	 print FIFO;
      }
      close FIFO;
      unlink $pipe_file;
      sleep 2;			# to avoid dup signals
      exit;
   }
   else
   {
      my $chr_file_ref;
      if ($chr_file eq "-")
      {
	 $chr_file_ref = \*STDIN;
      }
      else
      {
	 open (FILE, "<$chr_file");
	 $chr_file_ref = \*FILE;
      }
      
      while (<$chr_file_ref>)
      {
	 chop;
	 #print STDERR "Read line: $_\n";
	 @row = split(/\t/, $_, 6);

	 if ($#row == 3) 
	 {
	    if ($with_values == 1) 
	    {
	       print STDERR "Error: Line $c on file $chr_file has no values (only 4 columns) while previous lines had values\n";
	       if ($chr_file ne "-") { close FILE; }
	       exit 1;
	    }
	    else 
	    {
	       $with_values = 0;
	    }
	 }
	 elsif ($#row > 3) 
	 {
	    if ($with_values == 0) 
	    {
	       print STDERR "Error: Line $c on file $chr_file has values while previous lines had none\n";
	       if ($chr_file ne "-") { close FILE; }
	       exit 1;
	    }
	    else 
	    {
	       $with_values = 1;
	    }
	 }
	 else 
	 {
	    print STDERR "Error: Line $c on file $chr_file has only " . length(@row) . " columns\n";
	    if ($chr_file ne "-") { close FILE; }
	    exit 1;
	 }

	 $chr_field_len = length($row[0]) > $chr_field_len ? length($row[0]) : $chr_field_len;
	 $name_field_len = length($row[1]) > $name_field_len ? length($row[1]) : $name_field_len;
	 if ($with_values and length($types_hash{$row[4]}) == 0) 
	 {
	    $types_hash{$row[4]} = ++$n_types;
	 }

	 $c++;
      }

      if ($chr_file ne "-") { close FILE; }

      return ($with_values, $chr_field_len, $name_field_len, join (";", sort keys(%types_hash)));
   }
}



__DATA__

genomica_tracks_functions.pl 

    Wrapping of genomica tracks functions, calls the genomica jar file (see also http://genie.weizmann.ac.il/tracks_java_doc.html).

       -max_mb <num>: Maximum memory size to allocate for the process (default is 2048MB).

       Common parameters for all functions:
          -t1 <str>:     First track file name (may be - for standard input).
          -t2 <str>:     Second track file name (may be - for standard input).
          -n1 <str>:     First track name (default: t1)
          -n2 <str>:     Second track name (default: t2)
          -v1:           Specifies that first track is in vector format (chv).
          -v2:           Specifies that second track is in vector format (chv).
          -no_overlaps1: Specifies that first track has no overlapping features.
          -no_overlaps2: Specifies that second track has no overlapping features.

          -chv_output          :   Print output in chv format (available for these functions: TrackToPerBp, MovingWindowTransform).
          -chv_max_values <num>:   Allow maximum <num> values in each feature (relevent if -chv_output is specified).

          -p <num>:      Output number in precision of <num> (default: 3)
          -uniquify:     Uniquify the ids of the loaded tracks

          -function <str>: Name of the function to execute, can be one of the following:


       ExtendTrackFeatures (expects one input track)
       ===================
          -add_upstream <num>  : Positive means extend (add upstream) minus means to shorten
          -add_downstream <num>: Positive means extend (add downstream) minus means to shorten
          -bound_by_zero       : If specified, do not extend features below zero
          -extend_point <str>  : Extend a selected position in the feature (possible values: START, CENTER, END. Default is empty, meainng extending the feature edges).


       TrackToPerBp (t1 - Track to transform [Optional: t2 - filter t1 by t2 features)
       ============
          -per_bp_func <str>: Function to use for merging values in the same bp (options: mean, sum, min, max. Default is mean)


       MovingWindowTransform (t1 - Track to transform [Optional: t2 - filter t1 by t2 features)
       =====================
          -transform_func <str>:     Function to use for the trasformation (options (see details at "Transform Functions" section below): mean, sum, min, max, centerIsmin, centerIsmax, gaussian (which requires -stdev <n>, default: 3). Default is mean)
          -window_half_size <num>:   Number of basepairs to take around each basepair in the transformation
          -resolution <num>:         Step size on the input track (Default: 1)
          -min_cov <num>:            Minimum number of basepairs with data for a valid window position. 1 <= min_cov <= 2 * window_half_size + 1 (default is 1).
          -center_covered:           If specified, valid window position are only those in which the center basepair has data.
          -chromosome <str>:         Perform transformation only on given range (optional, ignores t2)
          -start <num>:              see -chromosome above (optional)
          -end <num>:                see -chromosome above (optional)
          -anchor <num>:             Anchor position of windows (optional, default - first valid window position)
          -orientation <1/-1/0>:     1      - take only 5' to 3' features
                                     '"-1"' - take only 3' to 5' features
                                     0      - take all features (default)
          -output_whole_win_feature: If specified, output feature of the window size instead of a single bp feature on the center bp.
          -div_by_result:            If specified, divide the center bp with the result of the transformation on its surrounding window.
          -assume_zeros:             Assume that locations without data in the window have a zero value


       AlignStatsByFeatures (t1 - features track, t2 - stats track)
       ====================
          -alignment_type <str>:                       Align features by (possible values: START (default), CENTER, END)
          -align_point_win_extend_upstream <num>:      If <num> is positive, extend feature alignment point (e.g. start, end ..) by <num> upstream. Otherwise, use the whole feature as the aligning region (default: 0)
          -align_point_win_extend_downstream <num>:    If <num> is positive, extend feature alignment point (e.g. start, end ..) by <num> downstream. Otherwise, use the whole feature as the aligning region (default: 0)
          -match_orientation:                          If specified, for each feature take only stats feature with matching orientation (default: false).
          -empty_value <str>:                          Put <str> in place of empty values (default: null, meaning an empty cell).
          -print_only_matches:                         Print only features that has matching stats (default: print all features).
	  -sep_by_feature_type:                        If specified, produce a separate output per feature type (default: false).
          -selected_types <str>:                       Semicolon (;) seperated list of features types to work on.

          -add_upstream <num>:                         Modify features track (see -add_upstream above, default: 0)
          -add_downstream <num>:                       Modify features track (see -add_downstream above, default: 0)

          -per_bp_func <str>:                          To use on stats track if it has overlaps (see -per_bp_func above)

          -transform_func <str>:                       Smoothing function on the stats track (see -transform_func above, default: none)
          -window_half_size <num>:                     For smoothing functions (see -window_half_size above)
          -resolution <num>:                           For smoothing function, default is 1, see (-resolution above)
          -min_cov <num>:                              Minimum number of basepairs with data for a valid window position. 1 <= min_cov <= 2 * window_half_size + 1 (default is 1).
          -center_covered:                             If specified, valid window position are only those in which the center basepair has data.

          -compute_mode <str>:               Available modes (and additional required parameters per mode, default: DumpStats):

                                                1. DumpStats : Print a table of the aligned processed stats, a row per feature
                                                2. PerPos    : Compute a value per aligned position, requires:
                                                                 -per_pos_func <str>: Transform function (only non ordered functions, default: mean).
								 -report: Optional. Outputs the number of basepairs participated in each position calculation.
 								 -symmetric_mode: add the stats symmetrically around alignment point (Requires a fixed size window, so used only when -align_point_win_extend_up/downstream are specified and equal).
                                                3. PerFeature: Compute a value per feature, requires:
                                                                 -per_feature_func <str>: Transform function (only non ordered functions, default: none).
					                         -report:                 Optional: Outputs the number of basepairs participated in each feature calculation and the feature coordinates
                                                4. PerFeatures: Compute a single value from all the features. requires:
                                                                 -per_features_func <str>: Transform function (non ordered, default: mean).
                                                                 -per_feature_func <str> : Transform function (optional: if specified apply per_features_func on the output values of per_feature_func).
								 -report:                 Optional: Outputs the number of features or basepairs participated in the calculation,depending on whether -per_feature_func was specified (report #features) or not (report #bps).

          -assume_zeros:                     Relevant for -compute_mode and -transform_func functions: Assume that locations without data on the aligned region have a zero value (affecting only mean currently)



       CorrelateTracks
       ===============
          -min_offset <num>:         Minimum offset of t1 against t2 (default: 0)
          -max_offset <num>:         Maximum offset of t1 against t2 (default: 0)
          -offset_step <num>:        Offset step (default: 1)
          -sep_features_track <str>: Name of separating features track (optional)


       FindNearestFeature (compares t1 and t2 features distances)
       ==================
          -distance_mode <str>   : Distance calculation mode. Options: START_TO_START, MIN_EDGES_DIST (default).
	  -search_direction <str>: Search features up and/or downstream of the feature. Options: SearchDownstream, SearchUpstream, SearchAll (default).
          -allow_overlaps        : Allow overlap between the feature and its nearest feature
          -ignore_same_id        : Ignore features with the same id (name) in the comparison.
          -min_distance <num>    : Output t1 feature only if its distance from the nearest t2 feature is above <num> (default: no filter).
          -max_distance <num>    : Output t1 feature only if its distance from the nearest t2 feature is below <num> (default: no filter).

          Output format:
            <chr> <t1 ID> <t1 start> <t1 end> <t2 ID> <t2 start> <t2 end> <distance>


       PairsFunc (Apply a binary function over a sliding window between 2 tracks).
       =========
          -pairs_func <str> :    Function to use - func(t1, t2). Current options: PearsonCorr, Sum (default: PearsonCorr).

          -window_size <num>:    Compute function over a moving window of size <num> (default: 1)
          -window_step <num>:    Move window by <num> bps (default: 1)
          -min_cov <num>    :    Minimum number of pairs with data for a valid window position. 1 <= min_cov <= window_size (default is 1).
          -anchor <num>:         Anchor position for the moving window (makes sense if window step > 1).

	 ====== Currently offset is not supported =======
          -min_offset <num> :    Minimum offset of t1 against t2 (default: 0)
          -max_offset <num> :    Maximum offset of t1 against t2 (default: 0)
          -offset_step <num>:    Offset step (default: 1)
	 ====== Currently offset is not supported =======

         Output columns:
	 1. First track name
         2. Second track name
         3. Chromosome
         4. Window start coordinate
         5. Window end coordinate
         6. Offset
         7. Number of pairs participating in the window
         8. Result

       DiscretizeToRegions (Discretize t1 features by their value to region below and above the given cutoff. If t2 is specified, process t1 over t2 regions)
       ===================
          -cutoff <num>        : Use <num> as a cutoff over the track values
          -output_mode <str>   : Regions to output (Options: All (default), BelowCutoff, EqAboveCutoff).
	  -min_region_len <num>: Minimum length of output region (default: 0, meaning no filter)
          -max_region_len <num>: Maximum length of output region. Longer regions will be ignored (default: 0, meaning no filter)

       IntersectTracks (t1 - input track, t2 - track to intersect t1 with. Output track contains intersected regions/features with this type: <t1 feature type>;<intersection type>;<t2 feature type>)
       ===============
          -min_intersection_size <num>   : Minimum length of intersection (default: 1)
          -selected_types <str>          : Semicolon (;) seperated list of t2 features types to intersect t1 with (default: no filter)
	  -output_features               : If specified, output t1 original features instead of the default behavior (output intersecting regions).
          -ignore_same_id                : Ignore features with the same id (name) in the comparison.
          -intersection_types <str>      : Semicolon (;) seperated list of intersection types to output (Options: Contained;Contains;Intersects;PerfectMatch, default: no filter)
	  -select_single_feature_by <str>: Select a single t1 feature from all those intersecting each t2 feature (Options: MinValue, MaxValue, MinLength, MaxLength . Default: no filter).

       GreedyFeatureSelection (t1 - input track. Select non overlapping features from t1, ordered (desc) by their value and then by their genomic location (asc).)
       ===============
          -threshold <num>   : Minimum threshold on the values of features to consider


    MySQL Parameters:
    ================
          -load_to_db1:          Track t1 should be loaded (and saved) to the database. Default is to load track into the memory.
          -load_to_db2:          Track t2 should be loaded (and saved) to the database. Default is to load track into the memory.
                                If you wish not to save the tracks in the database, specify -dont_save1 or -dont_save2 (for the first or second track). 

          -db_output <str>:     Save output track in database under <str> file name.

          -host <str>:          MySQL host name (default: mcluster02b)
          -user <str>:          MySQL user name (default: $USER)
          -password <str>:      MySQL user password (default: none)
          -db_name <str>:       MySQL database name (default: tracks)

	  -dont_save1:          If specified, load t1 to database, process the request, and delete it before exit
	  -dont_save2:          If specified, load t2 to database, process the request, and delete it before exit


   Transform Functions:
   ===================
      Non ordered functions:
        1. mean (default)
        2. sum
        3. min
        4. max

      Ordered functions:
        1. gaussian (accepts -stdev <n>, default is 3) - a weighted average of the array elements where the weights form a gaussian (calculated by normPDF).
        2. centerIsmin - outputs the center bp value if it has a value and it is the minimum value among the rest.
        3. centerIsmax
	4. indexOfMin - outputs the index of the minimum value in the input vector
        5. indexOfMax
