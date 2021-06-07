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


my %args = load_args(\@ARGV);

#--------------------------#
# TM Method                #
#--------------------------#
my $TM_methods_list = "#"."Nimblegen"."#"."IDTDNA"."#";
my $TM_method = get_arg("tmm", "Nimblegen", \%args);

if ($TM_method eq "LIST")
{
  my $k = 0;
  my $s = 1;
  my $tmp_method = "";
  print STDOUT "\nTM methods:\n";
  while ($k < (length($TM_methods_list) - 1))
  {
    $s = index($TM_methods_list,"#",($k+1));
    $tmp_method = substr($TM_methods_list,($k + 1),(($s - $k) - 1));
    $k = $s;
    print STDOUT "\t$tmp_method\n";
  }
  exit;
}
elsif (index($TM_methods_list,"#".$TM_method."#") < 0)
{
  die("TM method $TM_method not recognized.\n");
}

#--------------------------#
# File and other arguments #
#--------------------------#
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

my $oligo_concentration = get_arg("o", 0.25, \%args);
my $salt_concentration = get_arg("s", 200, \%args);
$oligo_concentration *= 1e-6;
$salt_concentration *= 1e-3;

my $tm = get_arg("tm", 76.0 , \%args); 
my $delta = get_arg("d", 2.0 , \%args);
my $TM_upper_bound = get_arg("tm_max", 78.0, \%args);
my $resolution = get_arg("res", 3 , \%args); 
my $strand = get_arg("r", "forward", \%args);
my $prefix_probe_name = get_arg("n", "P", \%args);
my $strand_sign = ($strand eq "forward") ? "f" : "r"; 
my $probe_synthesis_cycle_limit = get_arg("ncyc", "148", \%args);

#--------------------------#
# Masker                   #
#--------------------------#
my $masker_file = get_arg("maskf", "", \%args);
my $mask_overlap = get_arg("masko", 0, \%args);

if (length($masker_file) > 0)
{
  open(MASKER_DUMMY,$masker_file) or die("Could not open file '$masker_file'.\n");
  close(MASKER_DUMMY);
  ## NOTICE: We don't use the file, just verify it can be opened (otherwise exit with error).
}

#--------------------------#
# Length prefferences      #
#--------------------------#
my $l = get_arg("l", 0 , \%args); 
my @length = &ParseRanges($l);
my $max_length = -1;
my $min_length = 100000000000;

for (my $i=0; $i < @length; $i++)
{
  my $tmp = $length[$i];
  $max_length = $max_length > $tmp ? $max_length : $tmp;
  $min_length = $min_length < $tmp ? $min_length : $tmp;
}

my $length_lower_bound = get_arg("ll", $min_length, \%args);

my $EXTENDER = "T";
### NOTICE: That's the nucleotide we extend with probes that are shorter than $length_lower_bound

#--------------------------#
# Working mode             #
#--------------------------#

my $OPTIMIZATION_MODE = 2;
my $PIVOT_MODE = 1;
my $LENGTH_ORDER_MODE = 0;

my $work_mode = get_arg("mode", $LENGTH_ORDER_MODE , \%args); 

if (($work_mode != $OPTIMIZATION_MODE)
    and 
    ($work_mode != $PIVOT_MODE)
    and 
    ($work_mode != $LENGTH_ORDER_MODE))
{
  die("Working mode $work_mode not recognized.\n");
}

my @error = ();
my $pivot_length;
if ($work_mode == $OPTIMIZATION_MODE)
{
  for (my $i = 0; $i < @length; $i++)
  {
    $error[$i] = 0;
  }
}
elsif ($work_mode == $PIVOT_MODE)
{
  $pivot_length = get_arg("piv", $length[0], \%args);
  if (($pivot_length > $max_length)
      or
      ($pivot_length < $min_length))
  {
    die("Pivot length $pivot_length is out of lengthes range [$min_length,$max_length].\n");
  }
}

