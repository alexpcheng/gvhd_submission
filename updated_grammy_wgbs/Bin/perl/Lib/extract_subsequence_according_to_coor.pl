#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $stab_file               = $ARGV[0];
my $coor_file               = $ARGV[1];

# getting the flags
my %args = &load_args(\@ARGV);
my $stat_file   = &get_arg("stats","offset_stat.txt", \%args);

#print STDERR "stab_file:$stab_file\n";
#print STDERR "coor_file:$coor_file\n";


open(IN_STAB_FILE, "<$stab_file") or die "Could not open in file: $stab_file\n";
open(IN_COOR_FILE, "<$coor_file") or die "Could not open in file: $coor_file\n";
open(OUT_STAT_FILE, ">$stat_file") or die "Could not open in file: $stat_file\n";

while (<IN_STAB_FILE>)
{
	chomp;
	my $seq_line = $_;
	
	my $coor_line = <IN_COOR_FILE>;
	chomp($coor_line);
	
	my ($seq_id , $seq) = split(/\t/, $seq_line);
	
	my @coor_line_arr;
	my (@coor_line_arr) = split(/\t/, $coor_line);
	
	my $motif_name = $coor_line_arr[0];
	my $seq_id_by_coor = $coor_line_arr[1];
	my $start_coor = $coor_line_arr[2];
	my $end_coor = $coor_line_arr[3];
	my $strand = $coor_line_arr[5];
	#print STDERR "$seq_id|$seq|$coor_line\n";
	
	if ($seq_id ne $seq_id_by_coor)
	{
		die "seq id not equal: $seq_id|$seq_id_by_coor\n";
	}
	
	my $cur_sub_seq = substr($seq,$start_coor,$end_coor-$start_coor+1);
	
	if ($strand == 1)
	{
		$cur_sub_seq  = &ReverseComplement($cur_sub_seq );
	}
	
	print STDOUT "$seq_id\t$cur_sub_seq\t$motif_name\n";
	print OUT_STAT_FILE "$motif_name\t$seq_id\t$cur_sub_seq\t$start_coor\n";
	
}

close(IN_STAB_FILE);
close(IN_COOR_FILE);
close(OUT_STAT_FILE);

__DATA__

Usage: 


extract_subsequence_according_to_corr.pl <stab file> <coor file>

-stat <stats file>


use in MacIsaac data processing in order to correct offsets in the binding sites location.

the general use is for extracting sub sequences from a file with sequences and coordinates of subsequences

