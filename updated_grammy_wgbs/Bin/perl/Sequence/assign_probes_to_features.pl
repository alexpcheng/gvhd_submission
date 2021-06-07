#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help") {
   print STDOUT <DATA>;
   exit;
}

my %args = load_args(\@ARGV);

my $features_file = get_arg("features", "", \%args);
my $probes_file = get_arg("probes", "", \%args);
my $resolution = get_arg("res", 1, \%args);
my $min_cov       = get_arg("min_cov", 0, \%args);
my $mid_len       = get_arg("mid_len", -1, \%args);
my $mid_cov       = get_arg("mid_cov", 0, \%args);

if (length($features_file) == 0 or length($probes_file) == 0)
{
    die "Error: must specify features and probes files.\n";
}

open (FEATURES_FILE, "<$features_file") or die "Error: failed to open $features_file\n";
open (PROBES_FILE, "<$probes_file") or die "Error: failed to open $probes_file\n";

# Each of the following arrays holds info on a feature (feature X info is in index Xi in all arrays).
my @orig_lines_arr;
my @assigned_probes_arr;
my @assigned_probes_hash;
my @n_probes_arr;
my @n_mid_probes_arr;
my @segment;
my @start_pos;
my @end_pos;
my $free_idx = -1;
my $n_open_features = 0;
my $no_more_probes = 0;
my $no_more_features = 0;

my $next_feature_end = -1;
my $next_feature_start = -1;
my $next_feature_segment = "";

my $last_probe_segment = "";
my $curr_probe_segment = "";
my $curr_probe_id = "";
my $curr_probe_start = -1;
my $curr_probe_end = -1;
my $curr_probe;

my $next_feature_segment_changed = 1;
my $next_feature_start_changed = 0;

my $feature_line;
my $feature_count = 0;
while (($feature_line = <FEATURES_FILE>) or ($no_more_probes == 0))
{
   if (length($feature_line) > 0)
   {
      $feature_count++;
      if ($feature_count % 10000 == 0 ) {print STDERR "."};

      chop $feature_line;
      &ReadFeature ($feature_line);

      if ($next_feature_segment_changed == 0 and $next_feature_start_changed == 0)
      {
#	 print STDERR "Next feature is in the same start: $next_feature_start \n";
	 next;
      }

      if ($next_feature_segment_changed == 1)
      {
	print STDERR "Starting features on $next_feature_segment ...\n";
      }
   }
   else
   {
      $no_more_features = 1;
      if ($no_more_probes == 1 or $n_open_features == 0)
      {
	 last;
      }
   }
   while ((($no_more_probes == 0) and 
	  (($curr_probe_segment lt $next_feature_segment) or  ($curr_probe_segment eq $next_feature_segment and $curr_probe_start < $next_feature_start)))
	  or ($no_more_features == 1))
   {
      ($curr_probe_segment, $curr_probe_id, $curr_probe_start, $curr_probe_end) = split (/\t/, $curr_probe);

      if ($curr_probe_start >= 74591942)
      {
	 my $i = 9;
      }
      if ($curr_probe_segment ne $last_probe_segment)
      {
	 print STDERR "Starting probes on $curr_probe_segment ...\n";
      }
      $last_probe_segment = $curr_probe_segment;

      if ($n_open_features > 0)
      {
	 &UpdateFeaturesInfo();
      }
      else
      {
#	 print STDERR "None2\t$curr_probe_id\n";
      }
      
      if ($curr_probe_start >= $next_feature_end)
      {
	 &CloseFeatures();
      }

      if (($curr_probe_segment lt $next_feature_segment) or 
	  ($curr_probe_start <= $next_feature_start) or
	  ($no_more_features == 1 and $n_open_features > 0))
      {
	 $curr_probe = <PROBES_FILE>;
	 if (length($curr_probe) == 0)
	 {
	    $no_more_probes = 1;
	    last;
	 }
      }
      else
      {
#	 print STDERR "Not yet\n";
	 if ($no_more_features == 1)
	 {
	    last;
	 }
      }
   }
}

&CloseAllFeatures();

sub ReadFeature
{
    my $line = @_[0];
    my @row = split(/\t/, $line);
    my $curr_start = $row[2] < $row[3] ? $row[2] : $row[3];
    my $curr_end   = $row[2] < $row[3] ? $row[3] : $row[2];

    if ($free_idx != -1)
    {
	$orig_lines_arr[$free_idx] = $line;
	$assigned_probes_arr[$free_idx] = "";
	$assigned_probes_hash[$free_idx] = {};
	$n_probes_arr[$free_idx] = 0;
	$n_mid_probes_arr[$free_idx] = 0;
	$segment[$free_idx] = $row[0];
	$start_pos[$free_idx] = $curr_start;
	$end_pos[$free_idx] = $curr_end;
	$free_idx = &FindNextFreeIdx();
    }
    else
    {
	push (@orig_lines_arr, $line);
	push (@assigned_probes_arr, "");
	push (@assigned_probes_hash, {});
	push (@n_probes_arr, 0);
	push (@n_mid_probes_arr, 0);
	push (@segment, $row[0]);
	push (@start_pos, $curr_start);
	push (@end_pos, $curr_end);
    }

    $next_feature_segment_changed = $next_feature_segment eq $row[0] ? 0 : 1;
    $next_feature_start_changed = $next_feature_start eq $curr_start ? 0 : 1;

    $next_feature_start = $curr_start;
    $next_feature_end = ($next_feature_end == -1 or ($row[0] eq $curr_probe_segment and $curr_end < $next_feature_end)) ? $curr_end : $next_feature_end;
    $next_feature_segment = $row[0];
    $n_open_features++;
}

