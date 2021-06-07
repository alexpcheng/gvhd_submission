#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
my $stat_file = $ARGV[1];
my $stab_dir = $ARGV[2];
if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

open(STAT_OUTFILE, ">$stat_file") or die "could not open test out file: $stat_file";
	



my %args = load_args(\@ARGV);

#my $species = get_arg("s", "", \%args);


my $current_id;
my $new_TF_need_to_update_id = 0;

my $prev_TF_id = "";

my $my_cur_TF_seq_num = 0;

my @cur_TF_seqs;
my @cur_TF_seqs_names;

while(<$file_ref>)
{
  chop;
  
  my ($cur_TF_id, $cur_seq_name, $cur_seq) = split(/\t/);
  
  print STDERR "cur line: $cur_TF_id, $cur_seq_name, $cur_seq\n";
  my $cur_seq_len = length ($cur_seq);
  print STDERR "cur length:$cur_seq_len\n";
  
  # new TF
  if ($cur_TF_id ne $prev_TF_id)
  {
	print STDERR "NEW MOTIF:$cur_TF_id(prev:$prev_TF_id)\n";
	#write prev TF
	if ($my_cur_TF_seq_num > 0)
	{
		my ($stat_TF_id, $stat_seq_num, $stat_total_seq_num, $stat_seq_len) = &PrintTFStab(\@cur_TF_seqs, \@cur_TF_seqs_names ,$prev_TF_id);
		
		my $unique_seqs_num = `cat $stab_dir/$stat_TF_id.stab | cut -f 2 | sort | uniq -c | wc -l`;
		print STDERR "DEBUG: $stab_dir/$stat_TF_id.stab | cut -f 2 | sort | uniq -c | wc -l";
		chomp($unique_seqs_num);
		
		print STAT_OUTFILE "$stat_TF_id\t$stat_seq_num\t$stat_total_seq_num\t$stat_seq_len\t$unique_seqs_num\n";
	}
	
	$my_cur_TF_seq_num = 0;
	$prev_TF_id = $cur_TF_id;
	
	
	undef @cur_TF_seqs;
	my @cur_TF_seqs;
	
	undef @cur_TF_seqs_names;
	my @cur_TF_seqs_names;
	
	
  }
  
  push(@cur_TF_seqs, $cur_seq);
  push(@cur_TF_seqs_names, $cur_seq_name);
  $my_cur_TF_seq_num = $my_cur_TF_seq_num + 1;
  
}

close(STAT_OUTFILE);

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub PrintTFStab
{
	
	my ($TF_seqs_ptr, $TF_seqs_names_ptr, $TF_id) = @_;
	
	print STDERR "DEBUG: PrintTFStab:$TF_id\n";
	
	my @print_TF_seqs = @$TF_seqs_ptr;
	my @print_TF_seqs_names    = @$TF_seqs_names_ptr;
	
	my @len_count;
	my @is_legal;
	
	for (my $i = 0; $i < 100; ++$i)
	{
		$len_count[$i] = 0;
		$is_legal[$i] = 0;
	}
	
	my $num_of_records = scalar(@print_TF_seqs);
	my $cur_seq;
	my $cur_is_legal;
	for (my $i = 0; $i < $num_of_records; ++$i)
	{
		$cur_seq = $print_TF_seqs[$i];
		$cur_is_legal = &IsLegalSeq($cur_seq);
		$is_legal[$i] = $cur_is_legal;
		
		
		my $cur_seq_len_i = length($cur_seq);
		print STDERR "seq:$cur_seq| legal:$cur_is_legal| len:$cur_seq_len_i \n";
		if ($cur_is_legal > 0)
		{
			$len_count[$cur_seq_len_i] = $len_count[$cur_seq_len_i] + 1;
			print STDERR "Adding count to length:$cur_seq_len_i, count:$len_count[$cur_seq_len_i]\n";
		}
	}
	
	my $max_count = $len_count[0];
	my $max_count_i = 0;
	my $total_seq_num = 0;
	
	for (my $i = 0; $i < 100; ++$i)
	{
		if ($len_count[$i] > $max_count)
		{
			$max_count = $len_count[$i];
			$max_count_i = $i;
		}
		
		$total_seq_num = $total_seq_num + $len_count[$i];
	}
	
	print STDERR "max_count:$max_count| max_count_i:$max_count_i\n";
	
	my $seq_num = 0;
	
	open(OUTFILE, ">$stab_dir/$TF_id.stab") or die "could not open test out file: $stab_dir/$TF_id.stab\n";
	
	
	for (my $i = 0; $i < $num_of_records; ++$i)
	{
		$cur_seq = $print_TF_seqs[$i];
		
		$cur_seq = uc($cur_seq);
		
		if ($is_legal[$i] > 0 && length($cur_seq) == $max_count_i )
		{
			print OUTFILE "$print_TF_seqs_names[$i]\t$cur_seq\n";
			$seq_num = $seq_num + 1;
		}
	}
	close(OUTFILE);
	
	
	return ($TF_id,$seq_num, $num_of_records, $max_count_i);
}
	
	
# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub IsLegalSeq
{
	print STDERR "DEBUG: IsLegalSeq\n";
	
	my ($test_seq) = @_;
	
	my $is_legal = 1;
	my @s = split(//, $test_seq, -1);
	
	for (my $i = 0; $i < $#s; $i++)
	{
		if ($s[$i] ne "A" && $s[$i] ne "C" && $s[$i] ne "G" && $s[$i] ne "T" && $s[$i] ne "a" && $s[$i] ne "c" && $s[$i] ne "g" && $s[$i] ne "t")
		{
			print STDERR "ILEGAL seq:$test_seq\n";
		}
	}
	return ($is_legal);
}
	
	

__DATA__

parse_transfac_bs_2_stabs.pl <transfac bs.tab file (output of mat 2 bs)> <statistics file> <stab_dir >

Parses a transfac.tab file
(parse the output of parse_transfac_matrix_2_bs.pl)



