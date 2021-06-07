#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $EXEC_DIR = "$ENV{GENIE_HOME}/Bin/EMBOSS/EMBOSS-5.0.0/emboss/";

# =============================================================================
# Main part
# =============================================================================

# reading arguments
if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA>;
   exit;
}

my $file_ref;
my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, $file_name) or die("Could not open file '$file_name'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $first = get_arg("first", 1, \%args);
my $pairwise = get_arg("pairwise", 0, \%args);
my $file_name_to = get_arg("alignto", 0, \%args);
my $gopen = get_arg("gopen", 10, \%args);
my $gext = get_arg("gext", 5, \%args);
my $output_file = get_arg("alignment", 0, \%args);
my $actual_seq_file = get_arg("actual_seq", 0, \%args);
my $actual_seq_vs_ref_align_file = get_arg("actual_vs_ref", 0, \%args);

my $summary_output = get_arg("summary_output", 0, \%args);
my $dbg = get_arg("dbg", 0, \%args);

if ($summary_output and $pairwise)
{
   print STDERR "Error: summary output works only when aligning to a single sequence (first / alignment).\n";
   exit 1;
}

# PAIRWISE
if ($pairwise) {
  my @sequences;
  my @ids;
  while (<$file_ref>) {
    chomp $_;
    my ($id, $seq) = split("\t", $_);
    push(@ids, $id);
    push(@sequences, $seq);
  }

  for (my $i = 0; $i < scalar(@ids)-1; $i++) {
    open(SEQ, ">tmpseqfile_$$.tab") or die "cannot create tmpseqfile_$$.tab\n";
    print SEQ ">$ids[$i]\n$sequences[$i]\n";
    close(SEQ);

    open(TO, ">tmpseqto_$$.tab") or die "cannot create tmpseqto_$$.tab\n";
    for (my $j = $i+1; $j < scalar(@ids); $j++) {
      print TO ">$ids[$j]\n$sequences[$j]\n";
    }
    close(TO);

    system("$EXEC_DIR/needle tmpseqfile_$$.tab tmpseqto_$$.tab -gapopen $gopen -gapextend $gext -outfile out_$$.needle  2> /dev/null; touch alignments_$$.data; cat out_$$.needle >> alignments_$$.data; /bin/rm out_$$.needle");
  }
}

# ALIGN TO FILE
elsif ($file_name_to) {
  open(SEQ, ">tmpseqfile_$$.tab") or die "cannot create tmpseqfile_$$.tab\n";
  while (<$file_ref>) {
    chomp $_;
    my ($id, $seq) = split("\t", $_);
    print SEQ ">$id\n$seq\n";
  }
  close(SEQ);

  open(TO, ">tmpseqto_$$.tab") or die "cannot create tmpseqto_$$.tab\n";
  open(DATAF, "$file_name_to") or die "cannot read $file_name_to\n";
  while (<DATAF>) {
    chomp $_;
    my ($id, $seq) = split("\t", $_);
    print TO ">$id\n$seq\n";
  }
  close(DATAF);
  close(TO);

  system("$EXEC_DIR/needle tmpseqto_$$.tab tmpseqfile_$$.tab -gapopen $gopen -gapextend $gext -outfile alignments_$$.data 2> /dev/null");
}

# FIRST (Default)
else {
  my $line = <$file_ref>;
  my ($id, $seq) = split("\t", $line);
  open(SEQ, ">tmpseqfile_$$.tab") or die "cannot create tmpseqfile_$$.tab\n";
  print SEQ ">$id\n$seq\n";
  close(SEQ);

  open(TO, ">tmpseqto_$$.tab") or die "cannot create tmpseqto_$$.tab\n";
  while (<$file_ref>) {
    chomp $_;
    my ($id, $seq) = split("\t", $_);
    print TO ">$id\n$seq\n";
  }
  close(TO);

#  print STDERR "$EXEC_DIR/needle tmpseqfile_$$.tab tmpseqto_$$.tab -gapopen $gopen -gapextend $gext -outfile alignments_$$.data\n";
  system("$EXEC_DIR/needle tmpseqfile_$$.tab tmpseqto_$$.tab -gapopen $gopen -gapextend $gext -outfile alignments_$$.data  2> /dev/null;");
}

if (not $dbg)
{
   system ("/bin/rm tmpseqfile_$$.tab tmpseqto_$$.tab");
}


# reading output
open(RESULT, "alignments_$$.data") or die "cannot read alignments_$$.data\n";
if ($output_file) 
{
   open(OUTPUT_ALIGN, ">$output_file") or die "Cannot open $output_file\n";
}

my $id_a;
my $id_b;
my $identity;
my $similarity;
my $score;
my @res;
my @temp_res;
my @ins;
my @ref;
my $last_gap_start = 0;
my $n_seqs = 0;
my $i;
my $j;
my $seq_a;
my $seq_b;
my $seq_a_len = 0;
my $seq_a_temp_len = 0;
my $spec_align_res_str;
my $c;

while (<RESULT>) {
  my $line = $_;

  if ($line =~ m/#=======================================/g) 
  {
     $line = <RESULT>;
     if (not $line =~ m/#/g) # alignment starts
     { 
	if ($summary_output)
	{
	   $spec_align_res_str .= "# $id_a\t$id_b\t$identity\t$similarity\t$score\n";
	}
	else
	{
	   print "$id_a\t$id_b\t$identity\t$similarity\t$score\n";
	}


	if ($output_file)
	{
	   print OUTPUT_ALIGN " ==================== $id_a,$id_b: Score= $score ====================== \n";
	}
	elsif (not $summary_output)
	{
	   print " ==================== $id_a,$id_b: Score= $score ====================== \n";
	}

	if ($summary_output and $seq_a and $seq_b)
	{
	   $n_seqs++;
	   if (length($seq_a) > scalar @res)
	   {
	      my $prev_len = $#res + 1;
	      for (my $i = 0; $i < length($seq_a) - $prev_len; $i++)
	      {
		 push (@res, []);
		 push (@ins, []);
	      }
	   }
	   
	   $seq_a_temp_len = 0;
#	   print STDERR "Length A:".(length($seq_a))."\tLength B:".(length($seq_b))."\n";
	   for ($i = 0, $j = 0; $i < length($seq_a); $i++)
	   {
	      @temp_res = @{$ins[$j]};

	      if (substr($seq_a, $i, 1) ne "-")
	      {
		 if ($seq_a_temp_len > $#ref)
		 {
		    push (@ref, substr($seq_a, $i, 1));
		 }

		 if ($#temp_res + 1 < $n_seqs and substr($seq_b, $i, 1) ne "-")
		 {
		    push (@temp_res, []);
		    $ins[$j] = [ @temp_res ];
		 }
		 push (@{$res[$j++]}, substr($seq_b, $i, 1));
		 $seq_a_temp_len++;

	      }
	      else
	      {
		 if ($#temp_res + 1 < $n_seqs)
		 {
		    push (@temp_res, []);
		 }

		 push (@{$temp_res[$#temp_res]}, substr($seq_b, $i, 1));
		 $ins[$j] = [ @temp_res ];
	      }

	   }
	   $seq_a_len = $seq_a_temp_len > $seq_a_len ? $seq_a_temp_len : $seq_a_len;
	}
	$c = 0;
	$seq_a = "";
	$seq_b = "";
	while (($line = <RESULT>) and (not ($line =~ m/#=======================================/g))) 
	{
	   if ($summary_output)
	   {
	      if ($c == 0 and $line =~ m/^\S+\s+\d+\s+(\S+)\s+\d+/g)
	      {
		 $seq_a .= $1;
	      }
	      if ($c == 2 and $line =~ m/^\S+\s+\d+\s+(\S+)\s+\d+/g)
	      {
		 $seq_b .= $1;
	      }
	      $c = ($c + 1) % 4;

	      if ($output_file)
	      {
		 print OUTPUT_ALIGN $line;
	      }

	   }
	   elsif ($output_file)
	   {
	      print OUTPUT_ALIGN $line;
	   }
	   else
	   {
	      print $line;
	   }
	}
     }
  }
  if ($line =~ m/^# 1: (.+)/g) 
  {
     $id_a = $1;
 }
  if ($line =~ m/^# 2: (.+)/g) 
  {
     $id_b = $1;
 }
  if ($line =~ m/^# Identity: +(\d+)\/(\d+) \(.+\)/g) 
  {
     $identity = "$1/$2";
 }
  if ($line =~ m/^# Similarity: +(\d+)\/(\d+) \(.+\)/g) 
  {
     $similarity = "$1/$2";
 }
  if ($line =~ m/^# Score: +(.+)/g) 
  {
     $score = $1;
 }
}

if ($summary_output and $seq_a and $seq_b)
{
   $n_seqs++;
   if (length($seq_a) > scalar @res)
   {
      my $prev_len = $#res + 1;
      for (my $i = 0; $i < length($seq_a) - $prev_len; $i++)
      {
	 push (@res, []);
	 push (@ins, []);
      }
   }
   
   $seq_a_temp_len = 0;

#   print STDERR "Length A:".(length($seq_a))."\tLength B:".(length($seq_b))."\n";
   $last_gap_start = 0;
   for ($i = 0, $j = 0; $i < length($seq_a); $i++)
   {
      @temp_res = @{$ins[$j]};
      
      if (substr($seq_a, $i, 1) ne "-")
      {
	 if ($seq_a_temp_len > $#ref)
	 {
	    push (@ref, substr($seq_a, $i, 1));
	 }
	 
	 if ($#temp_res + 1 < $n_seqs and substr($seq_b, $i, 1) ne "-")
	 {
	    push (@temp_res, []);
	    $ins[$j] = [ @temp_res ];
	 }
	 push (@{$res[$j++]}, substr($seq_b, $i, 1));
	 $seq_a_temp_len++;
	 
      }
      else
      {
	 if ($#temp_res + 1 < $n_seqs)
	 {
	    push (@temp_res, []);
	 }
	 
	 push (@{$temp_res[$#temp_res]}, substr($seq_b, $i, 1));
	 $ins[$j] = [ @temp_res ];
      }
   }
   
   $seq_a_len = $seq_a_temp_len > $seq_a_len ? $seq_a_temp_len : $seq_a_len;

   my $n_errors = 0;
   my $n_ins = 0;
   my @errors;
   my @temp_ins;
   my $cons_ins_len;
   my $actual_seq;
   my $errors_str;
   my $insertion_str;
   my $match = 0;
   my $prev;
   my $same_error;
   my $min_ins;
   my $cons_mis;

   if ($actual_seq_file)
   {
      open (ACTUAL_SEQ, ">$actual_seq_file") or die "Failed to open file: $actual_seq_file";
      print ACTUAL_SEQ "${id_a}_actual_seq\t";
   }

   for ($i = 0; $i < $seq_a_len; $i++)
   {
      @temp_res = @{$res[$i]};
      $match = 0;
      $same_error = 1;
      $prev = "";

#     print STDERR "$i\t$ref[$i]\t@temp_res\t";
      for ($j = 0; $j <= $#temp_res; $j++)
      {
	 if ($temp_res[$j] eq $ref[$i])
	 {
	    $match = 1;
	    next;
	 }
	 else
	 {
	    if ($prev and $prev ne $temp_res[$j])
	    {
	       $same_error = 0;
	    }
	    $prev = $temp_res[$j];
	 }
      }
      
      if ($match)
      {
	 push (@errors, 0);
      }
      else
      {
	 $n_errors++;
	 if ($same_error)
	 {
	    if ($temp_res[0] eq "-")
	    {
	       push (@errors, "D");
	    }
	    else
	    {
	       push (@errors, "M");
	       $cons_mis = $temp_res[0];
	    }
	 }
	 else
	 {
	    push (@errors, "N");
	 }
      }

      $min_ins = -1;
      @temp_res = @{$ins[$i]};

#      print STDERR "$errors[$#errors]\t";
      my @cons_ins;
      $cons_ins_len = 0;
      for ($j = 0; $j <= $#temp_res; $j++)
      {
	 @temp_ins = @{$temp_res[$j]};

	 for (my $k = 0; $k <= $#temp_ins and $cons_ins_len >= $k; $k++)
	 {
	    if ($#cons_ins < $k)
	    {
	       push (@cons_ins, $temp_ins[$k]);
	       $cons_ins_len++;
	    }
	    elsif ($cons_ins[$k] ne $temp_ins[$k])
	    {
	       $cons_ins_len = $k;
	    }
	    elsif ($k == $cons_ins_len)
	    {
	       $cons_ins_len++;
	    }
	 }
#	 print STDERR "@temp_ins\t";
	 if ($#temp_ins < $min_ins or $min_ins < 0)
	 {
	    $min_ins = $#temp_ins + 1;
	 }
      }

#      print STDERR "$min_ins\t@cons_ins\t$cons_ins_len\n";

      if ($min_ins > 0 and $i > 0 and $#temp_res >= 0)
      {
	 $n_ins += $min_ins;
	 $insertion_str .= "$id_b\t$id_a\t$i\t".($i+$min_ins-1)."\t";
	 
	 for (my $k = 0; $k < $min_ins; $k++)
	 {
	    $insertion_str .= ($k < $cons_ins_len) ? $cons_ins[$k] : "N";
	 }
	 $insertion_str .= "\n";

	 if ($actual_seq_file)
	 {
	    for (my $k = 0; $k < $min_ins; $k++)
	    {
		  print ACTUAL_SEQ ($k < $cons_ins_len) ? $cons_ins[$k] : "N";
	    }
	 }
      }

      if ($actual_seq_file)
      {
	 if ($errors[$#errors] eq 0)
	 {
	    print ACTUAL_SEQ $ref[$i];
	 }
	 elsif ($errors[$#errors] ne "D")
	 {
	    print ACTUAL_SEQ $errors[$#errors] eq "M" ? $cons_mis : "N";
	 }
      }
      
   }

   my $output_str = "# $id_b\tTotal Mismatches/Deletions\t$n_errors/$seq_a_len\t\tTotal insertions\t$n_ins/$seq_a_len\n#\n$spec_align_res_str";

   if ($actual_seq_file)
   {
      print ACTUAL_SEQ "\n";
      close ACTUAL_SEQ;

      if (length($actual_seq_vs_ref_align_file) > 0)
      {
	 open (SEQ_VS_REF, ">$actual_seq_vs_ref_align_file");
	 print SEQ_VS_REF "$output_str\n";
	 close SEQ_VS_REF;
	 system ("needle.pl $actual_seq_file -alignto $file_name_to >> $actual_seq_vs_ref_align_file");
      }
   }



   if ($summary_output and $summary_output ne "1")
   {
      open (SUMMARY_FILE, ">$summary_output") or die "Failed to open: $summary_output";
      print SUMMARY_FILE $output_str;
   }
   else
   {
      print $output_str;
   }

   if ($n_errors > 0)
   {
      $output_str = "#\n# bps with mismatch/deletion:\n# Read\tRef\tRef Start\tRef End\tError type\n";
      if ($summary_output and $summary_output ne "1")
      {
	 print SUMMARY_FILE $output_str;
      }
      else
      {
	 print $output_str;
      }

      PrintErrors (@errors);
   }

   if ($n_ins > 0)
   {
      $output_str = "#\n# Insertions:\n# Read\tRef\tIns Start\tIns End\tInsertion\n$insertion_str\n";

      if ($summary_output and $summary_output ne "1")
      {
	 print SUMMARY_FILE $output_str;
      }
      else
      {
	 print $output_str;
      }
   }
   
}

if ($output_file)
{
   close OUTPUT_ALIGN;
}
if ($summary_output and $summary_output ne "1")
{
   close SUMMARY_FILE;
}

close RESULT;

if (not $dbg) 
{
  system("/bin/rm alignments_$$.data");
}

# =============================================================================
# Subroutines
# =============================================================================
sub PrintErrors
{
   my @arr = @_;
   my $error_start = -1;
   my $str;

   for ($i = 0; $i < $seq_a_len; $i++)
   {
      if ($error_start >= 0)
      {
	 if ($arr[$i] ne $arr[$error_start])
	 {
	    $str = "$id_b\t$id_a\t".($error_start + 1)."\t$i\t";

	    if ( $arr[$error_start] eq "M" ) { $str .= "Mismatch"; }
	    elsif ( $arr[$error_start] eq "D" ) { $str .= "Deletion"; }
	    elsif ( $arr[$error_start] eq "N" ) { $str .= "Ambigious"; }
	    else { $str .= "Unknown"; }

	    $str .= "\n";

	    if ($summary_output and $summary_output ne "1")
	    {
	       print SUMMARY_FILE $str;
	    }
	    else
	    {
	       print $str;
	    }

	    $error_start = -1;
	 }
      }
      elsif ($arr[$i] ne 0)
      {
#	 print STDERR "arr[$i] == 0\n";
	 $error_start = $i;
      }
   }
   if ($error_start >= 0)
   {
      $str = "$id_b\t$id_a\t".($error_start + 1)."\t$i\t";

      if ( $arr[$error_start] eq "M" ) { $str .= "Mismatch"; }
      elsif ( $arr[$error_start] eq "D" ) { $str .= "Deletion"; }
      elsif ( $arr[$error_start] eq "N" ) { $str .= "Ambigious"; }
      else { $str .= "Unknown"; }

      $str .= "\n";

      if ($summary_output and $summary_output ne "1")
      {
	 print SUMMARY_FILE $str;
      }
      else
      {
	 print $str;
      }
   }

}

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

needle.pl <file name> [OPTIONS]

   Perform global sequence alignment.

   Output format:
   [id1] [id2] [identity] [similarity] [score]

OPTIONS:
  -first                            Align the first input sequence to all other sequences (Default).
  -pairwise                         Align between each pair of input sequences.
  -alignto <file name>              Align input sequences to the sequences in the given file.
  -gopen <num>                      Gap open panelty (Default = 10).
  -gext <num>                       Gap extend panelty (Default = 5).
  -alignment <file name>            Print alignment itself to file <file name>. (Default = do not print).
  -summary_output [ <file name> ]   Print a mismatch report (relevant when -first or -alignto is specified)
  -actual_seq <file name>           Print the actual aligned sequence to <file name> (relevant when -summary_report is specified)
  -actual_vs_ref <file_name>        Print alignment of the actual aligned sequence to the reference sequence (relevant when -summary_report and -actual_seq are specified)
  -dbg                              Debug mode
