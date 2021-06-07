#!/usr/bin/perl

# %%%%%% NEED TO CHANGE it so when p3file is true, p3_output goes to a file rather than to the screen

# NOTE: Note that Cases 5A and 5B result in the same outcome, and so could be combined.
#       However, by keeping them separate we understand the difference between these cases and could more
#       easily implement different solutions for the two.


# =============================================================================
# Include
# =============================================================================
use strict;

use POSIX qw(ceil floor);
use List::Util qw(max);

require "$ENV{PERL_HOME}/Lib/load_args.pl";

# =============================================================================
# Define defaults for constants
# =============================================================================

my $mpl = 90; #max primer length we can order, regardless of expense
my $mnp = 60; #max "normal" primer length (regular price)
my $mpp = 25; #min primer priming (match of primer to template)
my $mhl = 35; #min hybridization length for stands for elongation (match of two ss DNA to each other for elongation)
my $mpe = 55; #min PCR elongation length (min PCR reaction)
my $xtra = 5; #extra mutation length allowed beyond $mhl

# Primer3 constants
my $primer3cmd = "stab2primers.pl "
					."-force_left_end "
					."-force_right_end "
					."-min_gc_clamp 0 "
					."-opt_size $mpp "
					."-min_size $mpp "
					."-opt_tm 53 "
					."-min_tm 45 "
					."-max_tm 300 "
					."-self_end_limit 300 "
					."-self_any 300 "
					."-poly_x_limit 300" ; 

my $primer_planA = "sort.pl -c0 7,12 -op0 min -n0 "
							."| filter.pl -c 2 -max 8 "
							."| filter.pl -c 3 -max 3 ";

my $primer_planA_lflank =	"| filter.pl -c 12 -min 49 "
							."| filter.pl -c 12 -max 62 "
							."| filter.pl -c 13 -max 8 "
							."| filter.pl -c 14 -max 3 ";

my $primer_planA_rflank =	"| filter.pl -c 7 -min 49 "
							."| filter.pl -c 7 -max 62 "
							."| filter.pl -c 8 -max 8 "
							."| filter.pl -c 9 -max 3 ";

my $head_one =				"| head -n 1";
							
							
my $primer_planB = "sort.pl -c0 7,12 -op0 min -n0 ";
								
my $primer_planB_lflank = 				"| filter.pl -c 12 -min 49 ";

my $primer_planB_rflank = 				"| filter.pl -c 7 -min 49 ";

								
								
#Couldn't find a case where both primers have Tm>=49, so choose the longest primers you are allowed to choose
my $choose_one_primer_planC = "sort.pl -c0 6,11 -op0 max -n0 -r"
								."| head -n 1";



# =============================================================================
# Main part
# =============================================================================

# reading arguments
if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA>;
   exit;
}


my %args = load_args(\@ARGV);
my $start_fn = get_arg("start", 0, \%args);
my $end_fn = get_arg("end", 0, \%args);
my $gxp_file = get_arg("gxp", 0, \%args);
my $left_flanker = get_arg("left_flanker", 0, \%args);
my $right_flanker = get_arg("right_flanker", 0, \%args);
my $p3_file = get_arg("p3output", 0, \%args);

if ($gxp_file && -e $gxp_file) {die("GXP output file $gxp_file already exists!\n");}

my $tmp_file  = "tmp_dsgn_" . time();
my $tmp_file2 = "tmp_mut_"  . time();
my $tmp_file3 = "tmp_mtch_" . time();
my $tmp_file4 = "tmp_p1_"   . time();
my $tmp_file5 = "tmp_p2_"   . time();
my $tmp_file6 = "tmp_p3_"   . time();
my $tmp_file7 = "tmp_p4_"   . time();
my $tmp_file8 = "tmp_hybr_" . time();



open(SEQS_START, $start_fn) or die("Could not open file '$start_fn'.\n");
open(SEQS_END, $end_fn) or die("Could not open file '$end_fn'.\n");
open(P3_FILE, ">$p3_file") or die("Could not open file '$p3_file'.\n");

my @lines_s = <SEQS_START>;
my @lines_e = <SEQS_END>;

unless ($#lines_s == $#lines_e) {
	die("ERROR: Start and End files do not have the same number of lines.\n\n");
}

if ($p3_file) {
	print P3_FILE "Primer3_OUTPUT\t",`parse_primer3.pl -header`;
}