my $verbose_mode = get_arg("q", "verbose", \%args);
if ($verbose_mode eq "verbose")
{
  print STDERR "\nStart probe design ($prefix_probe_name)";
  if ($work_mode == $OPTIMIZATION_MODE)
  {
    print STDERR ", Optimization mode"
  }
  elsif ($work_mode == $PIVOT_MODE)
  {
    print STDERR ", Pivot mode"
  }
  elsif ($work_mode == $LENGTH_ORDER_MODE)
  {
    print STDERR ", Length-order mode"
  }
  print STDERR ".\n";
}

my $total_sequence_length = 0;

#---------------------------#
# Major loop over sequences #
#---------------------------#
while(<$file_ref>)
{
  chomp;
  my @row = split(/\t/);
  my $sequence_id = $row[0];
  my $sequence_forward_strand = $row[1];
  my $sequence_length = length($sequence_forward_strand);
  $total_sequence_length += $sequence_length;

  if ($verbose_mode eq "verbose")
  {
    print STDERR "Sequence: $sequence_id,$strand_sign\n";
  }
  my $previous_percentile = 0;

  #---------#
  # MASKER  #
  #---------#
  my @masker = (0);

  if (length($masker_file) == 0)
  {
    push(@masker,$sequence_length);
  }
  else
  {
    my $masker_str = `filter.pl $masker_file -c 0 -estr $sequence_id  | sort.pl -c0 0 -c1 2,3 -op1 min -n1 | chr_merge_consecutive_locations.pl | chr2minusplus.pl | cut.pl -f 3,4`;
    my @masker_rows = split(/\n/,$masker_str);

    for (my $r = 0; $r < @masker_rows; $r++)
    {
      my @masker_current_row = split(/\t/,$masker_rows[$r]);

      if ($masker_current_row[0] == 0)
      {
	@masker = ();
	push(@masker,$masker_current_row[1]+1);
      }
      else
      {
	push(@masker,$masker_current_row[0]);
	push(@masker,$masker_current_row[1]+1);
      }
    }

    if ($masker[@masker - 1] < $sequence_length)
    {
      push(@masker,$sequence_length);
    }
  }

  while (@masker > 0)
  {
    my $contig_start = shift(@masker) - $mask_overlap;
    $contig_start = ($contig_start < 0) ? 0 : $contig_start;
    my $contig_end = shift(@masker) + $mask_overlap;
    $contig_end = ($contig_end > $sequence_length) ? $sequence_length : $contig_end;

    for (my $probe_start = $contig_start; $probe_start <= ($contig_end - $min_length) ; $probe_start += $resolution)
    {
      my ($probe_length,$probe_tm,$probe_sequence) = (-1000,10000000000,""); 
      my ($tmp_probe_length, $tmp_probe_tm, $tmp_probe_sequence) = (-1000,-1000,"");
      my ($good_probe_length, $good_probe_tm, $good_probe_sequence) = (-1000,-1000,"");
      my $probe_end = -1;

      if ($work_mode == $OPTIMIZATION_MODE)
      {
	#-----------------------------------------#
	# OPTIMIZATION MODE                       #
	#-----------------------------------------#
	my @good_tm = ();

	for (my $i = 0; $i < @length; $i++)
	{
	  $tmp_probe_length = $length[$i];

	  if ($probe_start + $tmp_probe_length - 1 <= $contig_end)
	  {
	     $tmp_probe_sequence = &MySequenceVerifier(substr($sequence_forward_strand,$probe_start,$tmp_probe_length),$tmp_probe_length);

	     $tmp_probe_sequence = &ComputeNimblegenCycles($tmp_probe_sequence) > $probe_synthesis_cycle_limit ? "" : $tmp_probe_sequence;
	     $tmp_probe_tm = &ComputeMeltingTemperature($tmp_probe_sequence, $TM_method, $salt_concentration, $oligo_concentration);

	     if ($tmp_probe_tm ne "Too short")
	     {
		if (abs($tmp_probe_tm - $tm) <= $delta)
		{
		   push(@good_tm, $length[$i]);
		}
		if (abs($tmp_probe_tm - $tm) < (abs($probe_tm - $tm)))
		{
		   $probe_length = $tmp_probe_length;
		   $probe_tm = $tmp_probe_tm;
		   $probe_sequence = $tmp_probe_sequence;
		}
	     }
	  }
	}

	for (my $i = 0; $i < @error; $i++)
	{
	  $error[$i] += &Error($length[$i],$probe_length,@good_tm);
	}
      }
      elsif ($work_mode == $PIVOT_MODE)
      {
	#-----------------------------------------#
	# PIVOT MODE                              #
	#-----------------------------------------#

	for (my $i = 0; $i < @length; $i++)
	{
	   $tmp_probe_length = $length[$i];

	   if ($probe_start + $tmp_probe_length - 1 <= $contig_end)
	   {
	      $tmp_probe_sequence = &MySequenceVerifier(substr($sequence_forward_strand,$probe_start,$tmp_probe_length),$tmp_probe_length);
	      $tmp_probe_sequence = &ComputeNimblegenCycles($tmp_probe_sequence) > $probe_synthesis_cycle_limit ? "" : $tmp_probe_sequence;
	      $tmp_probe_tm = &ComputeMeltingTemperature($tmp_probe_sequence, $TM_method, $salt_concentration, $oligo_concentration);

	      if (($tmp_probe_tm ne "Too short") and ($tmp_probe_tm <= $TM_upper_bound))
	      {
		 if ((abs($tmp_probe_tm - $tm) <= $delta)
		     and
		     (abs($tmp_probe_length - $pivot_length) < (abs($good_probe_length - $pivot_length))))
		 {
		    $good_probe_length = $tmp_probe_length;
		    $good_probe_tm = $tmp_probe_tm;
		    $good_probe_sequence = $tmp_probe_sequence;
		 }
		 if (abs($tmp_probe_tm - $tm) < (abs($probe_tm - $tm)))
		 {
		    $probe_length = $tmp_probe_length;
		    $probe_tm = $tmp_probe_tm;
		    $probe_sequence = $tmp_probe_sequence;
		 }
	      }
	   }
	}
	
	if ($good_probe_length > 0)
	{
	   $probe_length = $good_probe_length;
	   $probe_tm = $good_probe_tm;
	   $probe_sequence = $good_probe_sequence;
	}

	$probe_end = $probe_start + $probe_length - 1; 
	$probe_sequence = ($strand eq "forward") ? $probe_sequence : &MyReverseComplement($probe_sequence);
	my $probe_id = "$prefix_probe_name\_$sequence_id\_$probe_start\_$probe_length$strand_sign";

	if (length($probe_sequence) > 0)
	{
	   print STDOUT "$sequence_id\t$probe_id\t$probe_start\t$probe_end\t$probe_tm\t$probe_sequence\n";
	}
      }
      elsif ($work_mode == $LENGTH_ORDER_MODE)
      {
	#-----------------------------------------#
	# LENGTH-ORDER MODE                       #
	#-----------------------------------------#
	my $notDone = 1;

	for (my $i = 0; ($i < @length) and $notDone; $i++)
	{
	  $tmp_probe_length = $length[$i];
	  if ($probe_start + $tmp_probe_length - 1 <= $contig_end)
	  {
	     $tmp_probe_sequence = &MySequenceVerifier(substr($sequence_forward_strand,$probe_start,$tmp_probe_length),$tmp_probe_length);
	     $tmp_probe_sequence = &ComputeNimblegenCycles($tmp_probe_sequence) > $probe_synthesis_cycle_limit ? "" : $tmp_probe_sequence;
	     $tmp_probe_tm = &ComputeMeltingTemperature($tmp_probe_sequence, $TM_method, $salt_concentration, $oligo_concentration);

	     if (($tmp_probe_tm ne "Too short") and ($tmp_probe_tm <= $TM_upper_bound))
	     {
		if ((abs($tmp_probe_tm - $tm) <= $delta)
		    or
		    (abs($tmp_probe_tm - $tm) < (abs($probe_tm - $tm))))
		{
		   $probe_length = $tmp_probe_length;
		   $probe_tm = $tmp_probe_tm;
		   $probe_sequence = $tmp_probe_sequence;
		}
		if (abs($tmp_probe_tm - $tm) <= $delta)
		{
		   $notDone = !$notDone;
		}
	     }
	  }
	}

	$probe_end = $probe_start + $probe_length - 1; 
	$probe_sequence = ($strand eq "forward") ? $probe_sequence : &MyReverseComplement($probe_sequence);
	$probe_sequence = (($probe_length >= $length_lower_bound) or ($probe_length <= 0)) ? $probe_sequence : &ExtendSequence($probe_sequence, $length_lower_bound, $EXTENDER);

	my $probe_id = "$prefix_probe_name\_$sequence_id\_$probe_start\_$probe_length$strand_sign";

	if (length($probe_sequence) > 0)
	{
	  print STDOUT "$sequence_id\t$probe_id\t$probe_start\t$probe_end\t$probe_tm\t$probe_sequence\n";
	}
      }

      if ($verbose_mode eq "verbose")
      {
	my $percentile = $probe_start / ($sequence_length - $min_length - $resolution);
	$previous_percentile = &PrintPercentile($percentile,$previous_percentile);
      }
    } #for
  } #while

  if ($verbose_mode eq "verbose")
  {
    print STDERR "\n";
  }
}

