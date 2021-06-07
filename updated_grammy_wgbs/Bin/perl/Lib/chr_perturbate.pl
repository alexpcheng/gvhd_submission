#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $chr_file = $ARGV[0];

my %args = load_args(\@ARGV);
my $noise_type = get_arg("t", "Gaussian", \%args);
my $param_list = get_arg("p", 5, \%args);
my $matlab_output_file = get_arg("tmp", "tmp_matlab_samples.txt", \%args);


my @params = split(/,/, $param_list);
my $num_params = @params;


die "Input file '$chr_file' not found.\n" unless ( -e $chr_file );
open(CHR, $chr_file) or die "Could not open file '$chr_file'.\n";

my $num_features = 0;
while( <CHR> ) {
  chomp;
  my @line = split(/\t/, $_);
  $num_features = $num_features + $line[5];
}
close CHR;

my $distribution_for_matlab;
my $params_for_matlab;

# will use the matlab script SampleFromDistribution.m for sampling. name of required distribution needs to fit it.
if ( $noise_type eq "Gaussian" ) {
  $distribution_for_matlab = "Normal";
  die "For Gaussian noise, a single param (Std) is expected\n" unless ( $num_params == 1 );
  $params_for_matlab = "[0 $params[0]]";
}

system("matlabrun.pl -po -m SampleFromDistribution -p \"$distribution_for_matlab,$params_for_matlab,$num_features,Round,$matlab_output_file,0\"");

open(CHR, $chr_file) or die "Could not open file '$chr_file' (2).\n";
open(PERTS, $matlab_output_file) or die "Could not open matlab output file '$matlab_output_file'.\n";

while ( <CHR> ) {
  chomp;
  my @line = split(/\t/, $_);
  for ( my $i=0 ; $i < $line[5] ; $i++ ) {
    my $perturbation = <PERTS>;
    chomp $perturbation;
    printf "%s\t%s\t%d\t%d\t%s\t%d\n", $line[0], $line[1], $line[2] + $perturbation, $line[3] + $perturbation, $line[4], 1 ;
  }
}

close CHR;
close PERTS;

system("rm $matlab_output_file");


__DATA__

chr_perturbate.pl <chr file> [options]

  takes a chr file and perturbates each of its locations according to a specified noise model.
  DOES NOT (!!) accept input through STDIN, so will not have to upload all data to memory.
  assumes that the 6th column contains the number of times that the feature appeared.
  if a feature appears n times, a perturbation will be performed independently n times,
  and each time a new output chr line will be outputed.
  note that features may be perturbated "over the edge" (to negative positions or beyond
  last position of respective sequence).
  output is not sorted.

  -t <str>:          noise model type (currently supports only Gaussian). default: Gaussian.
  -p <double list>:  a comma seperated list of the model specific parameters. default: 5 (default Std for Gaussian).
                     expected parameters for Gaussian: Std.

  -tmp <str>:        name for tmp output file of the matlab sampling run (this file is removed after it is used).
                     if you run parallel processes that use chr_perturbate.pl you should set the 'tmp' name
                     to be different for each process, else they will collide...
