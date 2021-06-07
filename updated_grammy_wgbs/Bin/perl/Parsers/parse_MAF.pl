#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

my $leading_organism_name = get_arg("l", "", \%args);
my $destination_organism_name = get_arg("d", "", \%args);

if (length($leading_organism_name) == 0)
{
  die "Leading organism not specified\n";
}

my @current_sequences;
while(<$file_ref>)
{
  chop;

  if ($_ =~ /^s /)
  {
    push(@current_sequences, $_);
  }
  elsif (length($_) == 0)
  {
    &ProcessCurrentSequences;

    @current_sequences = ();
  }
}

sub ProcessCurrentSequences
{
  my $leading_row;
  my $leading_name;
  my $leading_chromosome;
  my $leading_start;
  my $leading_size;
  my $leading_strand;
  my $leading_srcSize;
  my $leading_sequence;
  my @leading_sequence_array;
  my $is_reverse_leading;

  my $destiny_row;
  my $destiny_name;
  my $destiny_chromosome;
  my $destiny_start;
  my $destiny_size;
  my $destiny_strand;
  my $destiny_srcSize;
  my $destiny_sequence;
  my @destiny_sequence_array;
  my $is_reverse_destiny;

  for (my $i = 0; $i < @current_sequences; $i++)
  {
    my @row = split(/[ ]+/, $current_sequences[$i]);
    $row[1] =~ /(^[^\.]+)\.(.+)/;

    if ($1 eq $leading_organism_name)
    {
      $leading_row = $current_sequences[$i];
      $leading_name = $1;
      $leading_chromosome = $2;
      $leading_start = $row[2];
      $leading_size = $row[3];
      $leading_strand = $row[4];
      $leading_srcSize = $row[5];
      $leading_sequence = $row[6];
      @leading_sequence_array = split(/ */,$leading_sequence);
      $is_reverse_leading = $leading_strand =~ /\-/;
    }
  }

  if (length($leading_row) > 0)
  {
    my @leading_coordinates;
    my $iter = 0;				
    for (my $j = 0; $j < length($leading_sequence); $j++)
    {					
      my $is_nucleotide = ($leading_sequence_array[$j] !~ /\-/);	  
      $leading_coordinates[$j] = 
	($is_reverse_leading ? 
	 ($is_nucleotide ? $leading_srcSize - ($leading_start + $iter++) : -1) : 
	 ($is_nucleotide ? $leading_start + $iter++ : -1));
    }

    for (my $i = 0; $i < @current_sequences; $i++)
    {
      my @row = split(/[ ]+/, $current_sequences[$i]);
      $row[1] =~ /(^[^\.]+)\.(.+)/;
      my $current_name = $1;

      if ($current_name ne $leading_organism_name and ($current_name eq $destination_organism_name or length($destination_organism_name) == 0))
      {
	$destiny_row = $current_sequences[$i];
	$destiny_name = $1;
	$destiny_chromosome = $2;
	$destiny_start = $row[2];
	$destiny_size = $row[3];
	$destiny_strand = $row[4];
	$destiny_srcSize = $row[5];
	$destiny_sequence = $row[6];
	@destiny_sequence_array = split(/ */,$destiny_sequence);
	$is_reverse_destiny = $destiny_strand =~ /\-/;
	
	my @destiny_coordinates;
	$iter = 0;
	my @destiny_leading_alignable;
	my $not_started = 1;
	my $start = -1;

	for (my $j = 0; $j < length($destiny_sequence); $j++)
	{
	  my $is_nucleotide_leading = ($leading_sequence_array[$j] !~ /\-/);
	  my $is_nucleotide_destiny = ($destiny_sequence_array[$j] !~ /\-/);
	  
	  $destiny_coordinates[$j] = 
	    ($is_reverse_destiny ? 
	     ($is_nucleotide_destiny ? $destiny_srcSize - ($destiny_start + $iter++) : -1) : 
	     ($is_nucleotide_destiny ? $destiny_start + $iter++ : -1));
	  
	  $destiny_leading_alignable[$j] = $is_nucleotide_leading && $is_nucleotide_destiny;
	  
	  if ($destiny_leading_alignable[$j] && $not_started)
	  {
	    $not_started = !$not_started;
	    $start = $j;
	  }
	  elsif (!$destiny_leading_alignable[$j] && !$not_started)
	  {
	    $not_started = !$not_started;
	    my $end = $j;
	    
	    print "$destiny_name\t$destiny_chromosome\t";
	    print "$destiny_coordinates[$start]\t$destiny_coordinates[$end -1]\t";
	    print "$leading_name\t$leading_chromosome\t";
	    print "$leading_coordinates[$start]\t$leading_coordinates[$end -1]";
	    print "\n";
	  }
	}
      }
    }
  }
}

__DATA__

parse_MAF.pl <file>

   Takes in a Multiple Alignment File (MAF) and 
   names for a "leading" organism and "destination" organisms. 

   Output an "aln" file format, that for each alignment in the MAF, 
   for each destination organism, specify the latter mapped coordinates by the MAF
   to the leading organism.

   E.g., given a MAF A.maf for organisms o1,o2,o3,o4, the command:
   parse_MAF.pl A.maf -l o2 -d o3 
   return a mapping for organism o3 to the coordinates of o2, and
   parse_MAF.pl A.maf -l o2
   return a mapping for o1,o3,o4 to o2.

   Output is (see "aln" file format):

   <dest org><tab><chr><tab><start><tab><end><tab><lead org><tab><chr><tab><start><tab><end><tab>

   -l <str>:    Specifies the leading organism

   -d <str>:    Species the destination organism (default: print all organisms)