for (my $i=0; $i<=$#lines_s; $i++) {
	my @line_s = split(/\t/,$lines_s[$i]);
	my @line_e = split(/\t/,$lines_e[$i]);
	
	my $alias_s = $line_s[0];
	my $alias_e = $line_e[0];
	
	my $seq_s = $line_s[1];
	my $seq_e = $line_e[1];
	
	chomp $seq_s;
	chomp $seq_e;
	
	my ($ref_indices, $p3_output, @result) = start_vs_end(\$seq_s,\$seq_e);
	
	
	#### HANDLE INDICES FOR SINGLE LINE
	if ($gxp_file) {
	
		#PREPARE CHR FILES TO LATER BECOME GENOMICA GXP FILES FOR VISUALIZING SEQUENCES & PRIMERS
		
		#DESIGNED
		open(TMP, ">>", $tmp_file) or die("Could not open file '$tmp_file'.\n");
		print TMP join("\t",$alias_e,1,$ref_indices->[0],"Designed $ref_indices->[0]bp",1),"\n";
		close(TMP);
		
		
		if ($ref_indices->[3] != length($seq_e)) {
			#MISMATCH AREA
			open(TMP2, ">>", $tmp_file2) or die("Could not open file '$tmp_file2'.\n");
			print TMP2 join("\t",$alias_e,$ref_indices->[1]+1,$ref_indices->[2]-1,"Mutation $ref_indices->[3]bp",1),"\n";
			close(TMP2);
			
			#MATCH AREA
			open(TMP3, ">>", $tmp_file3) or die("Could not open file '$tmp_file3'.\n");
			unless ($ref_indices->[1] == 0) {print TMP3 join("\t",$alias_e,1,$ref_indices->[1],"Match ".($ref_indices->[1])."bp",1),"\n";}
			unless (($ref_indices->[0]-$ref_indices->[2]+1) == 0) {print TMP3 join("\t",$alias_e,$ref_indices->[2],$ref_indices->[0],"Match ".($ref_indices->[0]-$ref_indices->[2]+1)."bp",1),"\n";}
			close(TMP3);
		} else {
			#MATCH AREA -- SEQUENCES MATCH
			open(TMP3, ">>", $tmp_file3) or die("Could not open file '$tmp_file3'.\n");
			print TMP3 join("\t",$alias_e,1,$ref_indices->[3],"Complete Match ".$ref_indices->[3]."bp",1),"\n";
			close(TMP3);
		}		

		
		#PRIMER 1 AREA
		if ($ref_indices->[4]) {
			open(TMP4, ">>", $tmp_file4) or die("Could not open file '$tmp_file4'.\n");
			print TMP4 join("\t",$alias_e,$ref_indices->[4],$ref_indices->[5],"Primer 1 ".($ref_indices->[5]-$ref_indices->[4]+1)."bp",1),"\n";
			close(TMP4);
		}
		
		#PRIMER 2 AREA
		if ($ref_indices->[6]) {
			open(TMP5, ">>", $tmp_file5) or die("Could not open file '$tmp_file5'.\n");
			print TMP5 join("\t",$alias_e,$ref_indices->[6],$ref_indices->[7],"Primer 2 ".($ref_indices->[7]-$ref_indices->[6]+1)."bp",1),"\n";
			close(TMP5);
		}
		
		#PRIMER 3 AREA
		if ($ref_indices->[8]) {
			open(TMP6, ">>", $tmp_file6) or die("Could not open file '$tmp_file6'.\n");
			print TMP6 join("\t",$alias_e,$ref_indices->[8],$ref_indices->[9],"Primer 3 ".($ref_indices->[9]-$ref_indices->[8]+1)."bp",1),"\n";
			close(TMP6);
		}

		#PRIMER 4 AREA
		if ($ref_indices->[10]) {
			open(TMP7, ">>", $tmp_file7) or die("Could not open file '$tmp_file7'.\n");
			print TMP7 join("\t",$alias_e,$ref_indices->[10],$ref_indices->[11],"Primer 4 ".($ref_indices->[11]-$ref_indices->[10]+1)."bp",1),"\n";
			close(TMP7);
		}

		#HYBRIDIZATION AREA
		if ($ref_indices->[6] && $ref_indices->[8]) {
			open(TMP8, ">>", $tmp_file8) or die("Could not open file '$tmp_file8'.\n");
			print TMP8 join("\t",$alias_e,$ref_indices->[8],$ref_indices->[7],"Hybridization ".($ref_indices->[7]-$ref_indices->[8]+1)."bp",1),"\n";
			close(TMP8);
		}
		
	}
	
	#### HANDLE RESULT FOR SINGLE LINE
	my $j;
	foreach $j (@result) {
		print $j,"\t";
	}
	
	print "\n";
	
	#### HANDLE Primer3 Output FOR SINGLE LINE
	
	if ($p3_file) {
		unless ($p3_output) {$p3_output = "Failed, default primers used.";}
		print P3_FILE "Primer3_OUTPUT\t$alias_e\t$p3_output\n";
	}
		
}

close(SEQS_START);
close(SEQS_END);
close(P3_FILE);

#### AFTER ALL LINES HAVE BEEN DEALT WITH, PREPARE GENOMICA GXP FILE
if ($gxp_file) {

	system  ("cat $tmp_file | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '0,0,255,1' > $tmp_file.gxt");
	system ("cat $tmp_file2 | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '255,0,0,1' > $tmp_file2.gxt");
	system ("cat $tmp_file3 | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '0,0,255,1' > $tmp_file3.gxt");
	system ("cat $tmp_file4 | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '0,255,0,1' > $tmp_file4.gxt");
	system ("cat $tmp_file5 | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '0,255,0,1' > $tmp_file5.gxt");
	system ("cat $tmp_file6 | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '0,255,0,1' > $tmp_file6.gxt");
	system ("cat $tmp_file7 | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '0,255,0,1' > $tmp_file7.gxt");
	system ("cat $tmp_file8 | lin.pl | cut.pl -f 2,1,3- | tab2feature_gxt.pl -c '0,255,255,1' > $tmp_file8.gxt");
	
	
	#system ("gxt2gxp.pl $tmp_file.gxt  > $gxp_file.designed.gxp");
	#system ("gxt2gxp.pl $tmp_file2.gxt > $gxp_file.mutation.gxp");
	#system ("gxt2gxp.pl $tmp_file3.gxt > $gxp_file.matching.gxp");
	#system ("gxt2gxp.pl $tmp_file4.gxt > $gxp_file.primer1.gxp");
	#system ("gxt2gxp.pl $tmp_file5.gxt > $gxp_file.primer2.gxp");
	#system ("gxt2gxp.pl $tmp_file6.gxt > $gxp_file.primer3.gxp");
	#system ("gxt2gxp.pl $tmp_file7.gxt > $gxp_file.primer4.gxp");
	#system ("gxt2gxp.pl $tmp_file8.gxt > $gxp_file.hybrid.gxp");
	
	
	system ("gxt2gxp.pl $tmp_file.gxt $tmp_file2.gxt $tmp_file3.gxt $tmp_file4.gxt $tmp_file5.gxt $tmp_file6.gxt $tmp_file7.gxt $tmp_file8.gxt > $gxp_file.gxp");
	system ("rm $tmp_file $tmp_file2 $tmp_file3 $tmp_file4 $tmp_file5 $tmp_file6 $tmp_file7 $tmp_file8");
	system ("rm $tmp_file.gxt $tmp_file2.gxt $tmp_file3.gxt $tmp_file4.gxt $tmp_file5.gxt $tmp_file6.gxt $tmp_file7.gxt $tmp_file8.gxt");

}


