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
my $val_to_print = get_arg("f", "counts", \%args);
my $sum = get_arg("sum", 0, \%args);
my $w = get_arg("w", 1, \%args);

while(my $line=<$file_ref>)
{
  chomp($line);
  my @row = split(/\t/,$line);
  my $seq_id = $row[0];
  my $seq_fwd = $row[1];
  my $rest;
  for (my $i = 2; $i < @row; $i++)
  {
     $rest .= "\t".$row[$i];
  }

  my $seq_rev = &MyReverseComplement($seq_fwd);

  my $seq_length = length($seq_fwd);
  my $seq_best_count = 0;
  my $seq_total_counts = 0;
  my $seq_val = 0;

  for (my $i=0; $i < $seq_length; $i++) 
  {
     my $seq_count = 0;
     my $k=0;
     my $match_len = 0;

     for (my $j=$i; $j < $seq_length; $j++) 
     {
	if (substr($seq_fwd,$j,1) eq substr($seq_rev,$k,1)) 
	{
	   $match_len++;
	}
	else
	{
	   $seq_count +=  $match_len ** $w;
	   $match_len = 0;
	}
	$k++;
     }

     if ($match_len > 0)
     {
	$seq_count +=  $match_len ** $w;
     }

     $seq_best_count = ($seq_count > $seq_best_count) ? $seq_count : $seq_best_count;
     $seq_total_counts += $seq_count;
  }

  for (my $i=1; $i < $seq_length; $i++) 
  {
     my $seq_count = 0;
     my $k=0;
     my $match_len = 0;

     for (my $j=$i; $j < $seq_length; $j++) 
     {
	if (substr($seq_fwd,$k,1) eq substr($seq_rev,$j,1))
	{
	   $match_len++;
	}
	else
	{
	   $seq_count +=  $match_len ** $w;
	   $match_len = 0;
	}
	$k++;
     }
     
     if ($match_len > 0)
     {
	$seq_count +=  $match_len ** $w;
     }
     
     $seq_best_count = ($seq_count > $seq_best_count) ? $seq_count : $seq_best_count;
     $seq_total_counts += $seq_count;
  }
  
  
  $seq_val = $val_to_print eq "counts" ? ($sum == 0 ? $seq_best_count : $seq_total_counts / $seq_length) : ($seq_best_count / $seq_length);
  $seq_val = &format_number($seq_val,2);
  
  print "$seq_id\t$seq_val\t${seq_fwd}${rest}\n";

}


#-------------------------------------------------------------------------
# $DNAsequence MyReverseComplement ($DNAsequence) # E.g. RC("AACG")="CGTT"
#-------------------------------------------------------------------------
sub MyReverseComplement
{
  my $sequence = $_[0];

  my $n_valid = ($sequence =~ tr/[ACGT]//);


  if ($n_valid != length($sequence))
  {
     die("\nReverseSequence() error: sequence must be on {A,C,G,T}. Exit process.\n");
  }

  return &ReverseComplement($sequence);

}

__DATA__

compute_self_complementarity.pl <file.lst>

   Takes in as input a list of (DNA) sequences in the format <id><\t><sequence> [<other fields>].
   For each sequence, slides the forward sequence and the reverse complement against each other
   and counts the number of complementray base pairs. Reports the maximal counts of a sequence 
   (or the fraction of counts to the sequence length).

   Output format: <id> <comp value> <sequence> [ <other_fields> ]

   -f:    Report the fraction of complementarity, i.e. counts divided by sequence length 
          (default: report counts).

   -sum:  When reporting counts, report the total sum of counts divided by sequence length instead of only the best count.

   -w <num>:    When reporting counts, multiply each match with length(match)^num (default: 1).
