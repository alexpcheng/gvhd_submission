#!/usr/bin/perl

use strict;
use List::Util qw[shuffle min max];

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAHYBRID_EXE_DIR = "$ENV{GENIE_HOME}/Bin/RNAHybrid/RNAhybrid-2.1/src";
my $RNAddG_EXE_DIR 		= "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs/";


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

my $dG_min = get_arg("dgmin", "15.0", \%args);
my $ddG_area = get_arg("ddgarea", "70", \%args);
my $FULL_TL  = get_arg("tl", "30", \%args);
my $DDG_OPEN  = get_arg("dgtl", "25", \%args);
my $no3max = get_arg("no3max", 0, \%args);

# Step over all Locations ###########################################################

while(<$file_ref>)
{
	chomp;
	my @row = split(/\t/);
	my $endpos = $row[2];
	my $miRNA = $row[7];
	my $utr = $row[8];
	
	print STDERR "\nProcessing $row[1] on $row[0]...";
		
	# Calculate begining of target but make sure we're still in the UTR
	
	my $startpos  = max ($endpos - $FULL_TL + 1, 1);
	my $openstart = max ($endpos - $DDG_OPEN + 1, 1);
	
	my $targetLen = $endpos - $startpos + 1;
	my $target    = substr ($utr, $startpos - 1, $targetLen);

# QQQ	print STDERR "miR = $miRNA; target = $target\n";

	if ($targetLen < 11)
	{
		print STDERR "Target is too short (below 11 bases). Skipping\n";
		next;
	}	

	print "\n\n$row[1] on $row[0] (ends $endpos): $row[4],$row[5],$row[6] [miRNA=$miRNA, target=$target]\n";

	my $dGall    = &getdG  ($miRNA, 1, 999, $target, 1, 30);

	# Call RNAduplex  ########################################################
	
	open (SEQFILE, ">tmp_seqfile") or die ("Could not open temporary sequence file.\n");
	print SEQFILE "$target\n$miRNA\n";
	close (SEQFILE);
	
	my $resline = `$RNAddG_EXE_DIR/RNAduplex < tmp_seqfile`;
	chomp ($resline);
	# $resline =~ m/ \((.*)\)/;
	#print "$dGall\n\n$resline\n";	
}

print STDERR " Done.\n";

################################################################################

sub getdG {

	my ($miRNA, $miR_start, $miR_len, $target, $target_start, $target_len) = @_ ;

	# Build miR and target substrings

	my $submiR    = substr ($miRNA, $miR_start-1, $miR_len);
	my $subtarget = reverse (substr (reverse($target), $target_start-1, $target_len)); 

	# Call RNAHybrid and extract result dG
	
	my $prog_line = "$RNAHYBRID_EXE_DIR/RNAhybrid -c -s 3utr_fly -b 1 $subtarget $submiR";
	my @prog_result = split (/\n/, `$prog_line`);
	if (@prog_result != 1)
	{
		print STDERR "Cound not hybrid.\n";
		print STDERR "Program call was: $prog_line\n";
		print STDERR "Result was: " . join ("\n", @prog_result);
		exit;
	}
	
	
	# QQQ print STDERR "Program call was: $prog_line\n";
	
	my @result = split (/:/, $prog_result[0]);
	my $dG = $result[4];
	
	print "\n$result[7]\n$result[8]\n$result[9]\n$result[10]\tdG=$dG\n";
	
	return $dG;
}

################################################################################

sub getddG {

	my ($miRNA, $utr, $startpos, $endpos, $ddG_area, $dGall, $ddGver) = @_ ;
	
	# Extract area around sequence
	my @seq_area = &extract_sequence ($startpos, $endpos, $ddG_area, $ddG_area, $utr);

	# Call RNAddG
	open (OUTFILE, ">tmp_1") || die "Can't open output file tmp_1.\n";						
	print OUTFILE "ID\t$seq_area[2]\t$seq_area[0];$seq_area[1];$miRNA;$dGall\n";
	close OUTFILE;
	
	my $cmdline = "RNAddG" . $ddGver . ".pl -quiet < tmp_1";
	chomp (my $resline = `$cmdline`);
	my @ddG_values = split (/\t/, $resline);
		
	return $ddG_values[6];
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

RNAddG_compute.pl <file>

	Compute the dG energies of potential target sites whose seed is given in the external
	tab file.
	
	Output consists of the input ID, followed by those dG values:
	    
        Type         miRNA coordinates           Target coordinates
        ====         =================           ==================
        dG all       nt 1 and up                 nt 1-30
        dG 5'        nt 1-9                      nt 1-9
        dG 3'        nt 10 and up                nt 10-30
        dG 3' max    nt 10 and up                Reverse complement of
                                                 miRNA bases 10 and up
        dG 3' ratio
		
    -tl <num>:      Maximal target length (default: 30)
    -no3max:        Do not compute 3' max value and ratio (saves time)
    
    
 