# =============================================================================
# Subroutines
# =============================================================================

sub start_vs_end {
	
	my ($ref_seq_s, $ref_seq_e) = @_;
	
	my @result = ();	
	my $ref_indices;
	my $p3_output = "";
	
	my ($s_match, $e_match) = match_ends($ref_seq_s,$ref_seq_e);


	# keep calling different cases,
	# if any case returns true or a value in the first element, return;
	
	# CASE 0

 	($ref_indices, $p3_output, @result)= case_0($ref_seq_s,$ref_seq_e);
 	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
 
 	# CASE 1
	
 	($ref_indices, $p3_output, @result) = case_1($ref_seq_s,$ref_seq_e,$s_match,$e_match);
 	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
 	
 	# CASE 2
 	
 	($ref_indices, $p3_output, @result) = case_2($ref_seq_s,$ref_seq_e,$s_match,$e_match);
 	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
 	
 	# CASE 3
 	
 	($ref_indices, $p3_output, @result) = case_3($ref_seq_s,$ref_seq_e,$s_match,$e_match);
 	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
 	
	# CASE 4
	
	($ref_indices, $p3_output, @result) = case_4($ref_seq_s,$ref_seq_e,$s_match,$e_match);
	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
	
	# CASE 5
 	
 	($ref_indices, $p3_output, @result) = case_5($ref_seq_s,$ref_seq_e,$s_match,$e_match);
 	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
 	
 	# CASE 6
 	
 	($ref_indices, $p3_output, @result) = case_6($ref_seq_s,$ref_seq_e,$s_match,$e_match);
 	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
 	
 	# CASE 7
 	
 	($ref_indices, $p3_output, @result) = case_7($ref_seq_s,$ref_seq_e,$s_match,$e_match);
 	if ($result[0]) {return ($ref_indices, $p3_output, @result);}
	
	# CASE FAIL
	
	my $mut_len = $e_match - $s_match - 1;
	
	@result = ("Could not find solution for this mutation. S_match is $s_match, E_match is $e_match. $mut_len bps.");
	my @indices = (length(${$ref_seq_e}),$s_match,$e_match,$e_match-$s_match-1);
	$p3_output = "Was not able to choose primers for this case.";
	return (\@indices, $p3_output, @result);
}

sub match_ends {

	my ($ref_seq_s, $ref_seq_e) = @_;

	my $s_match = 0;
	my $e_match = 0;	

	while (    ( $s_match < length(${$ref_seq_s}) )
			&& ( $s_match < length(${$ref_seq_e}) )
			&& ( substr(${$ref_seq_s},0,$s_match+1) eq substr(${$ref_seq_e},0,$s_match+1) )
	      ) 
	{
		$s_match++;		
	}
	
	# turn $s_match into the index for the last matching bp
	$s_match = $s_match - 1;
	
		
	while (    ( -$e_match < length(${$ref_seq_s}) )
			&& ( -$e_match < length(${$ref_seq_e}) )
			&& ( substr(${$ref_seq_s},$e_match-1) eq substr(${$ref_seq_e},$e_match-1) )
		  )
	{
		$e_match--;
	}
	
	$e_match = length(${$ref_seq_e}) + $e_match;
	
	return ($s_match,$e_match);
	
}

sub rc { #reverse_complements the input string
	
	my ($input) = @_;
	
	my $output = `echo "DUMMYNAME	$input" | stab2reverse_complement.pl | cut -f 2 `;
	
	chomp $output;
	
	return $output;

}

