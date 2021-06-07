#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/vector_ops.pl";

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

my %args = load_args(\@ARGV);

my $column = get_arg("c", -1, \%args);
my $skip_rows = get_arg("skip", 1, \%args);
my $skip_columns = get_arg("skipc", 1, \%args);
my $precision = get_arg("p", 3, \%args);
my $average_window = get_arg("w", 0, \%args);
my $compute_count = get_arg("count", 0, \%args);
my $compute_entropy = get_arg("e", 0, \%args);
my $compute_std = get_arg("std", 0, \%args);
my $compute_std_low = get_arg("std_low", 0, \%args);
my $compute_std_high = get_arg("std_high", 0, \%args);
my $compute_var = get_arg("var", 0, \%args);
my $compute_stderr = get_arg("stderr", 0, \%args);
my $compute_MAD = get_arg("MAD", 0, \%args);
my $compute_mean = get_arg("m", 0, \%args);
my $compute_max = get_arg("max", 0, \%args);
my $compute_min = get_arg("min", 0, \%args);
my $compute_max_ind = get_arg("max_i", 0, \%args);
my $compute_min_ind = get_arg("min_i", 0, \%args);
my $compute_max_min_difference = get_arg("dmaxmin", 0, \%args);
my $compute_median = get_arg("med", 0, \%args);
my $compute_true_median = get_arg("true_med", 0, \%args);
my $compute_sum = get_arg("s", 0, \%args);
my $compute_product = get_arg("prod", 0, \%args);
my $compute_sum_log = get_arg("slog", 0, \%args);
my $compute_num_above_or_equal_min = get_arg("gemin", "", \%args);
my $compute_fraction_above_or_equal_min = get_arg("geminf", "", \%args);
my $compute_num_below_or_equal_max = get_arg("lemax", "", \%args);
my $compute_fraction_below_or_equal_max = get_arg("lemaxf", "", \%args);
my $compute_statistic_top = get_arg("top", "", \%args);
my $compute_statistic_bottom = get_arg("bottom", "", \%args);
my $compute_quantile = get_arg("quant", "", \%args);
my $by_types = get_arg("types", -1, \%args);
my $compute_first_entry_lesser_ind = get_arg("fle_i", "", \%args);
my $compute_first_entry_greater_ind = get_arg("fge_i", "", \%args);
my $compute_first_nonempty_ind = get_arg("fn_i", "", \%args);
my $return_index_values = get_arg("indval", "", \%args);
my $ignore_val = get_arg("ignore_value", "", \%args);


for (my $i = 0; $i < $skip_rows; $i++)
{
    my $line = <$file_ref>;
    chomp($line);
    my @row = split(/\t/, $line,-1);

    print "Stats";
    if ($by_types>-1){ print "\tTypes" }

    #for (my $i = 0; $i < $skip_columns; $i++) { print "\t$row[$i]"; }

    if ($column == -1)
    {
	for (my $i = $skip_columns; $i < @row; $i++)
	{
	    print "\t$row[$i]";
	    #if ($i < @row - 1) { print "\t"; }
	}
    }
    else
    {
	print "\t$row[$column]";
    }

    print "\n";
}

my %matrix;
my %row_counter;
my $num_columns = 0;
my %types;
my @index_values;

while(<$file_ref>)
{
    chomp;
    my @row = split(/\t/,$_,-1);
    my $t="";

    if ($by_types>-1){
	$t=$row[$by_types];
    }

    $types{$t}=1;

    if ($column == -1)
    {
	for (my $i = $skip_columns; $i < @row; $i++)
	{
	    if (length($ignore_val) > 0){ 
		if ($row[$i] != $ignore_val){
		    $matrix{$t}[$row_counter{$t}][$i - $skip_columns] = $row[$i];
		}
	    }
	    else {
		$matrix{$t}[$row_counter{$t}][$i - $skip_columns] = $row[$i];
	    }
	}
	if (@row - $skip_columns > $num_columns) { $num_columns = @row - $skip_columns; }
    }
    else
    {
	if (length($ignore_val) > 0){ 
	    if ($row[$column] != $ignore_val){
		$matrix{$t}[$row_counter{$t}][0] = $row[$column];
	    }
	}
	else {
	    $matrix{$t}[$row_counter{$t}][0] = $row[$column];
	}
	$num_columns = 1;
    }
    if ($return_index_values ne ""){
      $index_values[$row_counter{$t}]=$row[$return_index_values] ; 
    }

    $row_counter{$t}++;
}

