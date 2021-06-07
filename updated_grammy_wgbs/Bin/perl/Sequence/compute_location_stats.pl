#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/GeneXPress/gxt_helpers.pl";

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
my $max_allowed_distance = get_arg("d", 0, \%args);
my $stats_location_file = get_arg("f", "", \%args);
my $vector_location_stats = get_arg("fv", 0, \%args);
my $stats_to_compute = get_arg("s", "Mean", \%args);
my $sum_statistics = get_arg("sum", 0, \%args);
my $sum_std_statistics = get_arg("sum_std", 0, \%args);
my $multiple_statistics = get_arg("m", 0, \%args);
my $boolean_intersection_threshold = get_arg("b", 0, \%args);
my $boolean_intersection_threshold2 = get_arg("b2", 0, \%args);
my $orientation = get_arg("o", 0, \%args);
my $coverage = get_arg("c", 0, \%args);
my $showall = get_arg("showall", 0, \%args);
my $empty_stat = get_arg("empty", 0, \%args);
my $show_empty_positions = get_arg("e", "", \%args);
my $normalized_column = get_arg("n", 0, \%args);
my $sorted_locations = get_arg("sorted", 0, \%args);
my $adjusted_mean = get_arg("adjusted", 0, \%args);
my $max_distance_sum = 0;
my $percentile_to_compute = -1;
my $significant_numbers = get_arg("p", 3, \%args);
my $verbose = !get_arg("q", 0, \%args);

if (substr ($stats_to_compute, 0, 1) eq "p")
{
	$percentile_to_compute = substr ($stats_to_compute, 1);
	$stats_to_compute = "p";
	
	if ( ($percentile_to_compute >= 100) or ($percentile_to_compute <= 0) )
	{
		die "Percentile range is 0-100 exclusive.\n";
	}
}

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);
my $num_locations=0;
my %sorted_chromosome2locations;


foreach my $chromosome (keys %chromosome2locations){
  my @chromosome_locations;
  if ($sorted_locations){
    @{$sorted_chromosome2locations{$chromosome}} = split/\n/,$chromosome2locations{$chromosome};
  }
  else{
    @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});
    $sorted_chromosome2locations{$chromosome} = \@chromosome_locations;
  }
  if ($sum_statistics == 1){
    for (@chromosome_locations){
      /^\S+\t\S+\t(\S+)\t(\S+)/;
      if (abs($1-$2)>$max_distance_sum){$max_distance_sum=abs($1-$2)}
      $num_locations++;
    }
  }
}
undef %chromosome2locations;

$verbose and print STDERR "Intersecting $stats_location_file ";

my $current_location_index = 0;
my $chromosome_locations;
my $num_chromosome_locations;
my $prev_chromosome = "";
my $current_left;
my %matrix_stats;
my %matrix_list;
my %matrix_counts;
my %matrix_coverage;
my %matrix_bool_hits;
my $counter = 1;
my @matrix_by_distance_sum;
my @matrix_by_distance_sum_squared;
my @matrix_by_distance_counts;
my @vector_row;
my $vector_row_size;
my $MAX_VECTOR_ROW_SIZE = 100000000000;
my $vector_row_current_index;
my $vector_row_current_substr_index;

# check if we got the STATS file as STDIN (allowed only if the feature file was given by name)
my $stats_file_ref;

if ($stats_location_file =~ /^-$/) 
{
    if (length($file) < 1 or $file =~ /^-$/) 
    {
	die "Could not open both features and stats files from the STDIN\n";	
    }
    else 
    {
	$stats_file_ref = \*STDIN;
    }
}
else
{
    open(STATS_FILE, "<$stats_location_file") or die "Could not find stats location file $stats_location_file\n"; 
    $stats_file_ref = \*STATS_FILE;
}

#&TestLoading(); exit;

