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
my $value_column = get_arg("vc", 4, \%args);
my $min_gap_length = get_arg("gl", 19, \%args);

my $chromosome = "";
my $start = 0;
my $end = 0;
my $val = 0;

my $local_max_chr = "";
my $local_max_start = 0;
my $local_max_end = 0;
my $local_max_val = 0;

my $local_max_previous_chr = "";
my $local_max_previous_end = -1;

my @queue_in = ();


while(my $line = <$file_ref>)
{
   chomp($line);
   my @r = split(/\t/,$line);
   $start = ($r[2] < $r[3]) ? $r[2] : $r[3];

   if (($chromosome ne $r[0]) or ($start - $end > $min_gap_length))
   {
      my @queue_out = &ProcessQueue( @queue_in );
      &PrintQueue( @queue_out );
      @queue_in = ();
      $chromosome = $r[0];
      $end = ($r[2] < $r[3]) ? $r[3] : $r[2];

      $local_max_previous_chr = "";
      $local_max_previous_end = -1;
      $local_max_chr = $chromosome;
      $local_max_start = $start;
      $local_max_end = $end;
      $local_max_val = $r[$value_column];
   }
   elsif (($local_max_val > $r[$value_column]) and ($start - $local_max_end > $min_gap_length) and (($local_max_chr ne $local_max_previous_chr) or ($local_max_start - $local_max_previous_end > $min_gap_length)))
   {
      # go back in queue_in to remove lines after the local_max
      my $max_not_found = 1;
      while ((@queue_in > 0) and ($max_not_found == 1))
      {
	 my $tmp_line = pop(@queue_in);
	 my @tmp_r = split(/\t/,$tmp_line);
	 if ($tmp_r[$value_column] >= $local_max_val)
	 {
	    push(@queue_in, $tmp_line);
	    $max_not_found = 0;
	 }
      }

      # process and print queue
      my @queue_out = &ProcessQueue( @queue_in );
      &PrintQueue( @queue_out );
      @queue_in = ();
      $chromosome = $r[0];
      $end = ($r[2] < $r[3]) ? $r[3] : $r[2];

      $local_max_previous_chr = "";
      $local_max_previous_end = -1;
      $local_max_chr = $chromosome;
      $local_max_start = $start;
      $local_max_end = $end;
      $local_max_val = $r[$value_column];
   }
   else
   {
      $chromosome = $r[0];
      $end = ($r[2] < $r[3]) ? $r[3] : $r[2];

      if ($local_max_val <= $r[$value_column])
      {
	 $local_max_previous_chr = $local_max_chr;
	 $local_max_previous_end = $local_max_end;
	 $local_max_chr = $chromosome;
	 $local_max_start = $start;
	 $local_max_end = $end;
	 $local_max_val = $r[$value_column];
      }
   }

   push( @queue_in, $line );
}

if (@queue_in > 0)
{
   my @queue_out = &ProcessQueue( @queue_in );
   &PrintQueue( @queue_out );
   @queue_in = ();
}

#------------------------------------------------------------#
# &PrintQueue( @queue )
#------------------------------------------------------------#
sub PrintQueue
{
  for (my $i = 0; $i < @_; $i++)
  {
    my $line = @_[$i];
    print STDOUT "$line\n";
  }
}

#------------------------------------------------------------#
# @queue_out = &ProcessQueue( @queue )
#------------------------------------------------------------#
sub ProcessQueue
{
  my @queue = @_;

  if ((@queue == 0) or (@queue == 1))
  {
    return @queue;
  }

  my $max_line = @queue[0];
  my @r = split(/\t/,$max_line);
  my $max_index = 0;
  my $max_start = ($r[2] < $r[3]) ? $r[2] : $r[3];
  my $max_end = ($r[2] < $r[3]) ? $r[3] : $r[2];
  my $max_value = $r[$value_column];

  for (my $i = 0; $i < @queue; $i++)
  {
    my $line = @queue[$i];
    my @r = split(/\t/,$line);
    my $start = ($r[2] < $r[3]) ? $r[2] : $r[3];
    my $end = ($r[2] < $r[3]) ? $r[3] : $r[2];
    my $value = $r[$value_column];
    if ($value > $max_value)
    {
      $max_index = $i;
      $max_line = $line;
      $max_start = $start;
      $max_end = $end;
      $max_value = $value;
    }
  }

  my @res = ( $max_line );

  my @queue_left = ();

  for (my $i = 0; $i < $max_index; $i++)
  {
    my $line = @queue[$i];
    my @r = split(/\t/,$line);
    my $start = ($r[2] < $r[3]) ? $r[2] : $r[3];
    my $end = ($r[2] < $r[3]) ? $r[3] : $r[2];
    my $value = $r[$value_column];

    my $intersection = &Intersection($start, $end, ($max_start - $min_gap_length), ($max_end + $min_gap_length));

    if ( $intersection == 0 )
    {
      push( @queue_left, $line );
    }
  }

  my @queue_right = ();

  for (my $i = $max_index + 1; $i < @queue; $i++)
  {
    my $line = @queue[$i];
    my @r = split(/\t/,$line);
    my $start = ($r[2] < $r[3]) ? $r[2] : $r[3];
    my $end = ($r[2] < $r[3]) ? $r[3] : $r[2];
    my $value = $r[$value_column];

    my $intersection = &Intersection($start, $end, ($max_start - $min_gap_length), ($max_end + $min_gap_length));

    if ( $intersection == 0 )
    {
      push( @queue_right, $line );
    }
  }

  push( @res, &ProcessQueue( @queue_right ) );
  unshift( @res, &ProcessQueue( @queue_left ) );

  return @res;
}

#-------------------------------------------------------------------#
# $intersection_length Intersection($min_a, $max_a, $min_b, $max_b) #
#-------------------------------------------------------------------#
sub Intersection
{
  my $min_a = $_[0];
  my $max_a = $_[1];
  my $min_b = $_[2];
  my $max_b = $_[3];

  my $min_of_max_ab = ($max_a < $max_b) ? $max_a : $max_b;
  my $max_of_min_ab = ($min_a < $min_b) ? $min_b : $min_a;

  my $res = $min_of_max_ab - $max_of_min_ab + 1;

  $res = ($res < 0) ? 0 : $res;
  return $res;
}


__DATA__

chr2local_non_overlapping_maxima.pl <chr file>

   Takes a chr that has a column of value, and outputs the partial chr data
   that has no 2 objects in proximity less than some cutoff. The choice in 
   case of multiple proximate objects is recursively greedy by the max value.

   The chr file is assumed to be sorted by: chromosome (column 1, lexicographically)
   followed by the "start" coordinate (minimum of columns 3,4, numerically).

   -vc <int>:  The column of the values (0-based, default: 4).

   -gl <int>:  The minimal gap length (end - start -1) allowed between 2 consecutive objects (default: 19);