#--------------------------------------------------------------------
# Count non empty
#--------------------------------------------------------------------
if ($compute_count == 1)
{
    for my $t (keys %types){
	print "Count";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_count_full_entries(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);

	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Entropy
#--------------------------------------------------------------------
if ($compute_entropy == 1)
{

    for my $t (keys %types){
	print "Entropy";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_entropy(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Max
#--------------------------------------------------------------------
if ($compute_max == 1)
{
    for my $t (keys %types){
	print "Max";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_max(\@vec);
	}
	
	@res = &vec_window_max(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Min
#--------------------------------------------------------------------
if ($compute_min == 1)
{
    for my $t (keys %types){
	print "Min";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_min(\@vec);
	}
	
	@res = &vec_window_min(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# index of min
#--------------------------------------------------------------------
if ($compute_min_ind == 1)
{
    for my $t (keys %types){
	print "Min Ind";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_min_ind(\@vec);
	    if ($return_index_values ne "" and $res[$i] ne ""){$res[$i]=$index_values[$res[$i]]}
	}
		
	foreach my $r (@res)
	{
	    print "\t" . $r;
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# index of max
#--------------------------------------------------------------------
if ($compute_max_ind == 1)
{
    for my $t (keys %types){
	print "Max Ind";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_max_ind(\@vec);
	    if ($return_index_values ne "" and $res[$i] ne ""){$res[$i]=$index_values[$res[$i]]}
	}
	
	foreach my $r (@res)
	{
	    print "\t" . $r;
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# index of first nonempty entry
#--------------------------------------------------------------------
if ($compute_first_nonempty_ind == 1)
{
    for my $t (keys %types){
	print "First Nonempty Ind";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_first_nonempty_entry_ind(\@vec);
	    if ($return_index_values ne "" and $res[$i] ne ""){$res[$i]=$index_values[$res[$i]]}
	}

	foreach my $r (@res)
	{
	    print "\t" . $r;
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# index of first entry that is >= a value
#--------------------------------------------------------------------
if ($compute_first_entry_greater_ind ne "")
{
    for my $t (keys %types){
	print "First >= $compute_first_entry_greater_ind";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_first_entry_ge_ind(\@vec,$compute_first_entry_greater_ind);
	    if ($return_index_values ne "" and $res[$i] ne ""){$res[$i]=$index_values[$res[$i]]}
	}
	
	foreach my $r (@res)
	{
	    print "\t" . $r;
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# index of first entry that is <= a value
#--------------------------------------------------------------------
if ($compute_first_entry_lesser_ind ne "")
{
    for my $t (keys %types){
	print "First >= $compute_first_entry_lesser_ind";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_first_entry_le_ind(\@vec,$compute_first_entry_lesser_ind);
	    if ($return_index_values ne "" and $res[$i] ne ""){$res[$i]=$index_values[$res[$i]]}
	}
	
	foreach my $r (@res)
	{
	    print "\t" . $r;
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Max - Min
#--------------------------------------------------------------------
if ($compute_max_min_difference == 1)
{
    for my $t (keys %types){
	print "MaxMinDifference";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_max(\@vec) - &vec_min(\@vec);
	}

	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Mean
#--------------------------------------------------------------------
if ($compute_mean == 1)
{
    for my $t (keys %types){
	print "Mean";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_avg(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Median
#--------------------------------------------------------------------
if ($compute_median == 1)
  {
      for my $t (keys %types){
	  print "Median";
	  if ($by_types>-1) { print "\t$t" }
	  my @res;
	  for (my $i = 0; $i < $num_columns; $i++)
	  {
	     my @vec = &GetVec($i,$t);
	     $res[$i] = &vec_median(\@vec);
	  }

	  @res = &vec_window_average(\@res, $average_window);

	  foreach my $r (@res)
	  {
	      print "\t" . &format_number($r, $precision);
	  }
	  print "\n";
    }
  }

#--------------------------------------------------------------------
# True Median (if even set avg. the center members)
#--------------------------------------------------------------------
if ($compute_true_median == 1)
  {
      for my $t (keys %types){
	  print "True Median";
	  if ($by_types>-1) { print "\t$t" }
	  my @res;
	  for (my $i = 0; $i < $num_columns; $i++)
	  {
	     my @vec = &GetVec($i,$t);
	     $res[$i] = &vec_true_median(\@vec);
	  }

	  @res = &vec_window_average(\@res, $average_window);

	  foreach my $r (@res)
	  {
	      print "\t" . &format_number($r, $precision);
	  }
	  print "\n";
    }
  }


#--------------------------------------------------------------------
# Quantile (0=first, 1=last, 0.5=med, ...)
#--------------------------------------------------------------------
if (length($compute_quantile) > 0)
  {
      for my $t (keys %types){
	  print "$compute_quantile"."_quantile";
	  if ($by_types>-1) { print "\t$t" }
	  my @res;
	  for (my $i = 0; $i < $num_columns; $i++)
	  {
	     my @vec = &GetVec($i,$t);
	     $res[$i] = &vec_quantile(\@vec,$compute_quantile);
	  }

	  @res = &vec_window_average(\@res, $average_window);

	  foreach my $r (@res)
	  {
	      print "\t" . &format_number($r, $precision);
	  }
	  print "\n";
    }
  }

#--------------------------------------------------------------------
# StdEV
#--------------------------------------------------------------------
if ($compute_std == 1)
{
    for my $t (keys %types){
	print "Std";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_std(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# MAD (median absolute deviation)
#--------------------------------------------------------------------
if ($compute_MAD == 1)
{
    for my $t (keys %types){
	print "MAD";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_mad(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}


#--------------------------------------------------------------------
# Mean + Std
#--------------------------------------------------------------------
if ($compute_std_high == 1)
{
    for my $t (keys %types){
	print "Std_High";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_avg(\@vec) + &vec_std(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Mean - Std
#--------------------------------------------------------------------
if ($compute_std_low == 1)
{
    for my $t (keys %types){
	print "Std_Low";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_avg(\@vec) - &vec_std(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Variance
#--------------------------------------------------------------------
if ($compute_var == 1)
{
    for my $t (keys %types){
	print "Std";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_std(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r*$r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# StdError
#--------------------------------------------------------------------
if ($compute_stderr == 1)
{
    for my $t (keys %types){
	print "StdErr";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_stderr(\@vec);
	}
	
    @res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Sum
#--------------------------------------------------------------------
if ($compute_sum == 1)
{
    for my $t (keys %types){
	print "Sum";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	  $res[$i] = &vec_sum(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Product
#--------------------------------------------------------------------
if ($compute_product == 1)
{
    for my $t (keys %types){
	print "Product";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	  $res[$i] = &vec_product(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#-------------------------------------------------------------------------
# Sum log // assume positive entries = log(x_i) and return log(sum_i{x_i})
#-------------------------------------------------------------------------
if ($compute_sum_log == 1)
{
    for my $t (keys %types){
	print "Sum";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	   my @vec = &GetVec($i,$t);
	   $res[$i] = &vec_sum_log(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Num above or equal minimum
#--------------------------------------------------------------------
if (length($compute_num_above_or_equal_min) > 0)
{
    for my $t (keys %types){
	print ">=$compute_num_above_or_equal_min";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_num_above_or_equal_min(\@vec, $compute_num_above_or_equal_min);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
      foreach my $r (@res)
      {
	  print "\t" . &format_number($r, $precision);
      }
	print "\n";
    }
}

#--------------------------------------------------------------------
# Fraction above or equal minimum
#--------------------------------------------------------------------
if (length($compute_fraction_above_or_equal_min) > 0)
{
    for my $t (keys %types){
	print "%>=$compute_fraction_above_or_equal_min";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_num_above_or_equal_min(\@vec, $compute_fraction_above_or_equal_min) / &vec_count_full_entries(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	  print "\t" . &format_number($r, $precision);
      }
	print "\n";
    }
}

#--------------------------------------------------------------------
# Num less than or equal to maximum
#--------------------------------------------------------------------
if (length($compute_num_below_or_equal_max) > 0)
{
    for my $t (keys %types){
	print "<=$compute_num_below_or_equal_max";
	if ($by_types>-1) { print "\t$t" }

	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_num_below_or_equal_max(\@vec, $compute_num_below_or_equal_max);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Fraction less than or equal to maximum
#--------------------------------------------------------------------
if (length($compute_fraction_below_or_equal_max) > 0)
{
    for my $t (keys %types){
	print "%<=$compute_fraction_below_or_equal_max";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    $res[$i] = &vec_num_below_or_equal_max(\@vec, $compute_fraction_below_or_equal_max) / &vec_count_full_entries(\@vec);
	}
	
	@res = &vec_window_average(\@res, $average_window);
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";
    }
}

#--------------------------------------------------------------------
# Computes nth statistic from top, if n<1 then computes the
# (n*entries)th statistic from top
#--------------------------------------------------------------------

if (length($compute_statistic_top) > 0)
{
    for my $t (keys %types){
	print "$compute_statistic_top"."_top";
	if ($by_types>-1) { print "\t$t" }
	
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    my $stat_num=scalar(@vec)-$compute_statistic_top;
	    if ($compute_statistic_top<1) {
	      $stat_num = sprintf("%d",(1-$compute_statistic_top) * &vec_count_full_entries(\@vec) );
	    }
	    $res[$i]=&vec_nth_statistic(\@vec, $stat_num  );
	}
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";    
    }
}

#--------------------------------------------------------------------
# Computes nth statistic from bottom if n<1 then computes the
# (n*entries)th statistic from bottom
#--------------------------------------------------------------------

if (length($compute_statistic_bottom) > 0){
    for my $t (keys %types){
	print "$compute_statistic_bottom"."_bottom";
	if ($by_types>-1) { print "\t$t" }
	my @res;
	for (my $i = 0; $i < $num_columns; $i++)
	{
	    my @vec = &GetVec($i,$t);
	    my $stat_num=$compute_statistic_bottom-1;
	    if ($compute_statistic_bottom<1) {
	      $stat_num = sprintf("%d",($compute_statistic_bottom * &vec_count_full_entries(\@vec))-1 );
	    }
	    $res[$i]=&vec_nth_statistic(\@vec,$stat_num);
	}
	
	foreach my $r (@res)
	{
	    print "\t" . &format_number($r, $precision);
	}
	print "\n";    
    }
}


sub GetVec ()
{
  my $column = shift;
  my $t = shift;

  my @res;
  for (my $i = 0; $i < $row_counter{$t}; $i++)
    {
      push(@res, $matrix{$t}[$i][$column]);
    }
  return @res;
}

__DATA__

compute_column_stats.pl <file>

   Takes in a tab delimited file and computes statistic for specified columns

   -c <num>:     Column on which to compute the statistic (default: -1 for all columns)

   -skip <num>:  Number of row headers to skip (default: 1)
   -skipc <num>: Number of column headers to skip (default: 1)

   -p <num>:     Precision (default: 3)

   -w <num>:     Print results as the average of a window of <num> around the printed column

   -ignore_value <num>  if specified, ignores the value <num> in all columns when computing (default: none)

   STATISTIC TO COMPUTE

   -e:            Entropy (assumes categorical values)
   -lemax <num>:  Number that are less than or equal to <num>
   -lemaxf <num>: Fraction that are less than or equal to <num>
   -gemin <num>:  Number that are above or equal to <num>
   -geminf <num>: Fraction that are above or equal to <num>
   -bottom <num>: <num>th statistic from bottom (1-based). if 0 < <num> < 1 then the statistic
                  is (<num> * number of entries) from bottom.
   -top <num>:    <num>th statistic from top (1-based). if 0 < <num> < 1 then the statistic is
                  (<num> * number of entries) from top.

   -m:            Mean
   -max:          Max
   -min:          Min
   -dmaxmin:      Max - Min
   -med:          Median
   -true_med:     True Median - in the sense that for an even number of members we get the mean of the two center ones
   -quant <num>:  Quantile <num> of the values (0=min, 1=max, 0.5=median,...)
   -std:          Standard deviation
   -std_high:     Mean + Standard deviation
   -std_low:      Mean - Standard deviation
   -var:          Variance
   -MAD:          Maximum Absolute Median (the median of the difference from the median)
   -stderr:       Standard error
   -s:            Sum
   -prod:         Product
   -slog:         Sum of logs. Assumming each entry i = log(x_i), computes log( sum_i{x_i} )
   -count:        Count the number of non empty entries
   -types <num>:  Enable column types. Statistics are calculated separately for each type.
                  Type is given in <num>th column.

   -min_i:        Index of min
   -max_i:        Index of max
   -fn_i:         Index of first nonempty entry
   -fle_i <num>:  Index of first entry that is <= <num>
   -fge_i <num>:  Index of first entry that is >= <num>
   -indval <num>: If specified with flags that return indices, returns the values in the
                  column <num> matching the indices (instead of the indices themselves).

