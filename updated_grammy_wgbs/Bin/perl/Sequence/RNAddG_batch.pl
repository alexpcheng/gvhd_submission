#!/usr/bin/perl

use strict;
use List::Util 'shuffle';

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

my $RNAHYBRID_EXE_DIR = "$ENV{GENIE_HOME}/Bin/RNAHybrid/RNAhybrid-2.1/src";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $utr_file = get_arg("utr", "", \%args);
my $mirna_file = get_arg("mirna", "", \%args);
my $subset_file = get_arg("subset", "", \%args);
my $n_experiments = get_arg("n", "1000", \%args);
my $dG_min = get_arg("dgmin", "15.0", \%args);
my $ddG_area = get_arg("ddgarea", "70", \%args);

my $echoed_args = 	echo_arg("noGU", \%args) . 
					echo_arg("f", \%args);
					
if ( (length($utr_file) == 0) || (length($mirna_file) == 0) )
{
	print STDOUT "Must supply both UTR and miRNA files.\n\n";
	print STDOUT <DATA>;
	exit;
}

my %mirna;
my %subset;
my $interaction_ID = 1;

# Read miRNA file and keep in hash #############################################

open(MIRNA, "<$mirna_file") or die "Could not open $mirna_file\n";
while(<MIRNA>)
{
	chomp;
	my @row = split(/\t/);

	$mirna{$row[0]} = $row[1];
}
print STDERR "Read " . keys(%mirna) . " miRNAs.\n";
close MIRNA;

# Read Subset file and keep in double-hash #####################################

if ($subset_file)
{
	my $subset_counter = 0;
	
	print STDERR "Reading $subset_file\n";
	open(SUBSET, "<$subset_file") or die "Could not open $subset_file\n";
	while(<SUBSET>)
	{
		chomp;
		my @row = split(/\t/);
	
		$subset{$row[0]}->{$row[1]} = "1";
		$subset_counter++;
	}
	print STDERR "Read $subset_counter relations.\n";
	close SUBSET;
}

# Step over all UTRs ###########################################################

open(UTR, "<$utr_file") or die "Could not open $utr_file\n";
while(<UTR>)
{
	chomp;
	my @row = split(/\t/);

	print STDERR "\nProcessing $row[0]...";
		
	foreach my $current_mir (keys (%mirna))
	{
		my $dG_best 	= 999;
		my $ddG_best 	= 999;

		if ($subset_file) 
		{
			my $current_CG = $row[0];
			$current_CG =~ s/\-..//g ;

			if ($subset{$current_CG}->{$current_mir} != "1")
			{
				# print STDERR "$row[0] - $current_mir  not in subset. Skipping\n";
				next;
			}
		}
		
		# Call RNAHybrid 
		my @plain_hybrid = &RNAhybrid ($row[1], $mirna{$current_mir}, "$echoed_args -e $dG_min");
		
		# Process results of RNAhybrid -- keep best dG
		
		if (@plain_hybrid == 0) { next; }
		
		print STDERR "\n\t$interaction_ID\t$current_mir... ";
		print STDERR "Found " . @plain_hybrid . " result(s)... ";
		
		foreach my $resline (@plain_hybrid)
		{
			my @resrow = split (/\t/, $resline);			
			if ($resrow[2] < $dG_best) { $dG_best = $resrow[2]; }
		}
		print STDERR "best_dG=$dG_best; ";

		# Extract sequence around target and call RNAddG
		
		my %final_result = ();
		open (OUTFILE, ">tmp_1") || die "Can't open output file tmp_1.\n";				
		foreach my $resline (@plain_hybrid)
		{
			my @resrow = split (/\t/, $resline);
			my $start = $resrow[4];
			my $end   = $resrow[4] + $resrow[5] - 1;
			
			my @seq_area = &extract_sequence ($start, $end, $ddG_area, $ddG_area, $row[1]);
			
			print OUTFILE "$interaction_ID\t$seq_area[2]\t$seq_area[0];$seq_area[1];$mirna{$current_mir}\n";
			# QQQ print STDERR "start=$start; end=$end; length=$resrow[5]; after extract == start=$seq_area[0]; end=$seq_area[1]\n";
			
			my $sub_target = substr ($row[1], ($end - 8), 10);
			my $sub_mir = substr ($mirna{$current_mir}, 0, 9);
			
			my @seed_hybrid = &RNAhybrid ($sub_target, $sub_mir, "-e 0.1");
			my $seed_dG = "-";
			
			if (length (@seed_hybrid) == 1)
			{
				foreach my $seed_resline (@seed_hybrid)
				{
					my @seed_resrow = split (/\t/, $seed_resline);
					$seed_dG = $seed_resrow[2];
				}
			}
			
			$final_result{$interaction_ID} = "$row[0]\t$interaction_ID\t$start\t$end\t$current_mir\t$resrow[2]\t$seed_dG";
			$interaction_ID++;	
		}
		
		
		close OUTFILE;

		# Call RNAddG for *all* RNAHybrid results
		my @ddG_result = split (/\n/, `RNAddG.pl -quiet $echoed_args < tmp_1`);

		# Keep best ddG
		foreach my $resline (@ddG_result)
		{
			my @resrow = split (/\t/, $resline);
			if ($resrow[6] < $ddG_best) { $ddG_best = $resrow[6]; }
			$final_result{$resrow[0]} .= "\t$resrow[6]";
		}
		print STDERR "best_ddG=$ddG_best; ";
		
		
		# Loop on number of shuffles required
	
		my $dG_failed 	= 0;
		my $ddG_failed 	= 0;
		my $count		= 1;
		
		while (($count <= $n_experiments) && (!($dG_failed && $ddG_failed)) )
		{
		
			# Shuffle UTR
			my $shuffled = (join "", shuffle(split ("", $row[1])));
			
			# Run RNAHybrid
			my @shuffle_hybrid = &RNAhybrid ($shuffled, $mirna{$current_mir}, $dG_min);
			
			# Process results of RNAhybrid -- keep best dG
			
			if (@shuffle_hybrid == 0)
			{
				$count++;
				next;
			}
			
			print STDERR "\n\t" . ($interaction_ID - 1) . "_$count\t$current_mir... ";
			print STDERR "Found " . @shuffle_hybrid . " result(s)... ";
			
			my $dG_best_shuffle = 999;
			foreach my $resline (@shuffle_hybrid)
			{
				my @resrow = split (/\t/, $resline);			
				if ($resrow[2] < $dG_best_shuffle) { $dG_best_shuffle = $resrow[2]; }
			}
			print STDERR "dG_shuffle=$dG_best_shuffle ";

			# if best dG is better than unshuffled then $dG_failed			

			if (!$dG_failed && ($dG_best_shuffle <= $dG_best))
			{
				print STDERR "(dG FAILED) ";
				$dG_failed = $count;
			}
	
			if (!$ddG_failed)
			{

				# Extract sequence around target and call RNAddG
				
				open (OUTFILE, ">tmp_1") || die "Can't open output file tmp_1.\n";				
				foreach my $resline (@shuffle_hybrid)
				{
					my @resrow = split (/\t/, $resline);
					my $start = $resrow[4];
					my $end   = $resrow[4] + $resrow[5] - 2;
					
					my @seq_area = &extract_sequence ($start, $end, $ddG_area, $ddG_area, $shuffled);
					
					print OUTFILE "$count\t$seq_area[2]\t$seq_area[0];$seq_area[1];$mirna{$current_mir}\n";
				}
				close OUTFILE;
		
				# Call RNAddG for *all* RNAHybrid results
				my @ddG_result = split (/\n/, `RNAddG.pl -quiet < tmp_1`);
		
				# Keep best ddG
				my $ddG_best_shuffle = 999;
				foreach my $resline (@ddG_result)
				{
					my @resrow = split (/\t/, $resline);
					if ($resrow[6] < $ddG_best_shuffle) { $ddG_best_shuffle = $resrow[6]; }
				}
				print STDERR "ddG_shuffle=$ddG_best_shuffle ";
			
				# If best ddG is better than unshuffled then $ddG_failed
				if ($ddG_best_shuffle <= $ddG_best)
				{
					print STDERR "(ddG FAILED)";
					$ddG_failed = $count;
				}
			}
			
			$count++;
		}
		
		# Dump results of this hit
		
		foreach my $cur_result (keys (%final_result))
		{
			print $final_result{$cur_result};
			if ($dG_failed)  { print "\t$dG_failed\t-"; }  else { print "\t$n_experiments\t+"; }
			if ($ddG_failed) { print "\t$ddG_failed\t-"; } else { print "\t$n_experiments\t+"; }
			print "\n";
		}
	}	
	
}


