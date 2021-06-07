#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA> ;
   exit;
}

if ($ARGV[0] eq "--alg")
{
   goto ALGORITHM;
}

#---------------------------------------------------------------------#
# LOAD ARGUMENTS                                                      #
#---------------------------------------------------------------------#
my %args = load_args(\@ARGV);

my $locations_file_1;
my $locations_file_2;

my $value_column = get_arg("vc", "5", \%args);
my $head_rows1 = get_arg("sk1",0,\%args);
my $head_rows2 = get_arg("sk2",0,\%args);
my $one_against_all = get_arg("1all", 0, \%args);
my $all_against_all = get_arg("all", 0, \%args);

my @offset = split(/\,/,get_arg("offset", "", \%args));
my ($offset_start,$offset_end,$offset_increament) = ("","","");
if (@offset == 3)
{
   ($offset_start,$offset_end,$offset_increament) = @offset;
}
my $current_offset_file_1 = 0;
my $offset_mode = (@offset == 3);
my $local_contribution = get_arg("local", 0, \%args);
my $verbose = ! get_arg("q", 0, \%args);
my $precision = get_arg("p", 3, \%args);

my $files_str = get_arg("f", 0, \%args);
my @locations_file_list = split(/\,/, $files_str);

if (@locations_file_list < 1)
{
   die("At least one location file is expected (using the -f flag).\n");
}
for (my $i=0; $i < @locations_file_list; $i++)
{
   $locations_file_1 = $locations_file_list[$i];
   open(LOCATIONS_FILE_1, $locations_file_1) or die("Could not open the location file '$locations_file_1'.\n");
   close(LOCATIONS_FILE_1);
}

my $num_of_files = @locations_file_list;

#---------------------------------------------------------------------#
# CASES                                                               #
#---------------------------------------------------------------------#