sub primer3 {


	my ($ref_seq_e,$right_or_left,$max_size) = @_;
	
	my $max_size_cmd = " -max_size ".max($max_size,$left_flanker,$right_flanker);
				
	my $pcr_size_cmd = " -pcr_product_size ".length(${$ref_seq_e})."-".length(${$ref_seq_e});

	my $flank_cmd = "";
	my $choose_one_primer_planA = $primer_planA;
	my $choose_one_primer_planB = $primer_planB;
	
	#allow forcing one of the primers to be an exact size via filtering the primer3 results
	if ($right_or_left) {
		if ($right_or_left eq "flank_left" && $left_flanker){
			$flank_cmd = "| filter.pl -c 15 -minl $left_flanker -maxl $left_flanker | filter.pl -c 16 -maxl $max_size";
			$choose_one_primer_planA .= $primer_planA_lflank . $head_one;
			$choose_one_primer_planB .= $primer_planB_lflank . $head_one;}
		elsif ($right_or_left eq "flank_right" && $right_flanker) {
			$flank_cmd = "| filter.pl -c 16 -minl $right_flanker -maxl $right_flanker | filter.pl -c 15 -maxl $max_size";
			$choose_one_primer_planA .= $primer_planA_rflank . $head_one;
			$choose_one_primer_planB .= $primer_planB_rflank . $head_one;}
	} else {
		$flank_cmd = "| filter.pl -c 15 -maxl $max_size | filter.pl -c 16 -maxl $max_size";
		$choose_one_primer_planA .= $primer_planA_lflank . $primer_planA_rflank . $head_one;
		$choose_one_primer_planB .= $primer_planB_lflank . $primer_planB_rflank . $head_one;
	}
	
	my $my_primer3cmd = $primer3cmd.$max_size_cmd.$pcr_size_cmd.$flank_cmd;
		
	my $p3_results =  `echo "DUMMYNAME	${$ref_seq_e}" | $my_primer3cmd | grep -v -P '^input' | $choose_one_primer_planA | cut.pl -i -f 1 `;
				
	unless ($p3_results) {$p3_results =  `echo "DUMMYNAME	${$ref_seq_e}" | $my_primer3cmd | grep -v -P '^input' | $choose_one_primer_planB | cut.pl -i -f 1`;}
	
	unless ($p3_results) {$p3_results =  `echo "DUMMYNAME	${$ref_seq_e}" | $my_primer3cmd | grep -v -P '^input' | $choose_one_primer_planC | cut.pl -i -f 1`;}
	
	
	
	#parse the result so you end up with  left, right, and output
	my $left = "";
	my $right = "";
	
	chomp($p3_results);
	
	if ($p3_results) {
		my @split_results = split(/\t/,$p3_results);
		$left = $split_results[14];
		$right = $split_results[15];
	} else {
		$p3_results = "Primer3 FAILED to choose primers, chose primers by default.";
		
		if ($right_or_left eq "flank_left" && $left_flanker) {
			$left = substr(${$ref_seq_e},0,$left_flanker);}
		else {		
			$left = substr(${$ref_seq_e},0,$mpp);}
			
		if ($right_or_left eq "flank_right" && $right_flanker) {
			$right = substr(${$ref_seq_e},length(${$ref_seq_e})-$right_flanker);}
		else {
			$right = substr(${$ref_seq_e},length(${$ref_seq_e})-$mpp);}

	}
	

	return ($left,$right,$p3_results);

}

# =============================================================================
# CASES Subroutines
# =============================================================================

sub case_0 {

	my ($ref_seq_s, $ref_seq_e) = @_;

	# Check if sequences match
	if (${$ref_seq_s} eq ${$ref_seq_e}) {
		my @result = ("CASE 0 : Sequences match");
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, ..
		my @indices = (length(${$ref_seq_e}),length(${$ref_seq_e}),1,length(${$ref_seq_e}));
		my $p3_output = "None needed for CASE 0.";
		return (\@indices, $p3_output, @result);
	} else { return;}

}


sub case_1 {
	# =================================================================================
	# CASE 1: promoter length is 0-90bp (0 to $mpl)
	# 		
	#   -> Order 1 primer.
	#   -> *no limit on mutations*
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;

	if (length(${$ref_seq_e}) <= $mpl) {
		my @result = ("CASE 1",${$ref_seq_e});  #DEBUG : consider returning more information, like what kind of experiment must be done
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, ..
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,1,length(${$ref_seq_e}));
		my $p3_output = "None needed for CASE 1.";
		return (\@indices, $p3_output, @result);
		
	} else {
		return;
	}
}

sub case_2 {
	# ======================================================================================
	# CASE 2: mutation is contained within 35bp ( ) of end,
	#			i.e., internal segments of "start" and "end" seqs match each other
	#				  and "end" has no more than 35 "new" bps attached to either end of this
	#				  matching segment.
	#		  also, matching internal segment must be at least 80bp ($mpp + $mpe)
	#     
	#   -> Order 2 primers to PCR internal segment + designed ends.
	#   -> *allows for up to 35bp mutations on ends of matching internal segment*
	# ========================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;
	
	#DEBUG : need a better way of finding the matching internal segment,
	#        imagine if there were a hidden segment of 80bp somewhere in the long promoters,
	#        we actually need to do some MSA or needle.pl to find this..
	
	#DEBUG : temporary algorithm forces internal segment to touch one of the promoter boundarys,
    #        limiting us to mutations on only one end of the promoter.    
   
   # DEBUG : here is a crucial part of the temporary algorithm, one end must not match
   
   # How do we know if Case 2 applies here? :
   # 	(1) The match indices should be 35bps or less from each other,
   #		(this means at least one of them has changed, since a promoter of length 35 would have matched Case 1)
   #	(2) One of the match indices should still match its original value
   my $mut_len = ($e_match-$s_match-1);
   
   if ( $mut_len <= ($mnp - $mpp) ) {
   

   		if ($s_match == -1) { # Mismatch is on the left boundary
   			
   			if ( (length(${$ref_seq_e}) - $e_match - 1) > ($mpp + $mpe) ) # Make sure we meet minimum priming and PCR elongation lengths
   			{
					   
				my $right_match = substr(${$ref_seq_e},$e_match);
				#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
				my ($p3_left,$p3_right,$p3_output) = primer3(\$right_match,"flank_right",$mnp-$mut_len);
			
				# ZERO BASED INDICES FOR PRIMERS
				my @p1 = (0,$e_match + length($p3_left) -1);
				my @p2 = (length(${$ref_seq_e})-length($p3_right),length(${$ref_seq_e})-1);
			
				my $left_primer = substr(${$ref_seq_e},$p1[0],$p1[1]-$p1[0]+1);
				my $right_primer = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
				
			
				my @result = ("CASE 2",$left_primer,$right_primer);
				
				#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
				my @indices = (length(${$ref_seq_e}),0,$e_match+1,$e_match-$s_match-1,$p1[0]+1,$p1[1]+1,$p2[0]+1,$p2[1]+1);
				
				return (\@indices, $p3_output, @result);
   				
   			} #DEBUG : Should test properties of all possible primers. Right primer from 25bp to 60bp ($mpp to $mnp). Left primer from ($e_match + $mpp to $mnp)
   			
   		} elsif ($e_match == length(${$ref_seq_e}) ) { # Mismatch is on the right boundary
   			
   			
   			if ($s_match > ($mpp + $mpe)) # Make sure we meet minimum priming and PCR elongation lengths
   			{
   				
   				my $left_match = substr(${$ref_seq_e},0,$s_match+1);
				#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
				my ($p3_left,$p3_right,$p3_output) = primer3(\$left_match,"flank_left",$mnp-$mut_len);
   			
   				# ZERO BASED INDICES FOR PRIMERS
				my @p1 = (0,length($p3_left)-1);
   				my @p2 = ($s_match+1-length($p3_right),length(${$ref_seq_e})-1);
   				
   				my $left_primer = substr(${$ref_seq_e},$p1[0],$p1[1]-$p1[0]+1);
   				my $right_primer = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
   				
   				my @result = ("CASE 2",$left_primer,$right_primer);
   				
   				#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
				my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,$p1[0]+1,$p1[1]+1,$p2[0]+1,$p2[1]+1);
				
				return (\@indices, $p3_output, @result);
   			
   			} #DEBUG : Should test properties of all possible primers. Left primer from 25bp to 60bp ($mpp to $mnp). Right primer from ($s_match -1 + $mpp to $mnp)
   				
   		} else {return;}
   		
   }

}