print STDERR " Done.\n";

################################################################################

sub RNAhybrid {

	my $target_seq = $_[0];
	my $query_seq = $_[1];
	my $more_args = $_[2];
	
	my @results = ();

	#print STDERR "$RNAHYBRID_EXE_DIR/RNAhybrid -c -e -$energy -s 3utr_fly -f 2,6 $target_seq $query_seq \n";
	my @prog_result = split (/\n/, `$RNAHYBRID_EXE_DIR/RNAhybrid -c $more_args -s 3utr_fly -f 2,6 $target_seq $query_seq`);
	
	foreach my $resultline (@prog_result)
	{
		my @result = split (/:/, $resultline);
		
		
		#QQQ print STDERR "$result[7] dG = $result[4]\n$result[8]\n$result[9]\n$result[10]";
		
		# Calculate size of binding site
		
		my $count1;
		my $count2;
		
		$_ = $result[7]; $count1 = tr/A-Z//;
		$_ = $result[8]; $count2 = tr/A-Z//;
		
		my $totalcount = $count1 + $count2;
		
		while (chop ($result[9]) eq ' ')
		{
			if (chop ($result[10]) eq ' ')
			{
				$totalcount--;
			}
		}
		
		#QQQ print STDERR "   target_length = $totalcount\n";
		
		push (@results, "$result[0]\t$result[2]\t$result[4]\t$result[5]\t$result[6]\t$totalcount");
		
	}
	
	return @results;
}

################################################################################

sub extract_sequence {

	my $start_location = $_[0];
	my $end_location = $_[1];
	my $cur_us = $_[2];
	my $cur_ds = $_[3];
	my $sequence = $_[4];
	
	my $us_start = $start_location > $cur_us ? $start_location - $cur_us : 1;
	my $ds_end  = $end_location + $cur_ds < length($sequence) ? $end_location + $cur_ds : length($sequence);
	my $actual_start = $start_location - $us_start + 1;

	my $string = substr($sequence, $us_start - 1, ($ds_end - $us_start) + 1);
	
	my $actual_end = $actual_start + abs($end_location - $start_location);

	my @result = ($actual_start, $actual_end, $string);
	
	return @result;
}

		
__DATA__

RNAddG_batch.pl <file>

   -n <num>:          Number of shuffles to run
   -mirna   <file> :  stab file where miRNA sequences are found.
   -utr     <file> :  stab file where UTR sequences are found.
   -subset  <file> :  File containing paris of UTR, miRNA on which the search 
                      should be conducted. Any pair not in this set is skipped.
   -dgmin <num>    :  Minimal dG filter (default: -15.0, specify in positive numbers)
   -dgdarea<num>   :  Area around target that's folded when calculating ddG
                      (default: 70 bases)
                      