if (1)
{
  if ($verbose)  # printing names of files
  {
    print STDERR "Reading location data sets from different files:";
    for (my $j=0; $j < @locations_file_list; $j++)
    {
      print STDERR " $locations_file_list[$j]";
    }
    print STDERR "\n";
  }

  if ($all_against_all)
  {
     $verbose and print STDERR "All against all.\n";
     #---------------------------------------------------------------------------------#
     # for each place in array of files go through rest of array and calc correlations #
     # for now does not print a matrix                                                 #
     # prints: file_num1   file_num2  correlation                                      #
     #---------------------------------------------------------------------------------#

     #-------------------------------------------------------------------#
     # This is if we'll want to print a matrix - building empty matrix   #
     #-------------------------------------------------------------------#
     my @matrix ;
     #print "num of files:  $num_of_files\n";
     for (my $i=0 ; $i < $num_of_files ; $i++)
     {
	my @a ;
	$matrix[$i] = \@a ;
     }

     for (my $i=0 ; $i < $num_of_files ; $i++)
     {
	$matrix[$i]->[$i] = 1;

	for (my $k=$i+1 ; $k < $num_of_files ; $k++)
	{
	   my $locations_file_1 = $locations_file_list[$i];
	   my $locations_file_2 = $locations_file_list[$k];
	   my $my_offset = 0;

	   my ($corr,$N,$mean_x_final,$mean_y_final,$cov_x_y_final) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 0, 0, 0, 0);
	   $matrix[$i]->[$k] = $corr;
	   $matrix[$k]->[$i] = $corr;

	   if ($local_contribution)
	   {
	      my ($corr2,$N2,$mean_x_final2,$mean_y_final2,$cov_x_y_final2) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 1, $mean_x_final, $mean_y_final, $cov_x_y_final);
	   }
	   else
	   {
	      print STDOUT "$locations_file_1\t$locations_file_2\t$my_offset\t$corr\t$N\n";
	   }
	}
     }
  }
  elsif ($one_against_all)
  {
     #--------------------------------------------------------------------#
     #calculates the correlation of the first file against the rest       #
     #--------------------------------------------------------------------#
     $verbose and print STDERR "One against all.\n";

     my $locations_file_1 = $locations_file_list[0];
     for (my $i=1 ; $i < $num_of_files ; $i++)
     {
	my $locations_file_2 = $locations_file_list[$i];
	my $my_offset = 0;

	my ($corr,$N,$mean_x_final,$mean_y_final,$cov_x_y_final) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 0, 0, 0, 0);

	if ($local_contribution)
	{
	   my ($corr2,$N2,$mean_x_final2,$mean_y_final2,$cov_x_y_final2) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 1, $mean_x_final, $mean_y_final, $cov_x_y_final);
	}
	else
	{
	   print STDOUT "$locations_file_1\t$locations_file_2\t$my_offset\t$corr\t$N\n";
	}
     }
  }
  elsif ($offset_mode)
  {
     #--------------------------------------------------------------------#
     # Gets two files and calculates their correlations with offset modes #
     #--------------------------------------------------------------------#

     $verbose and print STDERR "One against Two, in offset mode.\n";

     # the added amount is always to the first file (can be negative)
     my $locations_file_1 = $locations_file_list[0];
     my $locations_file_2 = (@locations_file_list == 1) ? $locations_file_list[0] : (@locations_file_list == 2) ? $locations_file_list[1] : die("The offset mode can currently handle only one or two files, not multiple ones.\n");

     for (my $k = $offset_start ; $k <= $offset_end ; $k=$k+$offset_increament)
     {
	my $my_offset = $k;

	my ($corr,$N,$mean_x_final,$mean_y_final,$cov_x_y_final) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 0, 0, 0, 0);

	if ($local_contribution)
	{
	   my ($corr2,$N2,$mean_x_final2,$mean_y_final2,$cov_x_y_final2) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 1, $mean_x_final, $mean_y_final, $cov_x_y_final);
	}
	else
	{
	   print STDOUT "$locations_file_1\t$locations_file_2\t$my_offset\t$corr\t$N\n";
	}
     }
  }
  else
  {
     #-------------------------------------------------------------------#
     # Takes two first files and gets their correlation with offset 0    #
     #-------------------------------------------------------------------#
     $verbose and print STDERR "One against Two.\n";

     $locations_file_1 = $locations_file_list[0];
     $locations_file_2 = $locations_file_list[1];

     my $my_offset = 0;

     my ($corr,$N,$mean_x_final,$mean_y_final,$cov_x_y_final) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 0, 0, 0, 0);

     if ($local_contribution)
     {
	my ($corr2,$N2,$mean_x_final2,$mean_y_final2,$cov_x_y_final2) = ComputePairwiseCorrelation($locations_file_1, $locations_file_2, $my_offset, 1, $mean_x_final, $mean_y_final, $cov_x_y_final);
     }
     else
     {
	print STDOUT "$locations_file_1\t$locations_file_2\t$my_offset\t$corr\t$N\n";
     }
  }
}

exit;

#--------------------------#
# SUBROUTINES              #
#--------------------------#

#--------------------------------------------------------------------------------------------------------
# $correlation = ComputePairwiseCorrelation
# ($file_1,$file_2,$offset,$is_local_contribution_mode,$mean_x_final,$mean_y_final,$cov_x_y_final);
#--------------------------------------------------------------------------------------------------------