sub case_3 {
	# =================================================================================
	# CASE 3: promoter length is 91-145bp ($mpl+1 to $mplx2 - $mhl)
	# 		
	#   -> Order 2 primers.
	#   -> *no limit on mutations*
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;
	
	if (    (length(${$ref_seq_e}) > $mpl)
		 &&	(length(${$ref_seq_e}) <= (2*$mpl - $mhl))
	   )
	{
		# ZERO BASED INDICES FOR PRIMERS
		my @p2 = (0,floor(length(${$ref_seq_e})/2)+ceil($mhl/2)-1);
   		my @p3 = (floor(length(${$ref_seq_e})/2)-floor($mhl/2),length(${$ref_seq_e})-1);
   				
   		my $left_oligo = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
   		my $right_oligo = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
   		
		my @result = ("CASE 3",$left_oligo,$right_oligo); #DEBUG : consider returning more information, like what kind of experiment must be done
	
	   	#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,0,0,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1);
		
		my $p3_output = "None needed for CASE 3";

		return (\@indices, $p3_output, @result);
	} else {
		return;
	}

}

sub case_4 {
	# =================================================================================
	# CASE 4: mutation boundary is more than 80bp ($mpp + $mpe) from either end
	#         and mutation in designed region is no longer than $mhl 
	# 		
	#   -> Order 2 primer PAIRS.
	#   -> *mutation limit of 35bp ($mnp - $mpp) segment*
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;

	# Check that mutation boundary is ($mpp + $mpe) bps away from either end
	# And that mutation is at most $mhl + extra in length
	if (    ( ($s_match+1) >= ($mpp + $mpe) )
		 && ( (length(${$ref_seq_e})-$e_match) >= ($mpp + $mpe) )
		 && ( ($e_match-$s_match-1) <= $mhl + $xtra)
	   )
	{
		# LENGTH OF MAX MUTATION MINUS ACTUAL MUTATION LENGTH
		my $q = $mhl - ($e_match-$s_match-1);
		my $qp = $q;
		if ($q < 0) {$qp=0;}
		

		# PRIMER3 for LEFT PCR SEGMENT
		my $left_match = substr(${$ref_seq_e},0,$s_match+1);
		
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_ll,$p3_lr,$p3_output_left) = primer3(\$left_match,"flank_left",floor($mpp+$qp/2));
				
		# ZERO BASED INDICES FOR PRIMERS
		my @p1 = (0,length($p3_ll)-1);
		#my @p2 = ($s_match+1-length($p3_lr),($s_match-length($p3_lr)-1)+($mhl+length($p3_lr))-(ceil($q/2))-1);
		my @p2 = ($s_match+1-length($p3_lr),$s_match+$mhl-ceil($q/2));

		# PRIMER3 for RIGHT PCR SEGMENT
		my $right_match = substr(${$ref_seq_e},$e_match);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_rl,$p3_rr,$p3_output_right) = primer3(\$right_match,"flank_right",floor($mpp+$qp/2));
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p3 = ($e_match-$mhl+(floor($q/2)),($e_match-$mhl)+($mhl+length($p3_rl))-1);
		my @p4 = (length(${$ref_seq_e})-length($p3_rr),length(${$ref_seq_e})-1);
				
		my $left_left_primer = substr(${$ref_seq_e},$p1[0],$p1[1]-$p1[0]+1);
		my $left_right_primer = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_left_primer = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
		my $right_right_primer = rc(substr(${$ref_seq_e},$p4[0],$p4[1]-$p4[0]+1));
		
		my @result = ("CASE 4",$left_left_primer,$left_right_primer,$right_left_primer,$right_right_primer);
		#First primer can be 25->$mnp(60).
		#Second primer must include mismatch area, must have $mpp(25) match to left of mismatch, then you have room to expand further left or further right as desired, with length = $mnp (60).
		#Same flexibility in reverse for 3rd & fourth primers
		
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,$p1[0]+1,$p1[1]+1,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1,$p4[0]+1,$p4[1]+1);
		
		return (\@indices, "$p3_output_left\t$p3_output_right", @result);
		
	} else {return;}

}