if ($work_mode == $OPTIMIZATION_MODE)
{
  my $norm_factor = (($total_sequence_length - $min_length) / $resolution);
  
  for (my $i = 0; $i < @error; $i++)
  {
    $error[$i] = ($error[$i] / $norm_factor);
  }

  my $best_error = $error[0];
  my $best_error_length = $length[0];
  
  for (my $i = 0; $i < @error; $i++)
  {
    if ($error[$i] < $best_error)
    {
      $best_error = $error[$i];
      $best_error_length = $length[$i];
    }
  }

  if ($verbose_mode eq "verbose")
  {
    print STDERR "Optimal length:\t$best_error_length\nOptimal error:\t$best_error\n";  
  }

  for (my $i = 0; $i < @error; $i++)
  {
    print STDOUT "$length[$i]\t$error[$i]\n";
  }
}

if ($verbose_mode eq "verbose")
{
  print STDERR "Done.\n";
}

#--------------------------#
# SUBROUTINES              #
#--------------------------#

#--------------------------------------------------------------------------------------------------------
# $DNA_sequence_verified MySequenceVerifier ($sequence,$length)
#--------------------------------------------------------------------------------------------------------
sub MySequenceVerifier
{
  my $sequence = $_[0];
  $sequence = "\U$sequence";
  my $sequence_length = $_[1];
  my $tmp_sequence = $sequence;
  $tmp_sequence =~ s/[ACGT]//g;

  return ($sequence_length == length($sequence) && length($tmp_sequence) == 0) ? $sequence : "";
}