sub ComputePairwiseCorrelation
{
   my ($locations_file_1,$locations_file_2,$offset,$is_local_contribution_mode,$mean_x_final,$mean_y_final,$cov_x_y_final) = @_ ;
   my $local_contribution_type = "LocalContribution"."_"."$locations_file_1"."_"."$locations_file_2"."_"."$offset";
   my $local_contribution_val = 0;
   my $still_file_to_read = 1;

   open(LOCATIONS_FILE_1, $locations_file_1) or die("Could not open the location file '$locations_file_1'.\n");
   open(LOCATIONS_FILE_2, $locations_file_2) or die("Could not open the location file '$locations_file_2'.\n");
   my ($line_1, $line_2);

   #-------------------------------------#
   # taking off header rows              #
   #-------------------------------------#
   for (my $k=0 ; $k < $head_rows1 ; $k++)
   {
      $line_1 = <LOCATIONS_FILE_1>;
   }

   for (my $j=0 ; $j < $head_rows2 ; $j++)
   {
      $line_2 = <LOCATIONS_FILE_2>;
   }

   my $first_run = 0;
   my $sum_sq_x = 0;
   my $sum_sq_y = 0;
   my $sum_coproduct = 0;
   my $N = 0;
   my ($sweep, $delta_x, $delta_y, $mean_x, $mean_y);

   my ($line1_chr,$line1_start, $line1_end, $line1_type, $line1_value);
   my ($line2_chr,$line2_start, $line2_end, $line2_type, $line2_value);

   # get first relavent lines of the two files
   if ($still_file_to_read == 1)
   {
      ($line1_chr, $line1_start, $line1_end, $line1_type, $line1_value) = read_from(1, \$still_file_to_read);
      # taking care of offset
      $line1_start += $offset;
      $line1_end += $offset;

      ($line2_chr, $line2_start, $line2_end, $line2_type, $line2_value) = read_from(2, \$still_file_to_read);
   }

   while($still_file_to_read == 1)
   {

      my $intersect = (($line1_chr eq $line2_chr) and (! (($line1_start > $line2_end) or ($line2_start > $line1_end))));

      while ((! $intersect) && ($still_file_to_read == 1))
      {
	 # gettnig to the place where chr is the same
	 if ($line1_chr ne $line2_chr)
	 {
	    if ($line1_chr lt $line2_chr)
	    {
	       ($line1_chr,$line1_start, $line1_end, $line1_type, $line1_value) = read_from(1, \$still_file_to_read) ;
	       # taking care of offset
	       $line1_start += $offset;
	       $line1_end += $offset;
	    }
	    elsif ($line2_chr lt $line1_chr)
	    {
	       ($line2_chr,$line2_start, $line2_end, $line2_type, $line2_value) = read_from(2,\$still_file_to_read) ;
	    }
	 }
	 elsif (($line1_start > $line2_end) || ($line2_start > $line1_end))
	 {
	    if ($line1_start > $line2_end)
	    {
	       ($line2_chr,$line2_start, $line2_end, $line2_type, $line2_value) = read_from(2,\$still_file_to_read );
	    }
	    else
	    {
	       ($line1_chr,$line1_start, $line1_end, $line1_type, $line1_value) = read_from(1, \$still_file_to_read);
	       # taking care of offset
	       $line1_start += $offset;
	       $line1_end += $offset;
	    }
	 }
	 $intersect = (($line1_chr eq $line2_chr) and (! (($line1_start > $line2_end) or ($line2_start > $line1_end))));
      }

      my ($runover_start, $runover_end);
      # doing the calculation of the runover part for $runover_start and $runover_end
      if ($still_file_to_read == 1)
      {
	 ($runover_start, $runover_end) = get_runover_start_end($line1_start, $line1_end, $line2_start, $line2_end);

	 if ($first_run == 0)
	 {
	    if ($is_local_contribution_mode)
	    {
	       $local_contribution_val = ($line1_value - $mean_x_final) * ($line2_value - $mean_y_final) / $cov_x_y_final;
	       $local_contribution_val = &format_number($local_contribution_val,$precision);
	       print STDOUT "$line1_chr\t$runover_start\t$runover_start\t$local_contribution_type\t$local_contribution_val\n";
	    }

	    $mean_x = $line1_value;
	    $mean_y = $line2_value;
	    $runover_start += 1;
	    $N += 1;
	    $first_run = 1;
	 }

	 for(my $i = $runover_start; $i <= $runover_end; $i++)
	 {
	    if ($is_local_contribution_mode)
	    {
	       $local_contribution_val = ($line1_value - $mean_x_final) * ($line2_value - $mean_y_final) / $cov_x_y_final;
	       $local_contribution_val = &format_number($local_contribution_val,$precision);
	       print STDOUT "$line1_chr\t$i\t$i\t$local_contribution_type\t$local_contribution_val\n";
	    }

	    $N += 1;
	    $sweep = ($N - 1) / $N;
	    $delta_x = $line1_value - $mean_x;
	    $delta_y = $line2_value - $mean_y;
	    $sum_sq_x += $delta_x * $delta_x * $sweep;
	    $sum_sq_y += $delta_y * $delta_y * $sweep;
	    $sum_coproduct += $delta_x * $delta_y * $sweep;
	    $mean_x += $delta_x / $N;
	    $mean_y += $delta_y / $N;
	 }
      }

      if ($line1_end <= $line2_end)
      {
	 ($line1_chr,$line1_start, $line1_end, $line1_type, $line1_value) = read_from(1, \$still_file_to_read);
	 # taking care of offset
	 $line1_start += $offset;
	 $line1_end += $offset;
      }
      else
      {
	 ($line2_chr,$line2_start, $line2_end, $line2_type, $line2_value) = read_from(2, \$still_file_to_read);
      }
   }

   my $pop_sd_x = sqrt( $sum_sq_x );
   my $pop_sd_y = sqrt( $sum_sq_y );
   my $cov_x_y = $sum_coproduct;

   close(LOCATIONS_FILE_1);
   close(LOCATIONS_FILE_2);

   if (($pop_sd_x * $pop_sd_y) != 0)
   {
      my $correlation = $cov_x_y / ($pop_sd_x * $pop_sd_y);
      $mean_x_final = $mean_x;
      $mean_y_final = $mean_y;
      $cov_x_y_final = $cov_x_y;

      return (&format_number($correlation,$precision),$N,$mean_x_final,$mean_y_final,$cov_x_y_final) ;
   }
   else  # the denumerator == zero
   {
      $verbose and print STDERR "There are not enough values to calculate the correlation, OR all the values of at least one of the vectors are the same, i.e. std=0.\n";
      return (-2,$N,$mean_x_final,$mean_y_final,$cov_x_y_final);
   }
}