sub FindNextFreeIdx
{
    for (my $i = 0; $i <= $#orig_lines_arr; $i++)
    {
	if (length($orig_lines_arr[$i]) == 0)
	{
	    return $i;
	}
    }

    return -1;
}

sub UpdateFeaturesInfo 
{
   my $assigned = 0;
   for (my $i = 0; $i <= $#start_pos; $i++)
   {
      if ($start_pos[$i] != -1 and 
	  $curr_probe_segment eq $segment[$i] and
	  $curr_probe_start >= $start_pos[$i] and 
	  $curr_probe_end <= $end_pos[$i] and
	 !$assigned_probes_hash[$i]{$curr_probe_id})
      {
	 $assigned = 1;
	 $assigned_probes_arr[$i] .= "\t$curr_probe_id";
	 $n_probes_arr[$i]++;
	 $assigned_probes_hash[$i]{$curr_probe_id} = 1;
#	 print STDERR $segment[$i]."_".$start_pos[$i]."_".$end_pos[$i]."\t$curr_probe_id\n";
	 if ($mid_len > 0)
	 {
	    my $mid_start = $start_pos[$i] + ($end_pos[$i] - $start_pos[$i] - $mid_len)/2;
	    my $mid_end = $mid_start + $mid_len;
	    if ($curr_probe_start >= $mid_start and $curr_probe_end <= $mid_end)
	    {
	       $n_mid_probes_arr[$i]++;
	    }
	 }
      }
   }
   if ($assigned == 0)
   {
 #     print STDERR "None1\t$curr_probe_id\n";
   }

}

sub CloseFeatures
{
   for (my $i = 0; $i <= $#start_pos; $i++)
   {
      if ($end_pos[$i] > -1 and (($curr_probe_segment gt $segment[$i]) or ($curr_probe_segment eq $segment[$i] and  $curr_probe_start >= $end_pos[$i])))
      {
	 my $coverage = &format_number(($n_probes_arr[$i] * $resolution) / ($end_pos[$i] - $start_pos[$i] + 1),2);
	 if ($coverage >= $min_cov)
	 {
	    if ($mid_len > 0)
	    {
	       my $mid_coverage = &format_number(($n_mid_probes_arr[$i] * $resolution) / $mid_len,2);
	       if ($mid_coverage >= $mid_cov)
	       {
		  print $orig_lines_arr[$i]."\t$coverage:$mid_coverage" . $assigned_probes_arr[$i] . "\n";
	       }
	    }
	    else
	    {
	       print $orig_lines_arr[$i]."\t$coverage" . $assigned_probes_arr[$i] . "\n";
	    }
	 }
	 
	 $orig_lines_arr[$i] = "";
	 $assigned_probes_arr[$i] = "";
	 $assigned_probes_hash[$i] = {};
	 $n_probes_arr[$i] = 0;
	 $n_mid_probes_arr[$i] = 0;
	 $segment[$i] = "";
	 $start_pos[$i] = -1;
	 $end_pos[$i] = -1;
	 $n_open_features--;
	 $free_idx = $i;
      }
   }

   $next_feature_end = -1;
   for (my $i = 0; $i <= $#start_pos; $i++)
   {
      if ($end_pos[$i] > 0)
      {
	 $next_feature_end = ($next_feature_end == -1 or ($segment[$i] == $curr_probe_segment and $next_feature_end > $end_pos[$i])) ? $end_pos[$i] : $next_feature_end;
      }
   }
}

sub CloseAllFeatures
{
   for (my $i = 0; $i <= $#start_pos; $i++)
   {
      $curr_probe_segment = $curr_probe_segment < $segment[$i] ? $segment[$i] : $curr_probe_segment;
      $curr_probe_start = $curr_probe_start < $end_pos[$i] ? $end_pos[$i] : $curr_probe_start;
   }

   &CloseFeatures();
}
__DATA__

assign_probes_to_features.pl

    -features <FILE>:  Features file (chr file, sorted by col1 + min(col3,col4))
    -probes <FILE>:    Probes file (chr file, sorted by col1 + min(col3,col4))
    
    -res <NUM>:        Resolution of probes database (step size)
    -min_cov <NUM>:    Coverage threshold for feature: (<n probes in feature> * <res>) / <feature_length>  (default: 0).

    -mid_len <NUM>:    Length of region at the middle of ech feature (Optional, expects mid_cov).
    -mid_cov <NUM>:    Coverage threshold for the middle region (Optional).
