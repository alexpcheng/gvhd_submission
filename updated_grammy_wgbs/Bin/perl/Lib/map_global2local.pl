#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $FILE_A_REF;
my $file_A = $ARGV[0];
if (length($file_A) < 1 or $file_A =~ /^-/) 
{
  $FILE_A_REF = \*STDIN;
}
else
{
  open(FILE_A, $file_A) or die("Could not open file '$file_A'.\n");
  $FILE_A_REF = \*FILE_A;
}

my %args = load_args(\@ARGV);

my $FILE_B_REF;
my $file_B = get_arg("f", "", \%args);
my $is_verbose_mode = get_arg("q", "verbose", \%args);

if (length($file_B) == 0)
{
  die "One locations file not given.\n";
}
else
{
  open(FILE_B, $file_B) or die("Could not open file '$file_B'.\n");
  $FILE_B_REF = \*FILE_B;
}

my @seqs_names = <$FILE_B_REF>; 
my @all_locations = <$FILE_A_REF>;
my $num_locations = @all_locations;
my $counter_locations = 0;
my $previous_percentile = 0;

if ($is_verbose_mode eq "verbose")
{
  print STDERR "Start mapping:\t0 out of $num_locations.\nPercentage:\t";
}

foreach (@all_locations)
{
  chop;
  my @locations = split(/\t/, $_, 5);
  my $loc_chr = $locations[0];
  my $loc_id = $locations[1];
  my $loc_s = $locations[2];
  my $loc_e = $locations[3];
  my $loc_str = ($loc_s < $loc_e);
  my $seq_full_chr = "NULL";
  my $seq_chr = "NULL";
  my $seq_s = -10;
  my $seq_e = -10;
  my $not_done=1;
  my $found=0;
  my $i=0;

  if ($is_verbose_mode eq "verbose")
  {
    $counter_locations++;
    my $percentile = $counter_locations / $num_locations;
    $previous_percentile = &printpercentile($percentile,$previous_percentile);
  }

  while($not_done)
  {
    my $seq_line = $seqs_names[$i];
    chop($seq_line);
    my @seq = split(/\t/,$seq_line);
    $seq_full_chr = $seq[1];
    $seq_chr = $seq[0];
    $seq_s = $seq[2];
    $seq_e = $seq[3];

    if (($seq_chr eq $loc_chr) && 
	($loc_str ? 
	 (($seq_s <= $loc_s) && ($seq_e >= $loc_e)) : 
	 (($seq_s <= $loc_e) && ($seq_e >= $loc_s))))
    {
      $not_done=0;
      $found=1;
    }
    else
    {
      $i++;
      if ($i == @seqs_names)
      {
	$not_done=0;
      }
    }
  }

  if ($found)
  {
    my $new_s = $loc_s - $seq_s;
    my $new_e = $loc_e - $seq_s;
    my $extension = length($locations[4]) > 0 ? "\t$locations[4]" : "";
    print "$seq_full_chr\t$loc_id\t$new_s\t$new_e$extension\n";
  }
}

if ($is_verbose_mode eq "verbose")
{
  print STDERR "DONE.\n";
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


__DATA__

map_global2local.pl <file.chr>

   Take a locations file (chr) of some features F in some set of sequences S*, where
   S* is in the "global" coordinates (typically the original chromosomes).
   Also takes a locations file (-f) that maps a set of "local" sequences S into the containing set S*.
   Output a locations file of F relative to the local coordinates of S.
   

   NOTICE: 
           (1) Only features that are fully contained in some sequence s in S are printed.
           (2) For features that appear multiple times in S ouput only the first occurance 
               in S's locations file (think of the case where S has overlapping sequences).  
           (3) The mapping of S into S* is assumed to be forward only (no reverse mappings).
  
   ** See also: process_chromosome.pl **

   -f <file.chr>:     The locations file to be parsed.

   -q:                Quite mode (defualt is verbose)