#--------------------------------------------------------------------------------------------------------------#
# reads lines form a file  LOCATIONS_FILE_(1/2) untill getting to a line with the right type and then          #
# puts the wanted values of that line to $line*_chr,$line*_start, $line*_end, $line*_type, $line*_value)       #
#--------------------------------------------------------------------------------------------------------------#
sub read_from
{
   my ($num, $p_still_file_to_read) = @_ ;
   my ($line1, $line2) ;

   if ($num == 1)
   {
      if (!($line1 = <LOCATIONS_FILE_1>))
      {
	 $$p_still_file_to_read = 0 ;
	 return (0) ;
      }
      chomp($line1);
      #print "line file 1: $line1 \n" ;
      my @line1_array = split(/\t/, $line1);
      my $line1_chr = $line1_array[0];
      my $line1_start = ($line1_array[2] <= $line1_array[3]) ? $line1_array[2] : $line1_array[3];
      my $line1_end = ($line1_array[2] <= $line1_array[3]) ? $line1_array[3] : $line1_array[2];
      my $line1_type = 1;
      my $line1_value = $line1_array[$value_column];

      return ($line1_chr, $line1_start, $line1_end, $line1_type, $line1_value) ;
   }
   if ($num == 2)
   {
      if (!($line2 = <LOCATIONS_FILE_2>))
      {
	 $$p_still_file_to_read = 0 ;
	 return (0);
      }
      chomp($line2);
      #print "line file 2: $line2 \n" ;
      my @line2_array = split(/\t/,$line2);
      my $line2_chr = $line2_array[0];
      my $line2_start = ($line2_array[2] <= $line2_array[3]) ? $line2_array[2] : $line2_array[3];
      my $line2_end = ($line2_array[2] <= $line2_array[3]) ? $line2_array[3] : $line2_array[2];
      my $line2_type = 2;
      my $line2_value = $line2_array[$value_column];

      return ($line2_chr, $line2_start, $line2_end, $line2_type, $line2_value) ;
   }
}


