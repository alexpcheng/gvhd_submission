#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref_parser;
my $file_parser = $ARGV[0];
if (length($file_parser) < 1 or $file_parser =~ /^-/)
{
  $file_ref_parser = \*STDIN;
}
else
{
  open(FILE_PARSER, $file_parser) or die("Could not open file '$file_parser'.\n");
  $file_ref_parser = \*FILE_PARSER;
}

my %args = load_args(\@ARGV);

my $file_track = get_arg("t", "", \%args);
my $organism_name = get_arg("n", "reduced", \%args);
my $is_sorted_parser = get_arg("sp", "not_sorted", \%args);
my $is_sorted_track = get_arg("st", "not_sorted", \%args);
my $is_verbose_mode = get_arg("q", "verbose", \%args);

if (length($file_track) == 0)
{
  die "Original track not given\n";
}

my $file_ref_track;
open(FILE_TRACK, $file_track) or die("Could not open file '$file_track'.\n");
$file_ref_track = \*FILE_TRACK;

##
## Reduce parser to the organism's name
##

my @row;
my @pre_sorted_parser;
my @sorted_parser;

if ($organism_name ne "reduced")
{
  if ($is_verbose_mode eq "verbose")
  {
    print STDERR "Reduce parser to $organism_name...\t";
  }

  while(<$file_ref_parser>)
  {
    chop;
    @row = split(/\t/,$_);
    if ($row[0] eq $organism_name)
    {
      push(@pre_sorted_parser, $_);
    }
  }

  if ($is_verbose_mode eq "verbose")
  {
    print STDERR "done.\n";
  }
}
else
{
  while(<$file_ref_parser>)
  {
    chop;
    @row = split(/\t/,$_);
    push(@pre_sorted_parser, $_);
  }
}
if (@pre_sorted_parser == 0)
{
  die "\nThe organism's name does not match any row in parser.\n";
}

##
## Read the original track into an array
##

my @pre_sorted_original_track;
my @sorted_original_track;

while(<$file_ref_track>)
{
  chop;
  @row = split(/\t/,$_);
  push(@pre_sorted_original_track, $_);
}
if (@pre_sorted_original_track == 0)
{
  die "\nThe original track is empty.\n";
}

##
## Sort parser: 0-1-min(2,3)
##

if ($is_sorted_parser eq "not_sorted")
{
  if ($is_verbose_mode eq "verbose")
  {
    print STDERR "Sort parser...\t";
  }

  @sorted_parser = sort mysort_01min23 @pre_sorted_parser;

  if ($is_verbose_mode eq "verbose")
  {
    print STDERR "done.\n";
  }
}
my $num_sorted_parser = @sorted_parser;

##
## Sort original track: 0-min(2,3)
##

if ($is_sorted_track eq "not_sorted")
{
  if ($is_verbose_mode eq "verbose")
  {
    print STDERR "Sort original track...\t";
  }

  @sorted_original_track = sort mysort_0min23 @pre_sorted_original_track;

  if ($is_verbose_mode eq "verbose")
  {
    print STDERR "done.\n";
  }
}

##
## Map coordinates of original track 
##

my $current_parser_name = "";
my $current_parser_index = 0;
my @track_row;
my $contig_to_process;
my @parser_row;
my $num_sorted_original_track = @sorted_original_track;
my $previous_percentile = 0;

if ($is_verbose_mode eq "verbose")
{
  print STDERR "Start map coordinates: 0 out of $num_sorted_original_track.\n\nPercentile:\t";
}

my $counter_track = 0;

