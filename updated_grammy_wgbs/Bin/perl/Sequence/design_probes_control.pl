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
# Sequences (stab) file    #
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

my @sequences = <$file_ref>;

#--------------------------#
# Locations (chr) file     #
#--------------------------#
my $location_file = get_arg("chr", "", \%args);
my $location_file_ref;
if (length($location_file) == 0)
{
  die "Probes location file not given\n";
}
open(LOCATION_FILE, $location_file) or die("Could not open probes location file '$location_file'.\n");
$location_file_ref = \*LOCATION_FILE;

my @locations = <$location_file_ref>;

#--------------------------#
# Length prefferences      #
#--------------------------#
my $name_of_lengths = get_arg("l_name", "L", \%args);
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
# Other arguments          #
#--------------------------#
my $oligo_concentration = get_arg("o", 0.25, \%args);
my $salt_concentration = get_arg("s", 200, \%args);
$oligo_concentration *= 1e-6;
$salt_concentration *= 1e-3;

my $num_of_replicates = get_arg("rep_num", "5", \%args);
my $name_of_replicates = get_arg("rep_name", "REP", \%args);
my $num_of_reverse_complements = get_arg("rev_num", "5", \%args);
my $name_of_reverse_complements = get_arg("rev_name", "REV", \%args);
my $prefix_probe_name = get_arg("n", "P", \%args);

#my $strand_sign = ($strand eq "forward") ? "\+" : "\-"; 

#---------------------------#
# Major loop over locations #
#---------------------------#
for (my $i = 0; $i < @locations; $i++)
{
  my $row = $locations[$i];
  chomp($row);
  my @probe = split(/\t/,$row);
  my $sequence_id = $probe[0];
  my $probe_start = ($probe[2] < $probe[3]) ? $probe[2] : $probe[3];
  my $probe_end = ($probe[2] < $probe[3]) ? $probe[3] : $probe[2];
  my $probe_length = $probe_end - $probe_start + 1;
  my $probe_id1 = "$prefix_probe_name\_$sequence_id\_$probe_start\_";
  my $probe_id;
  my $tmp_sequence = "";
  my $tmp_sequence_id = "";

  for (my $j = 0; ($j < @sequences) and ($tmp_sequence_id ne $sequence_id); $j++)
  {
    my $l = $sequences[$j];
    chomp($l);
    my @r = split(/\t/,$l);
    $tmp_sequence_id = $r[0];
    if ($tmp_sequence_id eq $sequence_id)
    {
      $tmp_sequence = $r[1];
    }
  }

  my $probe_sequence = &MySequenceVerifier(substr($tmp_sequence,$probe_start,$probe_length),$probe_length);
  my $tmp_probe_tm = &ComputeMeltingTemperature($probe_sequence, $TM_method, $salt_concentration, $oligo_concentration);
  #---------------------------#
  # Replicates                #
  #---------------------------#
  my $probe_id_rep = $probe_id1 . $probe_length . "+" . $name_of_replicates;
  for (my $j = 1; $j <= $num_of_replicates; $j++)
  {
    my $tmp_probe_id = $probe_id_rep . $j;
    print STDOUT "$sequence_id\t$tmp_probe_id\t$probe_start\t$probe_end\t$tmp_probe_tm\t$probe_sequence\n";  
  }

  #---------------------------#
  # Reverse complements       #
  #---------------------------#
  my $probe_id_rev = $probe_id1 . $probe_length . "-" . $name_of_reverse_complements;
  my $rev_probe_sequence = &MyReverseComplement($probe_sequence);
  for (my $j = 1; $j <= $num_of_reverse_complements; $j++)
  {
    my $tmp_probe_id = $probe_id_rev . $j;
    print STDOUT "$sequence_id\t$tmp_probe_id\t$probe_start\t$probe_end\t$tmp_probe_tm\t$rev_probe_sequence\n";  
  }

  #---------------------------#
  # Lengths                   #
  #---------------------------#
  for (my $j = 0; $j < @length; $j++)
  {
    my $tmp_probe_length = $length[$j];
    my $tmp_probe_end = $probe_start + $tmp_probe_length - 1;
    my $k = $j + 1;
    my $tmp_probe_id = $probe_id1 . $tmp_probe_length . "+" . $name_of_lengths . $k;
    my $tmp_probe_sequence = &MySequenceVerifier(substr($tmp_sequence,$probe_start,$tmp_probe_length),$tmp_probe_length);
    my $tmp_probe_tm = &ComputeMeltingTemperature($tmp_probe_sequence, $TM_method, $salt_concentration, $oligo_concentration);
    $tmp_probe_sequence = ($tmp_probe_length >= $length_lower_bound) ? $tmp_probe_sequence : &ExtendSequence($tmp_probe_sequence, $length_lower_bound, $EXTENDER);

    print STDOUT "$sequence_id\t$tmp_probe_id\t$probe_start\t$tmp_probe_end\t$tmp_probe_tm\t$tmp_probe_sequence\n";  
  }

}

#--------------------------#
# SUBROUTINES              #
#--------------------------#

#--------------------------------------------------------------------------------------------------------
# $DNA_sequence_verified MySequenceVerifier ($sequence,$length)
#--------------------------------------------------------------------------------------------------------
sub MySequenceVerifier
{
  my @sequence = split(//,$_[0]);
  my $sequence_length = $_[1];
  my $ver_sequence = "";
  my $verified = ($sequence_length == @sequence);

  for (my $i = 0; ($i < @sequence) and $verified; $i++)
  {
    if ($sequence[$i] =~ /[AGCTagct]/) 
    { 
      $ver_sequence = $ver_sequence . "\U$sequence[$i]";
    }
    else 
    { 
      $verified = 0;
    }
  }
  return $verified ? $ver_sequence : "";
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

#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         design_probes_control.pl <stab>
 
 Description:    Given a stab file, and a location file of probes output a set of controls relative to each 
                 location. Including replicated, reverse complement copies and probes of different 
                 lengths relative to the start location. 
                 Melting temprature (TM) is computed as in desing_probes.pl.
                 Notice: currently will work unexpectedly for probes shorter than minimal length.

 Output:         <original_sequence_id><\t><probe_id><\t><start><\t><end><\t><probe_TM><\t><probe_sequence> 

 Flags:

  -chr                    The probe location file.

  -o <num>                Oligo concentration in micro-gram (default: 0.25ug).

  -s <num>                Salt concentration in milli-molar (default: 200mM).

  -tmm <str>              Specify the TM Method (default: "Nimblegen"). To see the list
                          of available TM Methods, run design_probes.pl -tmm "LIST".

  -n <str>                The prefix name for all probes (default: "P").        

  -rep_num <int>          Number of replicates (default: 5).
  -rep_name <str>         Suffix name for the replicates (default: "REP").

  -rev_num <int>          Number of reverse complements (default: 5).
  -rev_name <str>         Suffix name for the reverse complements (default: "REV").

  -l <int1>,..,<int_n>    An set of lengthes. E.g., "-l 50,52-55,47-45".
  -ll <int>               A lower bound on length. Below that extend probes with 'T's.
  -l_name <str>           Suffix name for the length control (default: "L").
