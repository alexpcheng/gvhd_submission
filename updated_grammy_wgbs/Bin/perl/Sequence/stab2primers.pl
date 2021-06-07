#!/usr/bin/perl
#changes that I added +1 to exclude length, chnaged PRIMER_SELF_END from 5 to 9999
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";

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

my $search_ends = get_arg("search_ends", -1, \%args);
my $min_gc_clamp = get_arg("min_gc_clamp", 0, \%args);
my $optimum_size = get_arg("opt_size", 20, \%args);
my $minimum_size = get_arg("min_size", 20, \%args);
my $maximum_size = get_arg("max_size", 30, \%args);
my $optimum_tm = get_arg("opt_tm", 60, \%args);
my $minimum_tm = get_arg("min_tm", 50, \%args);
my $maximum_tm = get_arg("max_tm", 90, \%args);
my $max_tm_difference = get_arg("max_tm_diff", 100, \%args);
my $force_left_end = get_arg("force_left_end", 0, \%args);
my $force_right_end = get_arg("force_right_end", 0, \%args);
my $self_end_limit = get_arg("self_end_limit", 5, \%args); ##The regular primer3 default is 3
my $self_any = get_arg("self_any", 8, \%args); ##The regular primer3 default is 8
my $poly_x_limit = get_arg("poly_x_limit", 8, \%args); ##The regular primer3 default is 5
my $pcr_product_size = get_arg("pcr_product_size", -1, \%args);

my $r = int(rand(10000000));
#print("r=$r\n");
while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  open(OUTFILE, ">tmp.$r");

  print OUTFILE "PRIMER_SEQUENCE_ID=$row[0]\n";
  print OUTFILE "SEQUENCE=$row[1]\n";
  print OUTFILE "PRIMER_PICK_ANYWAY=1\n";

  if ($search_ends != -1)
  {
    my @line = split(",", $search_ends);
	#print ("line0 = $line[0] \n");
	#print ("line1 = $line[1] \n");
    my $sequence_length = length($row[1]);
	#print ("length = $sequence_length \n");
    my $exclude_start = $line[0];
	#print ("exclude_start = $exclude_start \n");
    my $exclude_length = $sequence_length - ($line[0] + $line[1])+2;
	#print ("exclude_length = $exclude_length \n");
    print OUTFILE "PRIMER_PRODUCT_SIZE_RANGE=$exclude_length-$sequence_length\n";
	#print ("primer_product_SizeRange = $exclude_length-$sequence_length\n");
    print OUTFILE "EXCLUDED_REGION=$exclude_start,$exclude_length\n";
	#print ("excludedRegion = $exclude_start,$exclude_length\n");
  } elsif ($pcr_product_size != -1)
  {
  	print OUTFILE "PRIMER_PRODUCT_SIZE_RANGE=$pcr_product_size\n";
  }

  
  print OUTFILE "PRIMER_GC_CLAMP=$min_gc_clamp\n";

  print OUTFILE "PRIMER_OPT_SIZE=$optimum_size\n";
  print OUTFILE "PRIMER_MIN_SIZE=$minimum_size\n";
  #print ("min_size = $minimum_size\n");
  print OUTFILE "PRIMER_MAX_SIZE=$maximum_size\n";
  #print ("max_size = $maximum_size\n");

  print OUTFILE "PRIMER_OPT_TM=$optimum_tm\n";
  print OUTFILE "PRIMER_MIN_TM=$minimum_tm\n";
  print OUTFILE "PRIMER_MAX_TM=$maximum_tm\n";

  print OUTFILE "PRIMER_MIN_GC=0\n";
  print OUTFILE "PRIMER_MAX_GC=100\n";
  
  print OUTFILE "PRIMER_SELF_END=$self_end_limit\n";
  print OUTFILE "PRIMER_SELF_ANY=$self_any\n";
  print OUTFILE "PRIMER_MAX_POLY_X=$poly_x_limit\n";
  #print OUTFILE "PRIMER_FILE_FLAG=1\n"; 
  print OUTFILE "PRIMER_FIRST_BASE_INDEX=1\n";
  print OUTFILE "PRIMER_SALT_CORRECTIONS=1\n";
  print OUTFILE "PRIMER_TM_SANTALUCIA=1\n";
  print OUTFILE "PRIMER_NUM_RETURN=1\n";
  print OUTFILE "PRIMER_MAX_DIFF_TM=$max_tm_difference\n";

  if ($force_right_end == 1 and $force_left_end == 1)
  {
    for (my $i = $minimum_size; $i <= $maximum_size; $i++)
    {
      for (my $j = $minimum_size; $j <= $maximum_size; $j++)
      {
	&ForceEnd("PRIMER_RIGHT_INPUT=" . &ReverseComplement(substr($row[1], length($row[1]) - $i)), "PRIMER_LEFT_INPUT=" . substr($row[1], 0, $j));
      }
    }
  }
  elsif ($force_right_end == 1)
  {
    for (my $i = $minimum_size; $i <= $maximum_size; $i++)
    {
      &ForceEnd("PRIMER_RIGHT_INPUT=" . &ReverseComplement(substr($row[1], length($row[1]) - $i)));
    }
  }
  elsif ($force_left_end == 1)
  {
    for (my $i = $minimum_size; $i <= $maximum_size; $i++)
    {
      &ForceEnd("PRIMER_LEFT_INPUT=" . substr($row[1], 0, $i));
    }
  }
  else
  {
    print OUTFILE "=\n";

    system("$ENV{BIN_HOME}/Primer3/primer3-1.1.1/src/primer3_core < tmp.$r | parse_primer3.pl");
  }

  close(OUTFILE);
}

