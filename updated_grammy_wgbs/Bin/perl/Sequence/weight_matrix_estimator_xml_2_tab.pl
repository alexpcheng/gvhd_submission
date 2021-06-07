#! /usr/bin/perl 

use strict;
use XML::Parser;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";
require "$ENV{PERL_HOME}/Lib/c_bio_tokens_2_hash.pl";
require "$ENV{PERL_HOME}/Lib/xml_util.pl";


sub estimator_map_2_tab_str
{
  if (length(@_[0]) == 0 or @_[0] eq "--help")
  {
    print "Usage: weight_matrix_estimator_xml_2_tab_str.pl in_file.txt extract estimator properties from xml to tab delimeted string \n\n";
  }

  my ($xml_file_name) = @_;

  my $bio_tokens_hash_ptr = &get_bio_tokens_hash();
  my %bio_tokens_hash = %$bio_tokens_hash_ptr;

  my $parser = new XML::Parser(Style => 'Tree');
  my $tree = $parser->parsefile($xml_file_name);
  
  #use Data::Dumper;
  #print Dumper($tree);

  my @tree_array = @$tree;
  my $tree_name = $tree_array[0];
  if ($tree_name ne $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_TOKEN'})
  {
      die "file is not a estimator xml according to first tag";
  }

   #print $tree_name ."\n";

   my $estimator_arr_ptr = $tree_array[1];
   my @estimator_arr = @$estimator_arr_ptr;
   my $prop_hash_ptr = $estimator_arr[0];
   #print $prop_hash_ptr . "\n";
   my %prop_hash = %$prop_hash_ptr;
   
   my $tab = "\t";
   my $endl = "\n";
   my $header_str = "";
   my $values_str = "";

   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_ITERATION_NUM_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_ITERATION_NUM_TOKEN'}} . $tab;

   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MODEL_SCORE_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MODEL_SCORE_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_NUM_OF_FEATURES_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_NUM_OF_FEATURES_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_USE_ONLY_NEGATIVE_WEIGHTS_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_USE_ONLY_NEGATIVE_WEIGHTS_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_POSFRACTION_CORREC_FACTOR_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_POSFRACTION_CORREC_FACTOR_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_POSITIONS_NUM_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_POSITIONS_NUM_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_INIT_COUNT_PERCENT_THRESH_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_INIT_COUNT_PERCENT_THRESH_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_INIT_PVALUE_THRESH_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_INIT_PVALUE_THRESH_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_FEATURES_PARAMS_NUM_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_FEATURES_PARAMS_NUM_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_ITERATION_NUM_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_MAX_ITERATION_NUM_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_WEIGHT_START_POINT_STRATEGY_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_WEIGHT_START_POINT_STRATEGY_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_USE_REVERSE_COMPLEMENT_TOKEN'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_USE_REVERSE_COMPLEMENT_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'FEATURE_LEARN_OUTPUT_SUM_WEIGHTS_PENALTY_COEFFICIENT'} . $tab;
   my $values_str = $values_str . $prop_hash{$bio_tokens_hash{'FEATURE_LEARN_OUTPUT_SUM_WEIGHTS_PENALTY_COEFFICIENT'}} . $tab;
   
   #print $header_str . "\n";
   #print $values_str . "\n";
   
   
   my @estimator_arr = @$estimator_arr_ptr;
   my $train_name = $estimator_arr[3];
   #print $train_name. "\n";
   
   if ($train_name ne $bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_TOKEN'})
   {
       die "estimator xml: file format not including train params (missing tag) $bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_TOKEN'}";
   }
   
   
   my $train_arr_ptr = $estimator_arr[4];
   my @train_arr = @$train_arr_ptr;
   my $train_prop_hash_ptr = $train_arr[0];
   #print $train_prop_hash_ptr . "\n";
   my %train_prop_hash = %$train_prop_hash_ptr;
   
   my $header_str = $header_str . $bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_INITIAL_STEP_SIZE_TOKEN'} . $tab;
   my $values_str = $values_str . $train_prop_hash{$bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_INITIAL_STEP_SIZE_TOKEN'}} . $tab;
   
   
   my $header_str = $header_str . $bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_TOLERANCE_TOKEN'} . $tab;
   my $values_str = $values_str . $train_prop_hash{$bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_TOLERANCE_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_MAX_TRAIN_ITERATIONS_TOKEN'} . $tab;
   my $values_str = $values_str . $train_prop_hash{$bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_MAX_TRAIN_ITERATIONS_TOKEN'}} . $tab;
   
   my $header_str = $header_str . $bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_NOTIFY_ITER_COMP_TOKEN'} . $tab;
   my $values_str = $values_str . $train_prop_hash{$bio_tokens_hash{'TRAINING_PROCEDURE_PARAMS_NOTIFY_ITER_COMP_TOKEN'}} . $tab;
   
   #print $header_str . "\n";
   #print $values_str . "\n";

   return ($header_str . $endl . $values_str );


}


#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
#if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
#{
#  my $ret_str = &estimator_map_2_tab_str($ARGV[0]);
#  print $ret_str;
#}
#else
#{
#  print "Usage: weight_matrix_estimator_xml_2_tab_str.pl in_file.txt extract estimator properties from xml to tab delimeted string \n\n";
#}
