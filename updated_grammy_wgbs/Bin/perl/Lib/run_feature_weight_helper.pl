#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/System/q_util.pl";




#-------------------------------------------------------------------------
#
#------------------------------------------------------------------------
sub CollectLikelihoodResultsFromFile
{
	my ($likelihood_file_path) = @_;
	
	print "CollectLikelihoodResultsFromFile (DEBUG): CollectLikelihoodResultsFromFile from:$likelihood_file_path\n";
	my $likelihood_all;
	my $likelihood_seqs_num;
	my $likelihood_average;
	my $positive_likelihood_all;
	my $positive_likelihood_seqs_num;
	my $positive_likelihood_average;
	
	if (open(INLIKELIHOODFILE, $likelihood_file_path))
	{
		print "CollectLikelihoodResultsFromFile (DEBUG): opened the file";
	}
	else
	{
		print "CollectLikelihoodResultsFromFile (DEBUG): can't open the file";
		sleep 5; 
		open(INLIKELIHOODFILE, $likelihood_file_path) or die "CollectLikelihoodResultsFromFile could not open out file: $likelihood_file_path\n";
	}
	my $line = <INLIKELIHOODFILE>;
	#print "line:$line\n";
	chomp($line);
	#print "line:$line\n";
	my $line_start;
	my $line_end;
	($line_start, $line_end) = split(/:/, $line,2);
	#print "line_start:$line_start\n";
	#print "line_end:$line_end\n";
	($likelihood_all,$likelihood_seqs_num,$likelihood_average) = split(/\|/, $line_end,3);
	#print "likelihood_all:$likelihood_all\n";
	#print "likelihood_seqs_num:$likelihood_seqs_num\n";
	#print "likelihood_average:$likelihood_average\n";
	$line = <INLIKELIHOODFILE>;
	chomp($line);
	my $line_start;
	my $line_end;
	($line_start, $line_end) = split(/:/, $line,2);
	#print "line_start:$line_start\n";
	#print "line_end:$line_end\n";
	($positive_likelihood_all,$positive_likelihood_seqs_num,$positive_likelihood_average) = split(/\|/, $line_end,3);
	#print "positive_likelihood_all:$positive_likelihood_all\n";
	#print "positive_likelihood_seqs_num:$positive_likelihood_seqs_num\n";
	#print "positive_likelihood_average:$positive_likelihood_average\n";
	close(INLIKELIHOODFILE);
	print "DEBUG: CollectLikelihoodResultsFromFile return:$likelihood_all,$likelihood_seqs_num,$likelihood_average,$positive_likelihood_all,$positive_likelihood_seqs_num,$positive_likelihood_average\n";
	return ($likelihood_all,$likelihood_seqs_num,$likelihood_average,$positive_likelihood_all,$positive_likelihood_seqs_num,$positive_likelihood_average);
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub CollectKLDistanceResultsFromFile
{
	my ($KL_distance_file_path) = @_;
	
	print "DEBUG: CollectKLDistanceResultsFromFile from:$KL_distance_file_path\n";

	open(INKLFILE, $KL_distance_file_path) or die "CollectKLDistanceResultsFromFile could not open out file: $KL_distance_file_path\n";
	my $line = <INKLFILE>;
	chomp($line);
	my $line_start;
	my $KL_distance;
	($line_start, $KL_distance) = split(/:/, $line,2);
	close(INKLFILE);
	print "DEBUG: CollectKLDistanceResultsFromFile return:$KL_distance\n";
	return $KL_distance;
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub WriteTabularFileOfColumnArrays
{
	my $TAB = "\t";
	
	my ($array_of_col_arrays_ptrs_ptr, $array_of_col_headers_ptr, $write_tabular_output_file_path) = @_;
	
	
	my @array_of_col_arrays_ptrs = @$array_of_col_arrays_ptrs_ptr;
	my @array_of_col_headers = @$array_of_col_headers_ptr;
	
	if (scalar(@array_of_col_arrays_ptrs) !=  scalar(@array_of_col_headers))
	{
		print STDERR "length of array_of_col_arrays_ptrs and array_of_col_headers not equal!\n";
	}
	
	my $cols_num = scalar(@array_of_col_arrays_ptrs);
	if ($cols_num > scalar(@array_of_col_headers))
	{
		$cols_num = scalar(@array_of_col_headers);
	}
	
	open(WRITE_TABULAR_OUT_FILE, ">$write_tabular_output_file_path") or die "WriteTabularFileOfColumnArrays could not open out file: $write_tabular_output_file_path\n";
	
	my @cur_col_array;
	my $cur_col_header;
	my $cur_element;
	
	for (my $i = 0; $i < $cols_num; ++$i)
	{
		$cur_col_header = $array_of_col_headers[$i];
		
		print WRITE_TABULAR_OUT_FILE  "$cur_col_header"; 
		if ($i < $cols_num-1)
		{
			print WRITE_TABULAR_OUT_FILE  "$TAB"; 
		}
	}
	print WRITE_TABULAR_OUT_FILE "\n";
	
	my $TMP_cur_col_array_ptr = $array_of_col_arrays_ptrs[0];
	@cur_col_array = @$TMP_cur_col_array_ptr ;
	my $rows_num = scalar(@cur_col_array);
	
	for (my $r = 0; $r < $rows_num; ++$r)
	{
		for (my $c = 0; $c < $cols_num; ++$c)
		{
			my $TMP_cur_col_array_ptr = $array_of_col_arrays_ptrs[$c];
			@cur_col_array = @$TMP_cur_col_array_ptr;
			$cur_element = $cur_col_array[$r];
			
			print WRITE_TABULAR_OUT_FILE "$cur_element"; 
			if ($c < $cols_num-1)
		{
			print WRITE_TABULAR_OUT_FILE  "$TAB"; 
		}
		}
		print WRITE_TABULAR_OUT_FILE "\n";
	}
	close(WRITE_TABULAR_OUT_FILE);
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub WriteExecStrs
{
	my ($array_of_arrays_ptrs_ptr, $array_of_headers_ptr, $write_exec_strs_output_file_path) = @_;
	
	
	my @array_of_arrays_ptrs = @$array_of_arrays_ptrs_ptr;
	my @array_of_headers = @$array_of_headers_ptr;
	
	if (scalar(@array_of_arrays_ptrs) !=  scalar(@array_of_headers))
	{
		print STDERR "length of array_of_arrays_ptrs and array_of_headers not equal!\n";
	}
	
	my $arrays_len = scalar(@array_of_arrays_ptrs);
	if ($arrays_len > scalar(@array_of_headers))
	{
		$arrays_len = scalar(@array_of_headers);
	}
	
	open(WRITE_EXEC_STRS_OUT_FILE, ">$write_exec_strs_output_file_path") or die "WriteExecStrs could not open out file: $write_exec_strs_output_file_path\n";
	
	my @cur_array;
	my $cur_header;
	
	for (my $i = 0; $i < $arrays_len; ++$i)
	{
		my $TMP_cur_array_ptr = $array_of_arrays_ptrs[$i];
		@cur_array = @$TMP_cur_array_ptr;
		$cur_header = $array_of_headers[$i];
		
		print WRITE_EXEC_STRS_OUT_FILE "$cur_header\n";
		
		foreach my $cur_exec_line (@cur_array)
		{
			print WRITE_EXEC_STRS_OUT_FILE "$cur_exec_line \n\n";
		}
		print WRITE_EXEC_STRS_OUT_FILE "\n\n";
	}
	close(WRITE_EXEC_STRS_OUT_FILE);

}