system("rm tmp.$r");

sub ForceEnd
{
  my ($force1, $force2) = @_;
  print "input = @_ \n";

  system("cp tmp.$r tmp2.$r");
  open(OUTFILE2, ">>tmp2.$r");

  if (length($force1) > 0)
  {
    print OUTFILE2 "$force1\n";
  }

  if (length($force2) > 0)
  {
    print OUTFILE2 "$force2\n";
  }

  print OUTFILE2 "=\n";

  system("$ENV{BIN_HOME}/Primer3/primer3-1.1.1/src/primer3_core < tmp2.$r | parse_primer3.pl");

  system("rm tmp2.$r");
}

__DATA__

stab2primers.pl <file>

   Outputs primers for each sequence

   -search_ends <num1,num2>: Search for left primer only in first <num1> bp and right primer only in last <num2> bp
   -min_gc_clamp <num>:      Minimum number of consecutive Gs and Cs at the 3' end of both the left and right primer (default: 0)

   -opt_size <num>:          Optimum size to aim for (default: 20)
   -min_size <num>:          Minimum size to use (default: 20)
   -max_size <num>:          Maximum size to use (default: 30) (Note that if your primer size is >36 the reported Tm by Primer3 will be erroneous. It may be less than actual.)

   -opt_tm <num>:            Optimum TM to aim for (default: 60)
   -min_tm <num>:            Minimum TM to use (default: 50)
   -max_tm <num>:            Maximum TM to use (default: 90)
   -max_tm_diff <num>:       Max TM difference between primers (default: 100)

   -force_left_end:          The first left bp must be included in the left primer
   -force_right_end:         The first right bp must be included in the right primer
   -self_end_limit:          The maximum allowable 3'-anchored global alignment score when testing a single primer for self-complementarity, and the maximum allowable 3'-anchored global alignment score when testing for complementarity between left and right primers (default: 3, limit:327)
   -self_any:                The maximum allowable local complementarity of each primer to itself and of both primers to each other (default: 8, limit: 327)
   -poly_x_limit              The maximum allowable length of a mononucleotide repeat,
for example AAAAAA (default: 8, limit:unlimited)

	-pcr_product_size <num>-<num>		The acceptable range for the PCR product length. Ex: 100-150. Primer3 will give preference to the lower end of the range. Note that unless you specify this parameter, Primer3 defaults at a minimum PCR product length of 100bp.
