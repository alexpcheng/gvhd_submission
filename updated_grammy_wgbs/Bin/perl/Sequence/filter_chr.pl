#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help") {
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

my $verbose = !get_arg("q", 0, \%args);

my $window_half_size = get_arg("w", 50, \%args);
my $window_size = 1 + ($window_half_size * 2);
my $filter_type = get_arg("f", "ave", \%args);

my @known_types=("ave", "sum", "max", "min", "med", "ismax", "ismin");
my @tmp = grep {$filter_type eq $_} @known_types ;

if (@tmp > 0)
{
   $verbose and print STDERR "Location extended towards each direction by: $window_half_size bp\nFilter = $tmp[0]\n";
}
else
{
   die("Error: unknown filter type \"$filter_type\".\nExpected one of the following filters: @known_types\n");
}

my $column_original_value = get_arg("c", 5, \%args);
my $append_output_value = get_arg("vap", 0, \%args);

## Locations are assumed sorted by chromosome & start (min34)

my @queue_fwd;
my @queue_bck = ();
my $row_str;
my @row;
my $chromosome;
my $start;
my $end;
my $tmp_row_str;
my @tmp_row;
my $tmp_chromosome;
my $tmp_start;
my $tmp_end;

my $column_output_value = $append_output_value ? @row : $column_original_value;
my $last_column = $append_output_value ? $column_output_value : @row - 1;
my $print_current_location;
my $value;
my $new_val;

# Put the first location in the forward queue
$tmp_row_str=<$file_ref>;
push(@queue_fwd, $tmp_row_str);
(@queue_fwd > 0) or die("Empty input chr file.\n");

my $line_counter = 1;

# Loop over locations
while (@queue_fwd > 0)
{
   $verbose and ($line_counter % 10000 == 0) and print STDERR ".";
   $line_counter++;

   $row_str = shift(@queue_fwd);
   chomp($row_str);
   @row = split(/\t/,$row_str);
   $chromosome = $row[0];
   $start = ($row[2] <= $row[3]) ? $row[2] : $row[3];
   $end = ($row[2] <= $row[3]) ? $row[3] : $row[2];
   $value = $row[$column_original_value];

   my $last_fwd_queue_location_intersects_with_current_window = 1;

   # Fill in the forward queue with locations that intersect with the current "main" location (the last location does not intersect)
   while ($last_fwd_queue_location_intersects_with_current_window and $tmp_row_str=<$file_ref>)
   {
      chomp($tmp_row_str);
      @tmp_row = split(/\t/,$tmp_row_str);
      $tmp_chromosome = $tmp_row[0];
      $tmp_start = ($tmp_row[2] <= $tmp_row[3]) ? $tmp_row[2] : $tmp_row[3];
      $tmp_end = ($tmp_row[2] <= $tmp_row[3]) ? $tmp_row[3] : $tmp_row[2];
      push(@queue_fwd,$tmp_row_str);
      $last_fwd_queue_location_intersects_with_current_window = ($tmp_chromosome eq $chromosome) && ($tmp_end >= ($start - $window_half_size)) && ($tmp_start <= ($end + $window_half_size));
   }

   # Remove locations from the backward queue that do not intersect with the current main location.
   my @tmp_new_queue_bck = ();
   for (my $i=0; $i < @queue_bck; $i++)
   {
      $tmp_row_str = $queue_bck[$i];
      chomp($tmp_row_str);
      @tmp_row = split(/\t/,$tmp_row_str);
      $tmp_chromosome = $tmp_row[0];
      $tmp_start = ($tmp_row[2] <= $tmp_row[3]) ? $tmp_row[2] : $tmp_row[3];
      $tmp_end = ($tmp_row[2] <= $tmp_row[3]) ? $tmp_row[3] : $tmp_row[2];
      if (($tmp_chromosome eq $chromosome) && ($tmp_end >= ($start - $window_half_size)) && ($tmp_start <= ($end + $window_half_size)))
      {
	 push(@tmp_new_queue_bck,$tmp_row_str);
      }
   }
   @queue_bck = @tmp_new_queue_bck;

   $print_current_location = 1;

   # Calc the filter/function
   if ($filter_type eq "ave")
   {
      $new_val = &CalcWindowAve($row_str);
   }
   elsif ($filter_type eq "sum")
   {
      $new_val = &CalcWindowSum($row_str);
   }
   elsif ($filter_type eq "max")
   {
      $new_val = &CalcWindowMax($row_str);
   }
   elsif ($filter_type eq "min")
   {
      $new_val = &CalcWindowMin($row_str);
   }
   elsif ($filter_type eq "med")
   {
      $new_val = &CalcWindowMed($row_str);
   }
   elsif ($filter_type eq "ismax")
   {
      $new_val = &CalcWindowMax($row_str);
      $print_current_location = ($value == $new_val);
   }
   elsif ($filter_type eq "ismin")
   {
      $new_val = &CalcWindowMin($row_str);
      $print_current_location = ($value == $new_val);
   }

   # Print the location (if needed)
   if ($print_current_location)
   {
      if ($append_output_value)
      {
	 print STDOUT "$row_str\t$new_val\n";
      }
      else
      {
	 print STDOUT "$row[0]\t$row[1]\t$row[2]\t$row[3]";
	 for (my $j=4; $j < $column_output_value; $j++)
	 {
	    print STDOUT "\t$row[$j]";
	 }
	 print STDOUT "\t$new_val";
	 for (my $j=$column_output_value+1; $j < @row; $j++)
	 {
	    print STDOUT "\t$row[$j]";
	 }
	 print STDOUT "\n";
      }
   }

   push(@queue_bck, $row_str);
}