sub get_runover_start_end
{
   my ($line1_start, $line1_end, $line2_start, $line2_end) = @_ ;
   my ($runover_start, $runover_end);

   if ($line2_start <= $line1_start)
   {
      $runover_start = $line1_start ;
   }
   else
   {
      $runover_start = $line2_start ;
   }

   if ($line1_end <= $line2_end)
   {
      $runover_end = $line1_end;
   }
   else
   {
      $runover_end = $line2_end;
   }
   return ($runover_start, $runover_end);
}

ALGORITHM:

print STDOUT ("\
#---------------------------------------------------------------------#
#                                                                     #
#  The algorithm (from wikipedia):                                    #
#                                                                     #
#  sum_sq_x = 0                                                       #
#  sum_sq_y = 0                                                       #
#  sum_coproduct = 0                                                  #
#  mean_x = x[1]                                                      #
#  mean_y = y[1]                                                      #
#  for i in 2 to N:                                                   #
#       sweep = (i - 1.0) / i                                         #
#       delta_x = x[i] - mean_x                                       #
#       delta_y = y[1] - mean_y                                       #
#       sum_sq_x += delta_x * delta_x * sweep                         #
#       sum_sq_y += delta_y * delta_y * sweep                         #
#       sum_coproduct += delta_x * delta_y * sweep                    #
#       mean_x += delta_x / i                                         #
#       mean_y += delta_y / i                                         #
#  pop_sd_x = sqrt( sum_sq_x / N )                                    #
#  pop_sd_y = sqrt( sum_sq_y / N )                                    #
#  cov_x_y = sum_coproduct / N                                        #
#  correlation = cov_x_y / (pop_sd_x * pop_sd_y)                      #
#                                                                     #
#---------------------------------------------------------------------#
");
exit;

#    YAIR: I removed the local option cause it had a bug and I didn't have time to fix it....
#
#   -local            Output (only) the local single bp contributions to the overall correlation in a chr format,
#                     with Type = "LocalContribution_<name_data_set_x>_<name_data_set_y>_<offset>"
#                     (default: output the correlation coefficients)



#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         compute_location_correlation.pl

 Description:    Computes the correlation coefficient between 2 location (chr-format) data sets given as chr files.
                 Can offset one location with respect to the other, and also compute all pairwise correlations
                 between multiple data sets.
                 In addition can output the local single bp contributions to the correlation. *** need a better explanation ***

 Output:         <name_data_set_x><\t><name_data_set_y><\t><offset><\t><correlation><\t><num_of_data_points_in_calculation>

 IMPORTANT!!!    It is assumed that the location file(s) is sorted by chromosome 
                 (lexicographic order), then by start coordinate (minimum of 3rd-n-4th chr columns,
                 numerical order), *** and also that locations within a data set do not intersect. ***
                 Do not work with pipline!!!

 Flags:

   -f <file.chr>:    The locations file(s). Specify multiple files using comma (e.g. -f file1.chr,file2.chr,file3.chr).

   -vc <int>:        The Value column. (zero-based. default: 5)

   -sk1 <int>:       The number of header rows to skip in file1 (default: 0)

   -sk2 <int>:       The number of header rows to skip in file2 (default: 0)

   -offset <s,e,i>:  Offset the two location data sets compared by offsetting THE FIRST by:
                     <s> entries, <s+i> entries,... <e> entries
                     For example, -offset "-10,10,1" will compute stats between the vectors at
                     offset -10 to offset +10 in increments of 1.

   -1all:            Compute the correlations of data set 1 against all other data sets
                     (default: only for data sets 1 & 2).

   -all:             Compute the correlations of all pairs of data sets (default: only for data sets 1 & 2).

   -p <int>:         Precision for outputted correlations (default: 3 numbers after the digit)

   -q:               Quiet mode (default is verbose).

  --alg:             Print out the algorithm for computing the correlation in pseoducode (and exit).

  --help:            Print out this help manual (and exit).