sub case_5 {
	# =================================================================================
	# CASE 5: designed DNA length more than 145bp (2*$mpl - $mhl) but less than 195bp ($mhl + 2*$mpp + 2*mpe)
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;
		
	if (    ( length(${$ref_seq_e}) > (2*$mpl - $mhl) )
		 && ( length(${$ref_seq_e}) < ($mhl + 2*($mpp+$mpe)) ) 
       )
    {
    	my @result = ();
    	    	
    	# CASE 5A
    	@result = case_5A($ref_seq_s,$ref_seq_e,$s_match,$e_match);
		if ($result[0]) {return @result;}
    	
    	# CASE 5B
    	@result = case_5B($ref_seq_s,$ref_seq_e,$s_match,$e_match);
		if ($result[0]) {return @result;}
		
    } else {return;}

}

sub case_5A {
	# =================================================================================
	# CASE 5A: designed DNA length more than 145bp (2*$mpl - $mhl) but less than 195bp ($mhl + 2*$mpp + 2*mpe)
	#          and, mutation is 80bp ($mpp + $mpe) from end P but not from end Q
	#
	#   -> Order oligo for end Q, PCR for end P, potentially with very long primer if mutation boundary further than 90bp from Q
	#   -> *No limit on mutations up to 90bp ($mpl) away from end closest to mutation + 24bp ($mhl -$mpl -$mpp -$mpe +1) past 90bp ($mpl) index*
	#
	#   ** POTENTIAL PROBLEMS : ordering a very long oligo as a PCR primer**
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;
				
	if ( $s_match+1 >= ($mpp + $mpe) )
	{
		# Mutation boundary is at least ($mpp + $mpe) basepairs away from left end,
		# but not from right end because otherwise CASE 4 would have kicked in.
				
		# We are ordering a long oligo for the right end, if it does not contain 
		# the whole mutation, we must extend one of the primers for the left end accordingly
		my $extend_by = length(${$ref_seq_e}) - $mpl - $s_match - 1;
		
		unless ($extend_by >= 0) {$extend_by = 0;}
		
		# PRIMER3 for LEFT PCR SEGMENT
		my $left_match = substr(${$ref_seq_e},0,$s_match+1);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$left_match,"flank_left",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p1 = (0,length($p3_l)-1);
		my @p2 = ($s_match-length($p3_r)+1,($s_match+$extend_by+$mhl));
		my @p3 = ($s_match+$extend_by+1,length(${$ref_seq_e})-1);

		my $left_left_primer = substr(${$ref_seq_e},$p1[0],$p1[1]-$p1[0]+1);
		my $left_right_primer = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_oligo = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
		
		my @result = ("CASE 5A, oligo right end",$left_left_primer,$left_right_primer,$right_oligo);
		# 1st primer could be extended from $mpp to $mnp
		# 2nd primer may have flexibility in accordance with varying 3rd primer which is a long oligo
				
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,$p1[0]+1,$p1[1]+1,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1);
		
		return (\@indices, $p3_output, @result);
		
	} elsif ( (length(${$ref_seq_e})-$e_match) >= ($mpp + $mpe) )
	{
		# Mutation boundary is at least ($mpp + $mpe) basepairs away from right end,
		# but not from left end.
		
		# We are ordering a long oligo for the left end, if it does not contain 
		# the whole mutation, we must extend one of the primers for the left end accordingly
		my $extend_by = $e_match - $mpl;
		
		unless ($extend_by >= 0) {$extend_by = 0;}
		
		# PRIMER3 for RIGHT PCR SEGMENT
		my $right_match = substr(${$ref_seq_e},$e_match);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$right_match,"flank_right",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p2 = (0,$e_match-$extend_by-1);
		my @p3 = ($e_match-$extend_by-$mhl,$e_match+length($p3_l)-1);
		my @p4 = (length(${$ref_seq_e})-length($p3_r),length(${$ref_seq_e})-1);

		my $left_oligo = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_left_primer = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
		my $right_right_primer = rc(substr(${$ref_seq_e},$p4[0],$p4[1]-$p4[0]+1)); 

		my @result = ("CASE 5A, oligo left end",$left_oligo,$right_left_primer,$right_right_primer);
		# 3rd primer could be extended from $mpp to $mnp
		# 2nd primer may have flexibility in accordance with varying 1rd primer which is a long oligo
		
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,0,0,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1,$p4[0]+1,$p4[1]+1);
		
		return (\@indices, $p3_output, @result);
		
	} else {return;}

}