foreach (@sorted_original_track)
{

  if ($is_verbose_mode eq "verbose")
  {
    $counter_track++;
    my $percentile = $counter_track / $num_sorted_original_track;
    $previous_percentile = &printpercentile($percentile,$previous_percentile);
  }

  @track_row = split(/\t/, $_, 5);	
  $contig_to_process = $track_row[0];

  @parser_row = split(/\t/,$sorted_parser[$current_parser_index]);
  $current_parser_name = $parser_row[1];
  
  ##
  ## Save the current_parser_index (into tmp_...) 
  ## in case the contig_to_process has no entry in the parser.
  ##

  my $tmp_current_parser_index = $current_parser_index;

  ##
  ## Advance parser to the right contig
  ##

  while ($contig_to_process gt $current_parser_name && 
	 $current_parser_index < $num_sorted_parser)
  {
    $current_parser_index++;
    @parser_row = split(/\t/,$sorted_parser[$current_parser_index]);
    $current_parser_name = $parser_row[1];
  }

  if ($contig_to_process eq $current_parser_name)
  {
    my $pa_tr_start;
    my $pa_tr_end;
    my $pa_tr_length; 
    my $track_min23;
    my $track_max23;		
    my $track_row_2_lte_3;
    my $parser_row_2_lte_3;
    my $parser_row_6_lte_7;
    my $final_start; 
    my $final_end;
    my $offset_A; 
    my $offset_B;
    my $new_start;
    my $new_end;

    $parser_row_2_lte_3 = $parser_row[2] <= $parser_row[3];
    my $parser_min23 = $parser_row_2_lte_3 ? $parser_row[2] : $parser_row[3];
    my $parser_max23 = $parser_row_2_lte_3 ? $parser_row[3] : $parser_row[2];

    $track_row_2_lte_3 = $track_row[2] <= $track_row[3];
    $track_min23 = $track_row_2_lte_3 ? $track_row[2] : $track_row[3];
    $track_max23 = $track_row_2_lte_3 ? $track_row[3] : $track_row[2];
    
    ##
    ## Advance parser to the right "segment" within the contig
    ##

    while ($contig_to_process eq $current_parser_name && 
	   $track_min23 > $parser_max23 && 
	   $current_parser_index < $num_sorted_parser)
    {
      $current_parser_index++;
      @parser_row = split(/\t/,$sorted_parser[$current_parser_index]);
      $current_parser_name = $parser_row[1];
      $parser_row_2_lte_3 = $parser_row[2] < $parser_row[3];
      $parser_min23 = $parser_row_2_lte_3 ? $parser_row[2] : $parser_row[3];
      $parser_max23 = $parser_row_2_lte_3 ? $parser_row[3] : $parser_row[2];
    }

    my $local_current_parser_index = $current_parser_index;
    my $not_done_with_contig = 1;

    ##
    ## Work on the track (if found)
    ##

    while ($contig_to_process eq $current_parser_name &&
	   $not_done_with_contig && 
	   $local_current_parser_index < $num_sorted_parser)
    {
      @parser_row = split(/\t/,$sorted_parser[$local_current_parser_index]);
      $current_parser_name = $parser_row[1];
      $parser_row_2_lte_3 = $parser_row[2] < $parser_row[3];
      $parser_min23 = $parser_row_2_lte_3 ? $parser_row[2] : $parser_row[3];
      $parser_max23 = $parser_row_2_lte_3 ? $parser_row[3] : $parser_row[2];

      ##
      ## If there is still an overlap btw the track and the parser's segment
      ##

      if ($current_parser_name eq $contig_to_process && 
	  $track_max23 > $parser_min23)
      {
	$parser_row_6_lte_7 = $parser_row[6] <= $parser_row[7];

	$offset_A = $track_min23 > $parser_min23 ? $track_min23 - $parser_min23 : 0;
	$offset_B = $parser_max23 > $track_max23 ? $parser_max23 - $track_max23 : 0;

	##
	## Ugly case analysis...				
	##

	if ($parser_row_2_lte_3)
	{
	  if ($parser_row_6_lte_7)
	  {
	    $new_start = $parser_row[6] + $offset_A;
	    $new_end = $parser_row[7] - $offset_B;
	  }
	  else
	  {
	    $new_start = $parser_row[6] - $offset_A;
	    $new_end = $parser_row[7] + $offset_B;
	  }
	}
	else
	{
	  if ($parser_row_6_lte_7)
	  {
	    $new_start = $parser_row[7] - $offset_A;
	    $new_end = $parser_row[6] + $offset_B;
	  }
	  else
	  {
	    $new_start = $parser_row[7] + $offset_A;
	    $new_end = $parser_row[6] - $offset_B;
	  }
	}

	if ($track_row_2_lte_3)
	{
	  $final_start = $new_start;
	  $final_end = $new_end;
	}
	else
	{
	  $final_start = $new_end;
	  $final_end = $new_start;
	}
		    
	##
	## PRINT!!!
	##

	print "$parser_row[5]\t$track_row[1]\t$final_start\t$final_end\t$track_row[4]\n";

	$not_done_with_contig = $parser_max23 < $track_max23; 

      }#if
      else
      {
	$not_done_with_contig = 0;
      }

      $local_current_parser_index++;
    }#whlie 
  }
  else
  {
    $current_parser_index = $tmp_current_parser_index;
  }
}#foreach

if ($is_verbose_mode eq "verbose")
{
  print STDERR "DONE.\n";
}

##
## Sort parser: 0-1-min(2,3)	#my @sorted_parser = sort mysort_01min23 @parser;
##

sub mysort_01min23
{
  my @row_a = split(/\t/, $a);
  my @row_b = split(/\t/, $b);
  my $min_a_23 = ($row_a[2] < $row_a[3] ? $row_a[2] : $row_a[3]);
  my $min_b_23 = ($row_b[2] < $row_b[3] ? $row_b[2] : $row_b[3]);
  $row_a[0] cmp $row_b[0] || $row_a[1] cmp $row_b[1] || $min_a_23 <=> $min_b_23;
}

##
## Sort parser: 0-min(2,3)   
##

sub mysort_0min23
{
  my @row_a = split(/\t/, $a);
  my @row_b = split(/\t/, $b);
  my $min_a_23 = $row_a[2] < $row_a[3] ? $row_a[2] : $row_a[3];
  my $min_b_23 = $row_b[2] < $row_b[3] ? $row_b[2] : $row_b[3];
  $row_a[0] cmp $row_b[0] || $min_a_23 <=> $min_b_23;
}

##
## Print percentile (in verbose mode only)
##

sub printpercentile
{
  my $percent = int($_[0] * 100);
  my $previous_percent = $_[1];

  if ($percent > $previous_percent)
  {
    print STDERR "$percent% ";      
    $percent;
  }
  else
  {
    $previous_percent;
  }
}

#NOTE THE __DATA__ IS NOT CORRECT, RIGHT NOW I DON'T GET -n AND ASSUME ONLY ONE ORGANISM!

__DATA__

map_coordinates.pl <file.aln> 

  Takes in a MAF-parser file ("aln", a file produced from a MAF by parse_MAF.pl), 
  a stab file (-t) and an organism name (-n), and outputs a stab file 
  that is the original track transformed to the coordinates of the destiny 
  organism according to the MAF-parser.  

  -t <file.stab>:    The original stab file.

  -n <str>:          Name of the original organism. If <str> is not given, 
		     the procedure assumes that the parser is reduced to 
                     the original organism.

  -sp:		     Declare that the parser is sorted by columns: 
		     zero then 1st then minimum of 2nd and 3rd.

  -st:		     Declare that the original track is sorted by columns:
		     zero then minimum of 2nd and 3rd.

  -q:                Quite mode (default is verbose)
