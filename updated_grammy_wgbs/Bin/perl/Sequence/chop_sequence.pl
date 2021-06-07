#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
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

my $key_name = get_arg("k", "", \%args);
my $start_pos = get_arg("s", 1, \%args);
my $end_pos = get_arg("e", -1, \%args);
my $window_width = get_arg("w", 100, \%args);
my $overlap = get_arg("o", 0, \%args);
my $full_length = get_arg("fl", 0, \%args);

my @sequences;
while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    if ((length ($key_name) == 0) or ($key_name eq $row[0]))
    {
		push (@sequences, $_);
    }
}

my $sequence;
my $offset = $window_width - $overlap;

foreach $sequence (@sequences)
{
	(my $key, my $seq) = split (/\t/, $sequence);	

	my $seq_len = length ($seq);
	
	print STDERR "Chopping $key... ";

	my $real_end_pos = 0;
	
	if ($end_pos eq -1)
	{
		$real_end_pos = $seq_len - 1;
	}
	else
	{
		$real_end_pos = ($end_pos < $seq_len ? $end_pos : $seq_len - 1);
	}
	
	if ($full_length)
	{
		$real_end_pos -= ($window_width - 1);
	}
	
	my $num_seqs = 0;
		
	for (my $i = $start_pos; $i < $real_end_pos+2; $i = $i + $offset)
	{
		print $key . "_" . $i . "\t" . substr($seq, $i-1, $window_width) . "\n";
		$num_seqs++;
	}
	
	print STDERR "$num_seqs sequences\n";
	
	
	
}

__DATA__

chop_sequence.pl <file>

   Chop the given sequence into possibly overlapping windows

   -k <num>: Key of sequence to chop (default: chop all sequences)
   -s <num>: Start position (default: 1)
   -e <num>: End position (default: end of sequence)
   -w <num>: Width of chopped sequences (default: 100)
   -o <num>: Overlap between chopped sequences (default: 0)

   -fl:      Full length (do not include pieces that are shorter than the width size)
   
   