while(<$stats_file_ref>)
{
    chomp;

    if ($counter % 10000 == 0) { $verbose and print STDERR "."; }

    my @row = split(/\t/,$_,-1);
    my $stat="Default";

    #print STDERR "Statistics entry: $row[1]\n";

    @vector_row = ();
    my $vector_single_length;
    my $vector_single_jump;
    if ($vector_location_stats == 1)
    {
      $vector_single_length = $row[5];
      $vector_single_jump = $row[6];

      # DEBUG YAIR !!!!
      #$vector_row_size = int((($row[2] < $row[3] ? ($row[3] - $row[2] + 1) : ($row[2] - $row[3] + 1)) - $vector_single_length) / $vector_single_jump);
      $vector_row_size = 1 + ($vector_single_jump >= 1 ? int((($row[2] < $row[3] ? ($row[3] - $row[2] + 1) : ($row[2] - $row[3] + 1)) - $vector_single_length) / $vector_single_jump) : 0);

      if ($vector_row_size <= $MAX_VECTOR_ROW_SIZE)
      {
	#print STDERR "Load as vector\n";
	@vector_row = split(/\;/, $row[7]);
      }
      else
      {
	#print STDERR "Load as string vector_row_size=$vector_row_size jump=$vector_single_jump width=$vector_single_length\n";
	$vector_row_current_index = 0;
	$vector_row_current_substr_index = 0;
      }
    }
    if ($multiple_statistics)
    {
      $stat=$row[4];
    }

    if (length($prev_chromosome) == 0 or $row[0] ne $prev_chromosome)
    {
      $current_location_index = 0;
      my @tmp_empty;
      $chromosome_locations = length($sorted_chromosome2locations{$row[0]}) > 0 ? \@{$sorted_chromosome2locations{$row[0]}} : \@tmp_empty;
      $num_chromosome_locations = @$chromosome_locations;
      $prev_chromosome = $row[0];
      $current_left = -999999999;
    }

    my $other_right = $row[2] < $row[3] ? $row[3] : $row[2];

    if ($other_right + $max_allowed_distance >= $current_left)
    {
	my $other_left = $row[2] < $row[3] ? $row[2] : $row[3];

	for (my $i = $current_location_index; $i < $num_chromosome_locations; $i++)
	{
	    my @location = split(/\t/, $$chromosome_locations[$i],-1);

	    my $left = $location[2] < $location[3] ? $location[2] : $location[3];
	    my $right = $location[2] < $location[3] ? $location[3] : $location[2];

	    #print STDERR "Processing $location[0] from $left to $right\n";

	    if ($current_left == -999999999)
	    {
	      $current_left = $left;
	    }

	    if ($left > $other_right + $max_allowed_distance)
	    {
	      last;
	    }
	    elsif ($other_left > $right + $max_allowed_distance)
	    {
	      for (my $j = $i; $j > $current_location_index; $j--)
	      {
		#$$chromosome_locations[$j] = $$chromosome_locations[$j - 1];
	      }

	      $current_location_index++;
	      my @location = split(/\t/, $$chromosome_locations[$current_location_index],-1);
	      $current_left = $location[2] < $location[3] ? $location[2] : $location[3];
	    }
	    else
	    {
	      #print STDERR "$_ Intersects with $$chromosome_locations[$i]\n";
	      
	      my $start_intersection = $left < $other_left ? $other_left : $left;
	      my $end_intersection = $right < $other_right ? $right : $other_right;
	      my $intersection_size = $end_intersection - $start_intersection + 1;

	      my $unique_id = "$location[0];$location[1];$location[2];$location[3]";

	      if ($vector_location_stats == 0)
	      {
		  if (!$orientation or ($row[2]>=$row[3] and $location[2]>=$location[3]) or ($row[3]>=$row[2] and $location[3]>=$location[2])) {
		      if ($coverage){
			  # a bit vector is used to keep track of coverage
			  my $intersection_vector;
			  for (my $b=$start_intersection;$b<=$end_intersection;$b++){
			      vec ($intersection_vector,$b-$left,1)=1;
			  }
			  $matrix_coverage{$unique_id}{$stat} = $matrix_coverage{$unique_id}{$stat} | $intersection_vector;
		      }
		      $matrix_stats{$unique_id}{$stat}+= $row[5] * $intersection_size;
		      $matrix_counts{$unique_id}{$stat} += $intersection_size;
		      if ($intersection_size/(abs($row[2]-$row[3])+1)>=$boolean_intersection_threshold) {
			  if ($intersection_size/(abs($row[2]-$row[3])+1)>=$boolean_intersection_threshold2 or $intersection_size/(abs($location[2]-$location[3])+1)>=$boolean_intersection_threshold2) {
			      $matrix_bool_hits{$unique_id}{$stat}++;
			  }
		      }
		      if ($stats_to_compute eq "Std" or $stats_to_compute eq "Median" or $stats_to_compute eq "p" or $stats_to_compute eq "Entropy" or $stats_to_compute eq "Max") {
			  for (1..$intersection_size) {
			      push @{$matrix_list{$unique_id}{$stat}},$row[5];
			  }
		      }
		  }
	      }
	      else
	      {
		my $start_vector_index;
		my $end_vector_index;
		if ($row[2] < $row[3])
		{
		  $start_vector_index = $start_intersection >= $row[2] + ($vector_single_length - 1) ?
		    int(($start_intersection - ($vector_single_length - 1) - $row[2]) / $vector_single_jump) : 0;

		  $end_vector_index = int(($end_intersection - $row[2]) / $vector_single_jump) + 1;
		  if ($end_vector_index >= $vector_row_size) { $end_vector_index = $vector_row_size - 1; }
		}
		else
		{
		  $start_vector_index = $end_intersection <= $row[2] - ($vector_single_length - 1) ?
		    int(($row[2] - $end_intersection + ($vector_single_length - 1)) / $vector_single_jump) : 0;

		  $end_vector_index = int(($row[2] - $start_intersection) / $vector_single_jump) + 1;
		  if ($end_vector_index >= $vector_row_size) { $end_vector_index = $vector_row_size - 1; }
		}

		#print STDERR "start_intersection=$start_intersection end_intersection=$end_intersection\n";
		#print STDERR "start_vector_index=$start_vector_index  end_vector_index=$end_vector_index\n";

		for (my $j = $start_vector_index; $j <= $end_vector_index; $j++)
		{
		  my $vector_start = $row[2] < $row[3] ? ($row[2] + $j * $vector_single_jump) : ($row[2] - $j * $vector_single_jump);
		  my $vector_end = $row[2] < $row[3] ? ($vector_start + ($vector_single_length - 1)) : ($vector_start - ($vector_single_length - 1));
		  if ($row[2] > $row[3])
		  {
		    my $tmp = $vector_start;
		    $vector_start = $vector_end;
		    $vector_end = $tmp;
		  }
		  my $start_vector_intersection = $start_intersection < $vector_start ? $vector_start : $start_intersection;
		  my $end_vector_intersection = $end_intersection < $vector_end ? $end_intersection : $vector_end;
		  my $intersection_size = $end_vector_intersection - $start_vector_intersection + 1;
		  if ($intersection_size > 0)
		  {
		     #if (abs($j - $vector_row_current_index) > 10) { print STDERR "From non-sum\n"; }
		     if (!$orientation or ($row[2]>=$row[3] and $location[2]>=$location[3]) or ($row[3]>=$row[2] and $location[3]>=$location[2]))
		     {
			my $tmp_val = &GetVectorRowItem(\$row[7], $j);
			$matrix_stats{$unique_id}{$stat}+= $tmp_val * $intersection_size;
			$matrix_counts{$unique_id}{$stat} += $intersection_size;
			if ($stats_to_compute eq "Std" or $stats_to_compute eq "Median" or $stats_to_compute eq "p" or $stats_to_compute eq "Entropy" or $stats_to_compute eq "Max" or $stats_to_compute eq "Dump")
			{
			   for (1..$intersection_size) {
			      push @{$matrix_list{$unique_id}{$stat}},$tmp_val;
			   }
			}
		     }
		  }

		  #print STDERR "vector_start=$vector_start vector_end=$vector_end intersection_size=$intersection_size\n";
		}
	      }
      
	      if ($sum_statistics == 1)
	      {
		if ($vector_location_stats == 0)
		{
		  #print STDERR "OtherRight = $other_right SI $start_intersection EI $end_intersection max_distance_sum=$max_distance_sum\n";
		  if (!$orientation or ($row[2]>=$row[3] and $location[2]>=$location[3]) or ($row[3]>=$row[2] and $location[3]>=$location[2])) {
		    
		    if ($location[2] < $location[3])
		      {
			for (my $j = $start_intersection; $j <= $end_intersection; $j++)
			  {
			    #print STDERR "matrix_by_distance_counts[" . ($j - $left) . "]=" . ($matrix_by_distance_counts[$j - $left]) . "\n";
			    #print STDERR "matrix_by_distance_sum[" . ($j - $left) . "]=" . ($matrix_by_distance_sum[$j - $left]) . "\n";
			    $matrix_by_distance_sum[$j - $left] += $row[5];
			    $matrix_by_distance_sum_squared[$j - $left] += $row[5] * $row[5];
			    $matrix_by_distance_counts[$j - $left]++;
			  }
		      }
		    else
		      {
			for (my $j = $start_intersection; $j <= $end_intersection; $j++)
			  {
			    $matrix_by_distance_sum[$right - $j] += $row[5];
			    $matrix_by_distance_sum_squared[$right - $j] += $row[5] * $row[5];
			    $matrix_by_distance_counts[$right - $j]++;
			  }
		      }
		  }
		}
		else
		{
		  my $start_vector_index;
		  my $end_vector_index;
		  if ($row[2] < $row[3])
		  {
		    $start_vector_index = $start_intersection >= $row[2] + ($vector_single_length - 1) ?
		      int(($start_intersection - ($vector_single_length - 1) - $row[2]) / $vector_single_jump) : 0;

		    $end_vector_index = int(($end_intersection - $row[2]) / $vector_single_jump) + 1;
		    if ($end_vector_index >= $vector_row_size) { $end_vector_index = $vector_row_size - 1; }
		  }
		  else
		  {
		    $start_vector_index = $end_intersection <= $row[2] - ($vector_single_length - 1) ?
		      int(($row[2] - $end_intersection + ($vector_single_length - 1)) / $vector_single_jump) : 0;

		    $end_vector_index = int(($row[2] - $start_intersection) / $vector_single_jump) + 1;
		    if ($end_vector_index >= $vector_row_size) { $end_vector_index = $vector_row_size - 1; }
		  }

		  #print STDERR "start_intersection=$start_intersection end_intersection=$end_intersection\n";
		  #print STDERR "start_vector_index=$start_vector_index  end_vector_index=$end_vector_index\n";
		  
		  for (my $j = $start_vector_index; $j <= $end_vector_index; $j++)
		  {
		    my $vector_start = $row[2] < $row[3] ? ($row[2] + $j * $vector_single_jump) : ($row[2] - $j * $vector_single_jump);
		    my $vector_end = $row[2] < $row[3] ? ($vector_start + ($vector_single_length - 1)) : ($vector_start - ($vector_single_length - 1));
		    if ($row[2] > $row[3])
		    {
		      my $tmp = $vector_start;
		      $vector_start = $vector_end;
		      $vector_end = $tmp;
		    }
		    my $start_vector_intersection = $start_intersection < $vector_start ? $vector_start : $start_intersection;
		    my $end_vector_intersection = $end_intersection < $vector_end ? $end_intersection : $vector_end;
		 
		    if (!$orientation or ($row[2]>=$row[3] and $location[2]>=$location[3]) or ($row[3]>=$row[2] and $location[3]>=$location[2])) {

		      if ($location[2] < $location[3])
			{
			  for (my $k = $start_vector_intersection; $k <= $end_vector_intersection; $k++)
			    {
			      #print STDERR "matrix_by_distance_counts[" . ($k - $left) . "]=" . ($matrix_by_distance_counts[$k - $left]) . "\n";
			      #print STDERR "matrix_by_distance_sum[" . ($k - $left) . "]=" . ($matrix_by_distance_sum[$k - $left]) . "\n";
			      #if (abs($j - $vector_row_current_index) > 10) { print STDERR "From sum 2<3\n"; }
			      my $item = &GetVectorRowItem(\$row[7], $j);
			      $matrix_by_distance_sum[$k - $left] += $item;
			      $matrix_by_distance_sum_squared[$k - $left] += $item * $item;
			      $matrix_by_distance_counts[$k - $left]++;
			    }
			  
			}
		      else
			{
			  for (my $k = $start_vector_intersection; $k <= $end_vector_intersection; $k++)
			    {
			      #if (abs($j - $vector_row_current_index) > 10) { print STDERR "From sum 3<2\n"; }
			      my $item = &GetVectorRowItem(\$row[7], $j);
			      $matrix_by_distance_sum[$right - $k] += $item;
			      $matrix_by_distance_sum_squared[$right - $k] += $item * $item;
			      $matrix_by_distance_counts[$right - $k]++;
			    }
			}
		    }
		  }
		}
	      }
	    }
	  }
      }
    
    $counter++;
  }