$verbose and print STDERR "\n";

#------------------------------------------------------------------------------
# SUBROUTINES: CalcWindowXXX for each XXX filter
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# CalcWindowMed($row_str)
#------------------------------------------------------------------------------
sub CalcWindowMed
{
   my $m_str = shift;
   my @m_row = split(/\t/,$m_str);
   my $m_chromosome = $m_row[0];
   my $m_start = ($m_row[2] <= $m_row[3]) ? $m_row[2] : $m_row[3];
   my $m_end = ($m_row[2] <= $m_row[3]) ? $m_row[3] : $m_row[2];
   my $m_value = $m_row[$column_original_value];

   my @res_array = ();
   push(@res_array,$m_value);

   for (my $k=0; $k < @queue_bck; $k++)
   {
      my $t_str = $queue_bck[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 push(@res_array,$t_value);
      }
   }

   for (my $k=0; $k < @queue_fwd; $k++)
   {
      my $t_str = $queue_fwd[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 push(@res_array,$t_value);
      }
   }

   my @sorted_res_array = sort { $a <=> $b } @res_array;

   #Notice: for even number of observation we take the lower 'median'.
   my $med_index = (@res_array % 2 == 0) ? (@res_array/2)-1 : int(@res_array/2);

   my $res = $sorted_res_array[$med_index];

   return $res;
}

#------------------------------------------------------------------------------
# CalcWindowAve($row_str)
#------------------------------------------------------------------------------
sub CalcWindowAve
{
   my $m_str = shift;
   my @m_row = split(/\t/,$m_str);
   my $m_chromosome = $m_row[0];
   my $m_start = ($m_row[2] <= $m_row[3]) ? $m_row[2] : $m_row[3];
   my $m_end = ($m_row[2] <= $m_row[3]) ? $m_row[3] : $m_row[2];
   my $m_value = $m_row[$column_original_value];

   my $res = $m_value;
   my $counter = 1;
   my $a;

   for (my $k=0; $k < @queue_bck; $k++)
   {
      my $t_str = $queue_bck[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      $a = $counter/($counter+1);

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = ($res * $a) + ($t_value * (1-$a));
	 $counter++;
      }
   }

   for (my $k=0; $k < @queue_fwd; $k++)
   {
      my $t_str = $queue_fwd[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      $a = $counter/($counter+1);

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = ($res * $a) + ($t_value * (1-$a));
	 $counter++;
      }
   }

   return $res;
}

#------------------------------------------------------------------------------
# CalcWindowSum($row_str)
#------------------------------------------------------------------------------
sub CalcWindowSum
{
   my $m_str = shift;
   my @m_row = split(/\t/,$m_str);
   my $m_chromosome = $m_row[0];
   my $m_start = ($m_row[2] <= $m_row[3]) ? $m_row[2] : $m_row[3];
   my $m_end = ($m_row[2] <= $m_row[3]) ? $m_row[3] : $m_row[2];
   my $m_value = $m_row[$column_original_value];

   my $res = $m_value;

   for (my $k=0; $k < @queue_bck; $k++)
   {
      my $t_str = $queue_bck[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = $res + $t_value;
      }
   }

   for (my $k=0; $k < @queue_fwd; $k++)
   {
      my $t_str = $queue_fwd[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = $res + $t_value;
      }
   }

   return $res;
}