sub case_5B {
	# =================================================================================
	# CASE 5B: designed DNA length more than 145bp (2*$mpl - $mhl) but less than 195bp ($mhl + 2*$mpp + 2*mpe)
	#          and, mutation is less than 80bp ($mpp + $mpe) from both ends
	#
	#   -> Order oligo for end Q, PCR for end P, potentially with very long primer if mutation boundary further than 90bp from Q
	#   -> Choose to PCR end that is farthest away from a mutation boundary, so to violate $mpe the least.
	#   -> *No limit on mutations up to 90bp ($mpl) away from end closest to mutation + 24bp ($mhl -$mpl -$mpp -$mpe +1) past 90bp ($mpl) index*
	#
	#   ** POTENTIAL PROBLEMS : ordering a very long oligo as a PCR primer**
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;
	
	# Mutation boundary should already be less than 80bp ($mpp + $mpe) from both ends,
	# by virtue of having failed the previous cases. If not, we have a problem.
	if (    ($s_match + 1) >= ($mpp + $mpe)	
		 || (length(${$ref_seq_e}) - $e_match) >= ($mpp + $mpe)	
	   ) 
	{	return "Problem in Case 5B : Mutation boundary is more than ($mpp + $mpe) from at least one end of DNA";
	}
	  
	if ( ($s_match + 1) >= (length(${$ref_seq_e}) - $e_match) ) 
	{ 
		# Left end is further from mutation
		
		# We are ordering a long oligo for the right end, if it does not contain 
		# the whole mutation, we must extend one of the primers for the left end accordingly
		my $extend_by = length(${$ref_seq_e}) - $mpl - $s_match - 1;
		
		unless ($extend_by >= 0) {$extend_by = 0;}
		
		# PRIMER3 for LEFT PCR SEGMENT
		my $left_match = substr(${$ref_seq_e},0,$s_match+1);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$left_match,"flank_left",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p1 = (0,length($p3_l)-1);
		my @p2 = ($s_match-length($p3_r)+1,($s_match+$extend_by+$mhl));
		my @p3 = ($s_match+$extend_by+1,length(${$ref_seq_e})-1);
		
		my $left_left_primer = substr(${$ref_seq_e},$p1[0],$p1[1]-$p1[0]+1);
		my $left_right_primer = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_oligo = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
		
		my @result = ("CASE 5B, oligo right end",$left_left_primer,$left_right_primer,$right_oligo);
		# 1st primer could be extended from $mpp to $mnp
		# 2nd primer may have flexibility in accordance with varying 3rd primer which is a long oligo
				
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,$p1[0]+1,$p1[1]+1,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1);
		
		return (\@indices, $p3_output, @result);
		
	} else {
	
		# Right end is further from mutation
		
		# We are ordering a long oligo for the right end, if it does not contain 
		# the whole mutation, we must extend one of the primers for the left end accordingly
		my $extend_by = $e_match - $mpl;
		
		unless ($extend_by >= 0) {$extend_by = 0;}
		
		# PRIMER3 for RIGHT PCR SEGMENT
		my $right_match = substr(${$ref_seq_e},$e_match);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$right_match,"flank_right",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p2 = (0,$e_match-$extend_by-1);
		my @p3 = ($e_match-$extend_by-$mhl,$e_match+length($p3_l)-1);
		my @p4 = (length(${$ref_seq_e})-length($p3_r),length(${$ref_seq_e})-1);
		
		my $left_oligo = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_left_primer = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
		my $right_right_primer = rc(substr(${$ref_seq_e},$p4[0],$p4[1]-$p4[0]+1));
				
		my @result = ("CASE 5B, oligo left end",$left_oligo,$right_left_primer,$right_right_primer);
		# 3rd primer could be extended from $mpp to $mnp
		# 2nd primer may have flexibility in accordance with varying 1rd primer which is a long oligo
		
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,0,0,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1,$p4[0]+1,$p4[1]+1);
				
		return (\@indices, $p3_output, @result);
	
	}

}

sub case_6 {
	# =================================================================================
	# CASE 6: Mutation is fully contained within 90bp ($mpl) from an end,
	#         and mutation boundary is at least 80bp from other end, otherwise CASE 5 would apply
	# 		
	#   -> Order long $mpl oligo for that end, PCR the other end with 2 primers.
	#   -> *allows for any mutation 90bp from one end*
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;

	if ($e_match <= $mpl)
	{
		# Mutation is fully contained within $mpl from left side
		
		# PRIMER3 for RIGHT PCR SEGMENT
		my $right_match = substr(${$ref_seq_e},$e_match);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$right_match,"flank_right",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p2 = (0,$e_match-1);
		my @p3 = ($e_match-$mhl,$e_match+length($p3_l)-1);
		my @p4 = (length(${$ref_seq_e})-length($p3_l),length(${$ref_seq_e})-1);
		
		my $left_oligo = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_left_primer = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
		my $right_right_primer = rc(substr(${$ref_seq_e},$p4[0],$p4[1]-$p4[0]+1));
		
		my @result = ("CASE 6, oligo left end",$left_oligo,$right_left_primer,$right_right_primer);
		# 3rd primer could go from $mpp to $mnp
		# 2nd primer and 1st oligo can change in relation to each other, depending on mutation boundary
		
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,0,0,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1,$p4[0]+1,$p4[1]+1);
				
		return (\@indices, $p3_output, @result);
	
	} elsif ( (length(${$ref_seq_e})-$s_match-1) <= $mpl)
	{
		# Mutation is fully contained within $mpl from right side
		
		# PRIMER3 for LEFT PCR SEGMENT
		my $left_match = substr(${$ref_seq_e},0,$s_match+1);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$left_match,"flank_left",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p1 = (0,length($p3_l)-1);
		my @p2 = ($s_match-length($p3_r)+1,($s_match+$mhl));
		my @p3 = ($s_match+1,length(${$ref_seq_e})-1);

		my $left_left_primer = substr(${$ref_seq_e},$p1[0],$p1[1]-$p1[0]+1);
		my $left_right_primer = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_oligo = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
				
		my @result = ("CASE 6, oligo right end",$left_left_primer,$left_right_primer,$right_oligo);
		# 1st primer could go from $mpp to $mnp
		# 2nd primer and 3rd oligo can change in relation to each other, depending on mutation boundary
		
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,$p1[0]+1,$p1[1]+1,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1);
				
		return (\@indices, $p3_output, @result);
		
	} else {return;}

}