$verbose and print STDERR "\n";


my %locations2full_description;
foreach my $chromosome (keys %sorted_chromosome2locations)
{
    my $chromosome_locations = \@{$sorted_chromosome2locations{$chromosome}};

    for (my $i = 0; $i < @$chromosome_locations; $i++)
    {
	my @row = split(/\t/, $$chromosome_locations[$i], 5);
	
	my $unique_id = "$row[0];$row[1];$row[2];$row[3]";
	$locations2full_description{$unique_id} = "$row[1]\t$row[0]\t$row[2]\t$row[3]";
	
	if (scalar(@row)>4){$locations2full_description{$unique_id}.="\t$row[4]"; }

	if ($showall == 1)
	{
	  my $found = 0;
	  foreach my $stat (keys %{$matrix_counts{$unique_id}})
	  {
	    if (length($matrix_counts{$unique_id}{$stat}) > 0)
	    {
	      $found = 1;
	      last;
	    }
	  }
	  if ($found == 0)
	  {
	    $matrix_counts{$unique_id}{"Default"} = 0;
	    $matrix_stats{$unique_id}{"Default"} = $empty_stat;
	  }
	}
    }
}

foreach my $unique_id (keys %matrix_stats)
{
   foreach my $stat (keys %{$matrix_counts{$unique_id}}) {
      my $tmp_dbg = $locations2full_description{$unique_id};

      #print STDERR "id = $unique_id, full_dscr = $tmp_dbg\n";
      print $tmp_dbg;
	
      print "\t";
      if ($multiple_statistics)
      {
	 print "$stat\t";
      }
      if (length($matrix_counts{$unique_id}{$stat}) > 0)
      {
	 print $matrix_counts{$unique_id}{$stat};
	 print "\t";

	 if ($stats_to_compute eq "Mean")
	 {
	    if ($matrix_counts{$unique_id}{$stat} != 0 and length($matrix_counts{$unique_id}{$stat}) > 0)
	    {
	       if ($adjusted_mean)
	       {
		  my @row = split(/\t/,$locations2full_description{$unique_id});
		  my $segment_length = abs ($row[3] - $row[2]) + 1;
		  #print STDERR "segment length = $segment_length\n";
		  print &format_number($matrix_stats{$unique_id}{$stat} / $segment_length, $significant_numbers);
	       }
	       else
	       {
		  print &format_number($matrix_stats{$unique_id}{$stat} / $matrix_counts{$unique_id}{$stat}, $significant_numbers);
	       }
	    }
	    else
	    {
	       print $empty_stat;
	    }
	 }

	 if ($stats_to_compute eq "Std")
	 {
	    if (length($matrix_counts{$unique_id}{$stat}) > 0 and $matrix_counts{$unique_id}{$stat} >= 2)
	    {
	       my $tmp_mean = $matrix_stats{$unique_id}{$stat} / $matrix_counts{$unique_id}{$stat};
	       my $squared_sum = 0;
	       for my $tmp_i (@{$matrix_list{$unique_id}{$stat}})
	       {
		  $squared_sum+=(($tmp_i - $tmp_mean)**2);
	       }
	       my $tmp_std = ($squared_sum / $matrix_counts{$unique_id}{$stat});
	       $tmp_std = ($tmp_std > 0) ? sqrt($tmp_std) : 0;

	       print &format_number($tmp_std, $significant_numbers);
	    }
	    else
	    {
	       print $empty_stat;
	    }
	 }
	
	 if ($stats_to_compute eq "Sum")
	 {
	    print &format_number($matrix_stats{$unique_id}{$stat}, $significant_numbers);
	 }

	 if ($stats_to_compute eq "Boolean" and $matrix_bool_hits{$unique_id}{$stat})
	 {
	    print &format_number($matrix_bool_hits{$unique_id}{$stat}, $significant_numbers);
	 }
	
	 if ($stats_to_compute eq "Median")
	 {
	    my @sorted=sort {$a <=> $b} @{$matrix_list{$unique_id}{$stat}};
	    my $median;
	    my $median_index=scalar(@{$matrix_list{$unique_id}{$stat}})/2;
	    if ($median_index!=int($median_index))
	    {
	       $median=$sorted[$median_index-0.5];
	    }
	    else
	    {
	       $median=($sorted[$median_index]+$sorted[$median_index-1])/2;
	    }
	    print $median;
	 }

	 if ($stats_to_compute eq "p")
	 {
	    my @sorted=sort {$a <=> $b} @{$matrix_list{$unique_id}{$stat}};
	    my $percentile_index=int (scalar(@{$matrix_list{$unique_id}{$stat}})/(100/$percentile_to_compute));
	    print $sorted[$percentile_index];
	 }

	 if ($stats_to_compute eq "Max")
	 {
	    my @sorted=sort {$a <=> $b} @{$matrix_list{$unique_id}{$stat}};
	    print $sorted[$#sorted];
	 }
	 if ($stats_to_compute eq "Dump")
	 {
	    my @r = split(/\t/,$locations2full_description{$unique_id});

	    if ($r[2] <= $r[3])
	    {
	       my $rr = join(";",@{$matrix_list{$unique_id}{$stat}});
	       print "1\t1\t$rr";
	    }
	    else
	    {
	       my $rr = join(";",reverse @{$matrix_list{$unique_id}{$stat}});
	       print "1\t1\t$rr";
	    }
	 }
	 if ($stats_to_compute eq "Entropy")
	 {
	    my $entropy=0;
	    if ($matrix_stats{$unique_id}{$stat} == 0){
	       $entropy="NA";
	    }
	    else
	    {
	       for my $i (@{$matrix_list{$unique_id}{$stat}})
	       {
		  if ($i>0)
		  {
		     $entropy-=($i/$matrix_stats{$unique_id}{$stat})*log($i/$matrix_stats{$unique_id}{$stat})/log(2);
		  }
	       }
	    }
	    print $entropy;

	 }
	 if ($coverage)
	 {
	    my $c=0;
	    my $l=length(unpack("b*", $matrix_coverage{$unique_id}{$stat}));
	    for ($b=0;$b<$l;$b++)
	    {
	       if (vec($matrix_coverage{$unique_id}{$stat},$b,1)==1) { $c++ }
	    }
	    print "\t$c"; # to turn the bit vector into a string use: unpack("b*", $matrix_coverage{$unique_id}{$stat})
	 }
	 print "\n";
      }
      else
      {
	 print "0\t$empty_stat\n";
      }
   }
}


for (my $i = 0; $i <= $max_distance_sum; $i++)
{
  if ($show_empty_positions ne "" or length($matrix_by_distance_counts[$i]) > 0){
    if ($show_empty_positions eq "0" and length($matrix_by_distance_counts[$i])==0 ){
      print "Summary\t$i\t0\t0\t0";
      if ($normalized_column){ print "\t0" }
    }
    else
    {
      print "Summary\t$i\t$matrix_by_distance_counts[$i]\t$matrix_by_distance_sum[$i]\t";

      if (length($matrix_by_distance_counts[$i]) > 0)
      {
	print &format_number($matrix_by_distance_sum[$i] / $matrix_by_distance_counts[$i], $significant_numbers);
      }

      if ($sum_std_statistics == 1)
      {
	print "\t";
	if (length($matrix_by_distance_counts[$i]) > 0)
	{
	  my $mean = $matrix_by_distance_sum[$i] / $matrix_by_distance_counts[$i];
	  print &format_number($matrix_by_distance_sum_squared[$i] / $matrix_by_distance_counts[$i] - $mean * $mean, $significant_numbers);
	}
      }

      if ($normalized_column)
      {
	print "\t";
	if (length($matrix_by_distance_counts[$i]) > 0)
	{
	  print &format_number($matrix_by_distance_sum[$i] / $num_locations, $significant_numbers);
	}
      }
    }
    print "\n";
  }
}

#---------------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------------
sub GetVectorRowItem
{
  my ($vector_str_ref, $index) = @_;

  my $res;

  #if (abs($vector_row_current_index - $index) > 10) { print STDERR "ASKING $index and at $vector_row_current_index\n"; }

  if ($vector_row_size <= $MAX_VECTOR_ROW_SIZE)
  {
    $res = $vector_row[$index];
  }
  else
  {
    if ($vector_row_current_index <= $index)
    {
      while ($vector_row_current_index < $index)
      {
	$vector_row_current_substr_index = index($$vector_str_ref, ";", $vector_row_current_substr_index);
	$vector_row_current_substr_index++;
	$vector_row_current_index++;
      }
    }
    else
    {
      while ($vector_row_current_index > $index)
      {
	$vector_row_current_substr_index = rindex($$vector_str_ref, ";", $vector_row_current_substr_index - 2);
	$vector_row_current_substr_index++;
	$vector_row_current_index--;
      }
    }

    my $next = index($$vector_str_ref, ";", $vector_row_current_substr_index);
    if ($next >= 0)
    {
      $res = substr($$vector_str_ref, $vector_row_current_substr_index, $next - $vector_row_current_substr_index);
      #if ($res =~ /;/) { print STDERR "1 next=$next\n"; exit; }
    }
    else
    {
      $res = substr($$vector_str_ref, $vector_row_current_substr_index);
      #if ($res =~ /;/) { print STDERR "2 next=$next\n"; exit; }
    }
  }

  #print "$index --> $res\n";

  return $res;
}

#---------------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------------
sub TestLoading
{
  while(<STATS_FILE>)
  {
    chomp;

    my @row = split(/\t/,$_,-1);

    my $length = $row[3] - $row[2] + 1;

    print STDERR "Before loading $row[1] Length=$length\n";

    @vector_row = split(/\;/, $row[7]);

    print STDERR "After loading $row[1] Length=$length\n";
  }
}

__DATA__

compute_location_stats.pl <location file>

   Takes a location file and computes a statistic for it with respect to another location file.
   IMPORTANT: The statistics file is assumed to be sorted by chromosome and then by start
   location (i.e. 1st key = 1st column, 2nd key = minimum of 3rd and 4th columns).

   -f <file>:  Statistics file to use as the input statistic
   -fv:        Statistics file is a vector chr file (.chv)

   -d <num>:   Max. distance between the endpoints of locations for counting towards statistics (default: 0)

   -s <str>:   Statistic to compute (Mean/Median/Sum/Std/Entropy/Max/Boolean/Dump/pNN). "Boolean" statistic counts for each
               location the number of -f locations that intersect with it. (default: Mean)
               To calculate entropy, all statistics should to be strictly positive. For each location, the
               statistics are normalized to form a probability distribution, and entropy is calculated.

               pNN prints the NNth percentile data. E.g. p25 is the 25-th percentile, p50 is the median and
               p75 prints the 75-th percentile.

               ** Dump returns the list of statistics in the <location file> boundaries.
                  If the statistics file has full coverage at signle bp resolution, then the output would be a currect chv file. **

   -sum:       Sum the statistics across all locations as a function of distance from the start location
   -sum_std:   Compute the standard deviation across all locations as a function of distance from the start location

   -m:         Statistics file contains multiple statistics. Currently does not work with -d, -s and -fv.

   -b <real>:  When using the "Boolean" statisitic, require an intersection of <real> or more in order to be
               counted. <real> a fraction from the size of the -f location. (default: 0 = any intersection).
   -b2 <real>: Same as -b but requires minimal intersection of <real> on either of the locations (OR).

   -o:         Consider orientation. (default: off)
   -c:         Outputs for each location the number of positions that have data on them (i.e. how much of the
               location is covered). Given as an extra column at the end. (default: off)

   -showall:   Output all locations in the input file, even those that do not intersect any statistics
   -e:         Show empty locations when using "-sum". use -e 0 to print 0 instead of blank.
   -n:         Add column of counts normalized by total number of locations when using "-sum".
   -sorted:    Assumes locations file is sorted as well.
   -adjusted:  For mean calculation, assumes that missing data is zero, so that the sum of all locations is
               divided by the original location length rather than the number of bases for which the statistic
               was found.

   -q          Quite mode, i.e., repress STDERR printing (default: off).

   -p <int>:   The number of significant numbers to print (default: 3)
