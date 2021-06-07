#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $BG_FILE = "$ENV{GENIE_HOME}/Runs/Folding/Rabani06/Model/BG_model/bg.tab";


# =============================================================================
# Main part
# =============================================================================

# reading arguments
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  my $file_ref = \*STDIN;
  open(FILE, ">model_$$.tab") or die("Could not open file model.tab.\n");

  while (<$file_ref>) {
    my $line = $_;
    print FILE "$_";
  }
  close(FILE);
  $file_name = "model_$$.tab";
}
else {
  shift(@ARGV);
  $file_name = "../"."$file_name";
}

my %args = load_args(\@ARGV);
my $sample_size = get_arg("size", 100, \%args);

# generating sample instances from the model
sample($file_name, $sample_size, "sampled_instance");

system("/bin/rm -rf model_$$.tab");


# =============================================================================
# Subroutines
# =============================================================================

sub sample($$$) {
  my ($model_name, $sample_size, $output_file) = @_;
  open (XML, ">xml.map") or die "cannot open file xml.map.\n";

  print XML "<?xml version=\"1.0\"?>";
  print XML "<MAP>\n";
  print XML "  <RunVec>\n";
  print XML "    <Run Name=\"RNAmodel\" Logger=\"logger.log\">\n";
  print XML "      <Step Type=\"LoadRnaModelParams\"\n";
  print XML "            Name=\"LoadRnaModel\"\n";
  print XML "            RnaModelName=\"model\"\n";
  print XML "            File=\"$model_name\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LoadRnaBgParams\"\n";
  print XML "            Name=\"LoadRnaBgParams\"\n";
  print XML "            RnaBgModelName=\"bg_model\"\n";
  print XML "            File=\"$BG_FILE\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"SampleRnaModel\"\n";
  print XML "            Name=\"SampleModel\"\n";
  print XML "	         RnaModelName=\"model\"\n";
  print XML "            RnaBgModelName=\"bg_model\"\n";
  print XML "            RnaSampleSize=\"$sample_size\"\n";
  print XML "            OutputFile=\"$output_file\">\n";
  print XML "      </Step>\n";
  print XML "    </Run>\n";
  print XML "  </RunVec>\n";
  print XML "</MAP>\n";

  system("map_learn xml.map; /bin/rm -rf xml.map logger.log");
}



# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAmodel_sample.pl <model_file> [options]

Sample RNA structures from a given Covariance Model.
The model file should be given in the format of the motif search tool.

Options:
  -size <num>     Sample size [default: 100].
