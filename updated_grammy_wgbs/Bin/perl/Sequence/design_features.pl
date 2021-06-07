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

my $DEBUG = 0;

#---------------------------------------------------------------------#
# LOAD ARGUMENTS                                                      #
#---------------------------------------------------------------------#
my %args = load_args(\@ARGV);

#--------------------------#
# Features file            #
#--------------------------#
my $features_file_ref;
my $features_file = $ARGV[0];
if (length($features_file) < 1 or $features_file =~ /^-/) 
{
  $features_file_ref = \*STDIN;
}
else
{
  open(FEATURES_FILE, $features_file) or die("Could not open the features file '$features_file'.\n");
  $features_file_ref = \*FEATURES_FILE;
}

#--------------------------#
# Resolution               #
#--------------------------#
my $RESOLUTION_FIXED_MODE = 0;
my $RESOLUTION_GREEDY_MODE = 1;

my $resolution_mode = get_arg("res_mode", $RESOLUTION_GREEDY_MODE, \%args);
my $resolution = get_arg("res", 1 , \%args);

if (($resolution_mode != $RESOLUTION_FIXED_MODE)
    and 
    ($resolution_mode != $RESOLUTION_GREEDY_MODE))
{
  die("Resolution mode $resolution_mode not recognized.\n");
}

#--------------------------#
# Other arguments          #
#--------------------------#
my $add_upstream = get_arg("add_upstream", 0 , \%args);
my $add_downstream = get_arg("add_downstream", 0 , \%args);

#--------------------------#
# Probe design file        #
#--------------------------#
my $probes_file = get_arg("probes", "", \%args);
my $probes_file_ref;
if (length($probes_file) == 0)
{
  die "Probes design file not given\n";
}
open(PROBES_FILE, $probes_file) or die("Could not open probes design file '$probes_file'.\n");
$probes_file_ref = \*PROBES_FILE;

#---------------------------------------------------------------------#
# MAJOR LOOP OVER FEATURES                                            #
#---------------------------------------------------------------------#
my %probes_array = ();

my $tmp_probe_str = <$probes_file_ref>;
chomp($tmp_probe_str);
my @tmp_probe = split(/\t/,$tmp_probe_str);
my $tmp_probe_chr = $tmp_probe[1];
my $tmp_probe_min = ($tmp_probe[2] < $tmp_probe[3]) ? $tmp_probe[2] : $tmp_probe[3];
my $tmp_probe_max;

my $tmp_probe_key = $tmp_probe_chr . "__" . $tmp_probe_min;
$probes_array{ $tmp_probe_key } = $tmp_probe_str;

my $probes_array_chr_location = $tmp_probe_chr;
my $probes_array_min_start_bound_location = $tmp_probe_min;
my $probes_array_max_start_bound_location = $tmp_probe_min;

while(my $feature_str = <$features_file_ref>)
{
  chomp($feature_str);
  my @feature = split(/\t/,$feature_str);
  my $feature_chr = $feature[0];
  my $feature_id = $feature[1];
  my $feature_start = ($feature[2] < $feature[3]) ? ($feature[2] - $add_upstream) : ($feature[3] - $add_downstream);
  my $feature_end = ($feature[2] < $feature[3]) ? ($feature[3] + $add_downstream) : ($feature[2] + $add_upstream);

  &PrintHashDEBUG("Feature: $feature_id");

  #-----------------------------------------#
  # Remove from hash probes < feature_start #
  #-----------------------------------------#
  if (($probes_array_chr_location lt $feature_chr)
      or
      (($probes_array_chr_location eq $feature_chr) 
       and 
       ($probes_array_max_start_bound_location < $feature_start)))
  {
    %probes_array = ();
    $probes_array_chr_location = $feature_chr;
    $probes_array_min_start_bound_location = $feature_start;
    $probes_array_max_start_bound_location = $feature_end;
  }
  elsif (($probes_array_chr_location eq $feature_chr) 
	 and 
	 ($probes_array_max_start_bound_location > $feature_start))
  {
    for (my $j = $probes_array_min_start_bound_location; $j < $feature_start; $j++)
    {
      $tmp_probe_key = $feature_chr . "__" . $j;
      delete $probes_array{$tmp_probe_key};
    }
    $probes_array_min_start_bound_location = $feature_start;
  } elsif (($probes_array_chr_location gt $feature_chr)
	   or
	   ($probes_array_min_start_bound_location > $feature_end))
  {
    #there are no probes for this features
  }

  &PrintHashDEBUG("After: Remove from hash probes < feature_start");

  #-----------------------------------------#
  # Add to hash probes < feature_end        #
  #-----------------------------------------#
  while (($tmp_probe_chr lt $feature_chr)
	 or
	 (($tmp_probe_chr eq $feature_chr) 
	  and 
	  ($tmp_probe_min < $feature_start)))
  {
    $tmp_probe_str = <$probes_file_ref>;
    chomp($tmp_probe_str);
    @tmp_probe = split(/\t/,$tmp_probe_str);
    $tmp_probe_chr = $tmp_probe[1];
    $tmp_probe_min = ($tmp_probe[2] < $tmp_probe[3]) ? $tmp_probe[2] : $tmp_probe[3];
  }

  while (($tmp_probe_chr eq $feature_chr) 
	 and 
	 ($tmp_probe_min >= $feature_start)
	 and
	 ($tmp_probe_min <= $feature_end))
  {
    $tmp_probe_key = $tmp_probe_chr . "__" . $tmp_probe_min;
    $probes_array{$tmp_probe_key} = $tmp_probe_str;
    $tmp_probe_str = <$probes_file_ref>;
    chomp($tmp_probe_str);
    @tmp_probe = split(/\t/,$tmp_probe_str);
    $tmp_probe_chr = $tmp_probe[1];
    $tmp_probe_min = ($tmp_probe[2] < $tmp_probe[3]) ? $tmp_probe[2] : $tmp_probe[3];
  }

  &PrintHashDEBUG("After: Add to hash probes < feature_end");

  #-----------------------------------------#
  # Select probes for feature               #
  #-----------------------------------------#
  my @probe;
  my ($probe_str,$probe_chr,$probe_min,$probe_max,$probe_key);
  my $j = $feature_start;
  my $last_j = -1;
  my $tmp_j;

  while ($j <= $feature_end)
  {
    $probe_key = $feature_chr . "__" . $j;
    $probe_str = $probes_array{$probe_key};

    &PrintDEBUG("SELECT 1: $probe_key\n");

    if (length($probe_str) > 0)
    {
      &PrintDEBUG("SELECT 2: $probe_key\n");

      @probe = split(/\t/,$probe_str);
      $probe_chr = $probe[1];
      $probe_min = ($probe[2] < $probe[3]) ? $probe[2] : $probe[3];
      $probe_max = ($probe[2] < $probe[3]) ? $probe[3] : $probe[2];
      $probe_key = $probe_chr . "__" . $probe_min;
      if ($probe_max <= $feature_end)
      {
	print STDOUT "$feature_str\t$feature_start\t$feature_end\t$probe_str\n";
	$tmp_j = &AdvanceProbe($j, $last_j, 1);
	$last_j = $j;
	$j = $tmp_j;
      }
      else
      {
	$j = &AdvanceProbe($j, $last_j, 0);
      }
    }
    else
    {
      $j = &AdvanceProbe($j, $last_j, 0);
    }
  }
}