#-----------------------------------------------------------------------
# $sequence &ExtendSequence($probe_sequence,$length,$EXTENDER)
#-----------------------------------------------------------------------
sub ExtendSequence
{
  my $sequence = $_[0];
  my $length = $_[1];
  my $nuc = $_[2];

  while (length($sequence) < $length)
  {
    $sequence = $sequence . $nuc; 
  }
  $sequence;
}

#-----------------------------------------------------------------------
# $error Error($length,$best_probe_length,@good_tm)
#-----------------------------------------------------------------------
sub Error
{
  my $error_res = 100000000;
  my $length = shift(@_);
  my $best_probe_length = shift(@_);
  my @good_tm = @_;
  my $tmp_error = -1;
  
  if (@good_tm > 0)
  {
    for (my $i = 0; $i < @good_tm; $i++)
    {
      $tmp_error = abs($length - $good_tm[$i]);
      $error_res = ($tmp_error < $error_res) ? $tmp_error : $error_res;
    }
  }
  else
  {
    $error_res = abs($length - $best_probe_length);
  }
  $error_res;
}

#-------------------------------------------------------------------------
# $DNAsequence MyReverseComplement ($DNAsequence) # E.g. RC("AACG")="CGTT"
#-------------------------------------------------------------------------
sub MyReverseComplement
{
  my @sequence = split(//,$_[0]);
  my $reverse_sequence = "";
  
  for (my $i = (@sequence - 1); $i >= 0; $i--)
  {
    if ($sequence[$i] eq "A") { $reverse_sequence = $reverse_sequence . "T"; }
    elsif ($sequence[$i] eq "C") { $reverse_sequence = $reverse_sequence . "G"; }
    elsif ($sequence[$i] eq "G") { $reverse_sequence = $reverse_sequence . "C"; }
    elsif ($sequence[$i] eq "T") { $reverse_sequence = $reverse_sequence . "A"; }
    else 
    { 
      die("\nReverseSequence() error: sequence must be on {A,C,G,T}, found: $sequence[$i]. Exit process.\n");
    }
  }
  $reverse_sequence;
}

#-----------------------------------------------------------------------
# $percentile PrintPercentile ($percentile, $previous_percentile) 
#-----------------------------------------------------------------------
sub PrintPercentile
{
  my $percent = int($_[0] * 100);
  my $previous_percent = $_[1];

  if ($percent > $previous_percent)
  {
    print STDERR "$percent% ";      
    $percent;
  }
  else
  {
    $previous_percent;
  }
}

#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         design_probes.pl <stab>
 
 Description:    Given a stab file, output a probe design for the sequences 
                 based on preffered melting temprature (TM) and length.

 Output:         <original_sequence_id><\t><probe_id><\t><start><\t><end><\t><probe_TM><\t><probe_sequence> 

 Flags:

 --------------------------------------------- Concentrations ----------------------------------------------

  -o <num>:      Oligo concentration in micro-gram (default: 0.25ug).

  -s <num>:      Salt concentration in milli-molar (default: 200mM).

 ------------------------------------------- Melting Temperature -------------------------------------------

  -tm <num>:     The target melting temprature in Celsious (default: 76cels).

  -tmm <str>:    Specify the TM Method (default: "Nimblegen").
                 To see the list of available TM Methods, run design_probes.pl -tmm "LIST".

  -d <num>:      Define the interval [TM-<num>,TM+<num>] of "good" TM in Celsious (default: 2cels).

  -tm_max <num>: Define an (inclusive) upper bound for a valid TM (default: 78cels).

 ----------------------------------------------- Probe Length ----------------------------------------------

  -l <num1>,...,<num_n>:  
                 An order of lengthes. 
                 E.g., -l 50,49,51,48,52-55,47-45 is the order: 50,49,51,48,52,53,54,55,47,46,45. 
  
  -ll <num>:     A lower bound on length. If the lengthes defined by -l are lower than <num>, 
                 probes are extended by 'T's to length <num>. Used only in Length-order mode (mode 0).

  -piv <num>:    Define a pivot <num>. Used only in the Pivot mode (mode 1), and must be included in 
                 the lengthes defined by the -l flag (default: <num> = the first <num> in the -l flag). 

 ---------------------------------------------- Repeat Masking ---------------------------------------------

  -maskf <chr>:  Mask the sequences with the (repeat) masking file <chr>.

  -masko <num>:  Define the allowed overlap in base-pairs between a probe and a masked area (default: 0bp).

 -------------------------------------------------- Other --------------------------------------------------

  -res <num>:    The probe resolution in Base-pair (default: 3bp).

  -r:            Work as usual on the forward strand, but report (only) the reverse complement sequence.

  -mode <num>:   Define the working mode as follows.

                 <num=0>: Length-order mode. Search a "good" TM in the order defined by the -l flag. 
                                             The first length with a "good" TM is returned, 
                                             and if no "good" TM was found, return the best TM.
                                             Work with the length-lower-bound defined by the -ll flag.
               
                 <num=1>: Pivot mode.        Search the "good" TM that is most close to the pivot length
                                             defined by the -piv flag, within the range defined by the -l flag.
                                             If no "good" TM was found, return the best TM.

                 <num=2>: Optimization mode. Find best "pivot" preffered length within the range of lengthes 
                                             defined by the -l flag. The ouput in this mode is (only) the list
                                             of possible pivot lengthes and their (normalized) total error. 
                                             The error per probe is the distance between its length and the pivot length.

  -n <str>:      Define <str> to be a prefix name for all probes (default: "P").        

  -ncyc <num>:   Maximum number of "cycles" allowed for each probe (NibleGen's order of printing is A,C,G,T
                 and their limit is 148 cycles, which is the default for <num>).

  -q:            Quite mode (default is verbose).