sub case_7 {
	# =================================================================================
	# CASE 7: Mutation overlaps 80bp ($mpp+$mpe) and 90bp ($mpl) indices relative to one end
	#
	#   -> Order oligo for end closest to mutation (call it Q), PCR for end P, with longer than normal primer depending on distance mutation boundary is further than 90bp from Q
	#   -> *No limit on mutations up to 90bp ($mpl) away from end closest to mutation + 24bp ($mhl -$mpl -$mpp -$mpe +1) past 90bp ($mpl) index*
	#
	#   ** POTENTIAL PROBLEMS : ordering a very long oligo as a PCR primer**
	# =================================================================================
	
	my ($ref_seq_s, $ref_seq_e, $s_match, $e_match) = @_;
	
	if (    ($s_match + 1) < ($mpp+$mpe)
		 && $e_match > $mpl
	   )
	{
		# Mutation overlaps 80bp ($mpp+$mpe) and 90bp ($mpl) indices relative to left end
		

		
		# We are ordering a long oligo for the right end, if it does not contain 
		# the whole mutation, we must extend one of the primers for the left end accordingly
		my $extend_by = $e_match - $mpl;
		
		unless ($extend_by >= 0) {$extend_by = 0;}
		
		# PRIMER3 for RIGHT PCR SEGMENT
		my $right_match = substr(${$ref_seq_e},$e_match);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$right_match,"flank_right",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p2 = (0,$mpl-1);
		my @p3 = ($e_match-$extend_by-$mhl,$e_match+length($p3_l)-1);
		my @p4 = (length(${$ref_seq_e})-length($p3_r),length(${$ref_seq_e})-1);

		my $left_oligo = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_left_primer = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
		my $right_right_primer = rc(substr(${$ref_seq_e},$p4[0],$p4[1]-$p4[0]+1));
				
		my @result = ("CASE 7, oligo left end",$left_oligo,$right_left_primer,$right_right_primer);
		# 3rd primer could be extended from $mpp to $mnp
		# 2nd primer may have flexibility in accordance with varying 1rd primer which is a long oligo
		
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,0,0,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1,$p4[0]+1,$p4[1]+1);
		
		return (\@indices, $p3_output, @result);
			
	} elsif (    ( (length(${$ref_seq_e})-$s_match-1) > $mpl )
			  && ( (length(${$ref_seq_e})-$e_match) < ($mpp+$mpe) )
			)
	{
		# Mutation overlaps 80bp ($mpp+$mpe) and 90bp ($mpl) indices relative to right end
		
		# We are ordering a long oligo for the right end, if it does not contain 
		# the whole mutation, we must extend one of the primers for the left end accordingly
		my $extend_by = length(${$ref_seq_e}) - $mpl - $s_match - 1;
		
		unless ($extend_by >= 0) {$extend_by = 0;}
		
		# PRIMER3 for LEFT PCR SEGMENT
		my $left_match = substr(${$ref_seq_e},0,$s_match+1);
		#feed the matching portion of the sequence to the right of the mismatch into primer3, we will add on 
		my ($p3_l,$p3_r,$p3_output) = primer3(\$left_match,"flank_left",$mpp);
		
		# ZERO BASED INDICES FOR PRIMERS
		my @p1 = (0,length($p3_l)-1);
		my @p2 = ($s_match-length($p3_r)+1,$s_match+$extend_by+$mhl);
		my @p3 = (length(${$ref_seq_e})-$mpl,length(${$ref_seq_e})-1);
		
		my $left_left_primer = substr(${$ref_seq_e},$p1[0],$p1[1]-$p1[0]+1);
		my $left_right_primer = rc(substr(${$ref_seq_e},$p2[0],$p2[1]-$p2[0]+1));
		
		my $right_oligo = substr(${$ref_seq_e},$p3[0],$p3[1]-$p3[0]+1);
				
		my @result = ("CASE 7, oligo right end",$left_left_primer,$left_right_primer,$right_oligo);
		# 1st primer could be extended from $mpp to $mnp
		# 2nd primer may have flexibility in accordance with varying 3rd primer which is a long oligo
		
		#indices: length of designed sequence, start mutation idx, end mutation index, length mutation, primer1 left, p1 right, p2 l, p2 r, p3 l, p3 r, p4 l, p4 r
		my @indices = (length(${$ref_seq_e}),$s_match+1,$e_match+1,$e_match-$s_match-1,$p1[0]+1,$p1[1]+1,$p2[0]+1,$p2[1]+1,$p3[0]+1,$p3[1]+1);
				
		return (\@indices, $p3_output, @result);
		
	} else {return;}

}




# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

primers_for_DNA_mutation.pl -start <file name 1> -end <file name 2>

	This script outputs primers that can be used to mutate the DNA sequences
	in the "-start" file into the DNA sequences in the "-end" file. The files
	must have the same number of lines. The line numbers in the files must
	correspond to each other -- that is, the sequence in the "-start" file
	found on line 72 will be mutated to the sequence in the "-end" file in 
	line 72.
	
	The mutation area must be a single, contiguous area of no more than 35 bps. However,
	if the mutation area starts at a promoter end, it may be up to 90 bps in length.
	
	-start <FILENAME>	  	:  STAB file of sequences prior to mutation. 
	-end <FILENAME>     	:  STAB file of sequences as they would look after mutation.
	-gxp <FILENAME>	   		:  Create a Genomica gxp file to display the sequences and planned primers.
	-left_flanker <NUM> 	:  Entered sequences have this number of common flanking bps on their 5' ends. (this will result in output of common primers to match 5' flankers of all sequences entered)
	-right_flanker <NUM> 	:  Entered sequences have this number of common flanking bps on their 3' ends. (this will result in output of common primers to match 3' flankers of all sequences entered)
	-p3output <FILENAME> 	:  Create an output file listing the properties of the chosen primers, as output by Primer3