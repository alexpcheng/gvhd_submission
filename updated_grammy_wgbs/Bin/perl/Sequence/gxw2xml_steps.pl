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

my $file = $ARGV[0];

my %args = load_args(\@ARGV);
my $step_size = get_arg("s", 1, \%args);
my $method = get_arg("m", "Simplex", \%args);

my $names_and_lengths = `perl $ENV{PERL_HOME}/Sequence/gxw2consensus.pl $file | perl $ENV{PERL_HOME}/Sequence/stab2length.pl`;

my @lines = split /\n/,$names_and_lengths;

my $num_elements = scalar(@lines);


for (my $i = 0; $i < $num_elements; $i++)
{
  my @row = split /\t/, $lines[$i]; 
 
  for (my $j = 0; $j < $row[1]; $j++)
  {
      print STDOUT "
         <Step Type=\"LoadSequenceModelStep\"
               Name=\"Training\"
               StepType=\"GeneralParameters\"
               ParameterStepSize=\"$step_size\"
               TrainingProcedureType=\"$method\">
	       <GeneralTrainingParameters
                       ParameterType=\"ScalingParameter\"
                       WeightMatrix1=\"$row[0]\">
	       </GeneralTrainingParameters>
	       <GeneralTrainingParameters
                       ParameterType=\"CooperativityParameter\"
                       WeightMatrix1=\"$row[0]\"
                       WeightMatrix2=\"$row[0]\">\
	       </GeneralTrainingParameters>		    
	       <GeneralTrainingParameters
                       ParameterType=\"LogisticParameter\"
                       WeightMatrix1=\"$row[0]\">
	       </GeneralTrainingParameters>
                <GeneralTrainingParameters
                       ParameterType=\"WeightMatrixParameters\"
                       WeightMatrix1=\"$row[0]\"
                       WeightMatrixPositionToLearn=\"$j\">
	       </GeneralTrainingParameters>
         </Step>\n";
  }
}


__DATA__

gxw2xml_steps.pl <gxw file>

   Creates map_learn xml steps for each weight matrix assuming PSSMs

   -s <str>:   step size for simplex method (default: 1.0)

   -m <num>:   Training method (ConjugateGradient/Simplex)  (default: `Simplex`)