#------------------------------------------------------------------------------
# CalcWindowMax($row_str)
#------------------------------------------------------------------------------
sub CalcWindowMax
{
   my $m_str = shift;
   my @m_row = split(/\t/,$m_str);
   my $m_chromosome = $m_row[0];
   my $m_start = ($m_row[2] <= $m_row[3]) ? $m_row[2] : $m_row[3];
   my $m_end = ($m_row[2] <= $m_row[3]) ? $m_row[3] : $m_row[2];
   my $m_value = $m_row[$column_original_value];

   my $res = $m_value;

   for (my $k=0; $k < @queue_bck; $k++)
   {
      my $t_str = $queue_bck[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = ($res < $t_value) ? $t_value : $res;
      }
   }

   for (my $k=0; $k < @queue_fwd; $k++)
   {
      my $t_str = $queue_fwd[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = ($res < $t_value) ? $t_value : $res;
      }
   }

   return $res;
}

#------------------------------------------------------------------------------
# CalcWindowMin($row_str)
#------------------------------------------------------------------------------
sub CalcWindowMin
{

   my $m_str = shift;
   my @m_row = split(/\t/,$m_str);
   my $m_chromosome = $m_row[0];
   my $m_start = ($m_row[2] <= $m_row[3]) ? $m_row[2] : $m_row[3];
   my $m_end = ($m_row[2] <= $m_row[3]) ? $m_row[3] : $m_row[2];
   my $m_value = $m_row[$column_original_value];

   my $res = $m_value;

   for (my $k=0; $k < @queue_bck; $k++)
   {
      my $t_str = $queue_bck[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = ($res > $t_value) ? $t_value : $res;
      }
   }

   for (my $k=0; $k < @queue_fwd; $k++)
   {
      my $t_str = $queue_fwd[$k];
      chomp($t_str);
      my @t_row = split(/\t/,$t_str);
      my $t_chromosome = $t_row[0];
      my $t_start = ($t_row[2] <= $t_row[3]) ? $t_row[2] : $t_row[3];
      my $t_end = ($t_row[2] <= $t_row[3]) ? $t_row[3] : $t_row[2];
      my $t_value = $t_row[$column_original_value];

      if (($t_chromosome eq $t_chromosome) && ($t_end >= ($m_start - $window_half_size)) && ($t_start <= ($m_end + $window_half_size)))
      {
	 $res = ($res > $t_value) ? $t_value : $res;
      }
   }

   return $res;
}


__DATA__

Syntax:

   filter_chr.pl <file.chr>

Description:

   Performs a "window filter" transformation on a locations chr-format file.

   The output is a chr file which has locations from the original one that passed the filter criteria,
   with values modified/added according to the filter function, defined over the locations in a prespecified window (in bp).
   The window is defined as the original coordinates of the location extended by X bp to each direction as specified with the '-w X' flag.
   Each location contributes one value and not a values per base per of the location (the default behavior)
   Assumes the chr file to be sorted by chromosome (1st column, lexicographic) and start (minimum of 2nd & 3rd columns, numeric).

   E.g., can transform the data by a sliding window average, or filter only locations that have maximal values in their windows, etc.

   ** NOT IMPLEMENTED, but it is easy to do so: median filter, gaussian filter, any shape-specific convolution, etc. **

   It is not the fastest method you have ever seen, but you dont need to care for memory problems...

Flags:

   -w <int>             The window HALF size extention in base pairs (default: 50bp)
                        E.g., for a location at coordinates S & E, the window size = |E-S+1| + <int>*2.

   -f <filter_type>     The filter type, with <filter_type> is one of the following:

                          ave   =>   average (default)
                          med   =>   median (Notice: for even num of observation in the window take the lower 'median')
                          sum   =>   sum
                          max   =>   maximum
                          min   =>   minimum
                          ismax =>   print a location (original value) iff it has the maximal value of its window
                          ismin =>   print a location (original value) iff it has the minimal value of its window

   -c <int>             The column of the original value (default: 5, zero-base)

   -vap                 Append the output value after the last column (default: overwrite the original value)

   -q                   Quiet mode (default: verbose)
