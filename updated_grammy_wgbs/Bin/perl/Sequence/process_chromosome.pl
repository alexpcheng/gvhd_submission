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

my $lowercase = get_arg("l", 0, \%args);
my $min = get_arg("min", 1, \%args);
my $max = get_arg("max", 100000000000, \%args);
my $overlap = get_arg("ov", 0, \%args);
my $print_chr_file = get_arg("chr", "NO_CHR_FILE", \%args);
my $print_chr = ($print_chr_file ne "NO_CHR_FILE") ? 1 : 0;

if ($print_chr)
{
  open(CHR, ">$print_chr_file");
}

while(<$file_ref>)
{
  my @row = split(/\t/);
  my $chr = $row[0]; 
  my $seq = $row[1];
  my $s = 0;
  my $e = 0;
  my $seq_length = length($seq);

  while($s < $seq_length)
  {
    while($s < $seq_length && substr($seq, $s, 1) !~ /[AGCTagct]/)
    {
      $s++;
    }
    $e = $s;
    while($e < $seq_length && substr($seq, $e, 1) =~ /[AGCTagct]/)
    {
      $e++;
    }
    if ($e > $s && ($e - $s) > ($min - 1))
    {
      # &process_segments($s,$e,$min,$max,$overlap,$chr,@seq);
      #
      # Initially I made here the above call for a sub routine, 
      # but as I thougt it might be copying the entire array @seq
      # I gave it up. Still, the call is above and the sub routine is below
      # (in case I'll be sure it doesn't cast space it is more elegant to use it)
      
      my $start = $s;
      my $end = $e;
      my $ss = $start;
      my $ee = (($end - $ss) > ($max + $min)) ? ($ss + $max) : $end;

      while ($ss < $end)
      {
	my $ee_eff = $ee - 1;
	my $segment_name = "$chr-$ss-$ee_eff"; 

	print "$segment_name\t";
	if ($print_chr)
	{
	  print CHR "$chr\t$segment_name\t$ss\t$ee_eff\n";
	}

	while ($ss < $ee)
	{
	  if ($lowercase eq "1") 
	  { 
	    my $current_char = substr($seq, $ss, 1);
	    print "\L$current_char"; 
	  }
	  else 
	  { 
	    my $current_char = substr($seq, $ss, 1);
	    print "\U$current_char"; 
	  }
	  $ss++;
	}

	print "\n";
	if ($ss < $end)
	{
	  $ss = $ee - $overlap;
	  $ee = (($end - $ss) > ($max + $min)) ? ($ss + $max) : $end; 
	}
      }

    }
    $s = $e;
  }
}

close(CHR);

sub process_segments
{
  my ($start, $end, $min, $max, $overlap, $chr, @seq) = @_;

  my $ss = $start;
  my $ee = (($end - $ss) > ($max + $min)) ? ($ss + $max) : $end;

  while ($ss < $end)
  {
    my $ee_eff = $ee - 1;
    my $segment_name = "$chr-$ss-$ee_eff"; 
    print "$segment_name\t";

    while ($ss < $ee)
    {
      if ($lowercase eq "1") 
      { 
	print "\L$seq[$ss]"; 
      }
      else 
      { 
	print "\U$seq[$ss]"; 
      }
      $ss++;
    }

    print "\n";
    if ($ss < $end)
    {
      $ss = $ee - $overlap;
      $ee = (($end - $ss) > ($max + $min)) ? ($ss + $max) : $end; 
    }
  }
}


__DATA__

process_chromosome.pl <file>

   Process a chromosome in a stab format (<file>): 
   ----------------------------------------------   
   * Remove undetermined nucleotides (e.g. N). 

   * Convert to upper case (optionally, to lower case).

   * Optionally, cuts into segments of at most some given length and above some given minimal length 

     (max length could be exceeded by the minimal length in the extreme cases).

   * Optionally, output segments with an overlap of given length.

   * The resulted segments (in a stab format) are given the "chromosome" name: 

     <original chromosome name>-<start of segment>-<end of segment>

   * Optionally, print a locations (chr) file for the new "chromosomes" relative to the original ones.

   -l:         Convert to lower case (default: convert to upper case).

   -min <num>: Report only segments of length greater or equal to <num> (default: <num> = 1), 

               (e.g. if the original sequence is ...NNNAANNNTTTNN... and <num> = 3,

               then we output only the TTT segment).

   -max <num>: Cut segments into maximal(**) length of <num> (default: <num> = infinity...). 

               **NOTE: in exreme cases we may output segments of length exceeding by the minimal length!.

   -ov <num>:  The segments include an overlap of length <num> (default: <num> = 0).

   -chr <file>: Print the locations of the new "chromosomes" in the original ones to the (chr) file <file>.