&PrintDEBUG("\n");

#---------------------------------------------------------------------#
# Subroutines                                                         #
#---------------------------------------------------------------------#

#--------------------------#
# PrintDEBUG               #
#--------------------------#
sub PrintDEBUG
{
  if ($DEBUG) 
  {
    my $str = $_[0];
    print STDERR "$str";
  }
}

#--------------------------#
# PrintHashDEBUG           #
#--------------------------#
sub PrintHashDEBUG
{
  if ($DEBUG) 
  {
    my $header_str = $_[0];
    print STDERR "$header_str\n------------------------\n";
    while (my ($k,$v) = each %probes_array)
    {
      print STDERR "key: $k, value: $v\n";
    }
    print STDERR "------------------------\n";
  }
}

#-------------------------------------------------------------#
# j AdvanceProbe(probe_index, last_probe_index, probe_found)  #
#-------------------------------------------------------------#
sub AdvanceProbe
{
  my $probe_index = $_[0];
  my $last_probe_index = $_[1];
  my $found = $_[2];
  my $res = -1;
  if ($resolution_mode == $RESOLUTION_FIXED_MODE)
  {
    $res = $probe_index + $resolution;
  }
  elsif ($resolution_mode == $RESOLUTION_GREEDY_MODE)
  {
    if ($found)
    {
      $res = $probe_index + $resolution;
    }
    elsif ($last_probe_index > -1)
    {
      my $delta = $probe_index - $last_probe_index - $resolution;
      if ($delta < 0)
      {
	$res = $last_probe_index + $resolution - $delta;
      }
      elsif ($delta < ($resolution-1))
      {
	$res = $last_probe_index + $resolution - $delta - 1;
      }
      else
      {
	$res = $probe_index + 1;
      }
    }
    else
    {
      $res = $probe_index + 1;
    }
  }
  else 
  { 
    die("In design_features.pl->AdvanceProbe: Unknown resolution mode.\n");
  }
  return $res;
}

#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         design_features.pl <file.chr>
 
 Description:    Given a chr file of features and a probe design file,
                 select and output a set of probes for each feature.
                 Notice: the design is not strand sensitive.

 Output:         <feature1_information><\t><probe 1 information>
                 <feature1_information><\t><probe 2 information> 
                 ...

 IMPORTANT!!!    Currently it is assumed that the features file <file.chr> is sorted by chromosome (lexicographic order),
                 then by minimum of start and end coordinates (numerical order). The probes design file <file> is assumed
                 to be sorted too in the same order, but notice that these keys are different columns than
                 the features file. In addition, if add_upstream/add_downstream is used, the features file is assumed to be 
                 sorted according to the modified coordinates!! (beware of the case that add_upstream != add_downstream).

 Flags:

   -probes <file>                     The design of probes.

   -res <int>                         The resolution of probe mapping. (default: 1)

   -res_mode <0/1>                    The selection strategy with respect to the resolution. (default: mode 1)

                                      mode 0:     starting at the feature start, select only probes 
                                                  with indices that are multiplicities of the resolution.
                                      mode 1:     starting at the feature start, greedily select the next probe 
                                                  in the order: start+res, start+res-1, start+res+1, start+res-2 ...

   -add_upstream <int>                Add <int> bp upstream to the feature's start into the design. (default = 0)
  
   -add_downstream <int>              Add <int> bp downstream to the feature's end into the design. (default = 0)
