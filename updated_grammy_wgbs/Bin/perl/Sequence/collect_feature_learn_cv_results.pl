#! /usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";
require "$ENV{PERL_HOME}/Sequence/weight_matrix_estimator_xml_2_tab.pl";

my $OUT_LEARN = "Out_LearnWeightMatrix.txt";
my $OUT_LEARN_ESTIMATOR = "Out_LearnWeightMatrix_Estimator.txt";
my $OUT_LIKELIHOOD_TRAIN = "Out_Likelihhod_train.txt";
my $OUT_LIKELIHOOD_TEST = "Out_Likelihhod_test.txt";
my $LIKELIHOOD_TEST = "LogLikelihood_test";
my $LIKELIHOOD_TRAIN = "LogLikelihood_train";
#----------------------------------------------------------------
# 
#----------------------------------------------------------------
sub collect_feature_learn_cv_results_from_directories
{
  my ($dir_prefix, $append, $group_num, $out_file_name) = @_;

  #print $dir_prefix . "\n";
  #print $append . "\n";
  #print $group_num . "\n";
  #print $out_file_name . "\n";

  if ($append == 0)
  {
    open(OUTFILE, ">$out_file_name") or die "could not open  $out_file_name\n";
  }
  else
  {
    open(OUTFILE, ">>$out_file_name") or die "could not open  $out_file_name\n";
  }
  
  for (my $i = 0 ; $i < $group_num ; ++$i)
  { 
    my $dir_name = $dir_prefix . $i . "/";

    open(INTFILE_TRAIN, "<" . $dir_name . $OUT_LIKELIHOOD_TRAIN) or die "could not open $dir_name$OUT_LIKELIHOOD_TRAIN\n";
    open(INTFILE_TEST, "<" . $dir_name . $OUT_LIKELIHOOD_TEST) or die "could not open $dir_name$OUT_LIKELIHOOD_TEST\n";

    my $line_train = <INTFILE_TRAIN>;
    my $line_test = <INTFILE_TEST>;

    close(INTFILE_TRAIN);
    close(INTFILE_TEST);
    
    chomp($line_train);
    chomp($line_test);

    $line_train =~ s/#sequences_log_likelihood://;
    $line_test =~ s/#sequences_log_likelihood://;

    my $log_likelihood_test = scalar($line_test);
    my $log_likelihood_train = scalar($line_train);

    my $estimator_strs =  &estimator_map_2_tab_str($dir_name . $OUT_LEARN_ESTIMATOR);

    $estimator_strs =~ m/(.*)\n(.*)/;
    my $header_line = $1;
    #print $1;
    my $vals_line = $2;

    $header_line = $LIKELIHOOD_TEST . "\t" . $LIKELIHOOD_TRAIN ."\t" . $header_line;
    $vals_line = $log_likelihood_test. "\t" . $log_likelihood_train . "\t" . $vals_line;

    if ($append == 0 && $i == 0)
    {
      print OUTFILE $header_line ."\n";
    }
    print OUTFILE $vals_line ."\n";
  }

  close(OUTFILE);
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
{
  my %args = load_args(\@ARGV);

  collect_feature_learn_cv_results_from_directories($ARGV[0],
						    get_arg("a", 0, \%args),
						    get_arg("g", 5, \%args),
						    get_arg("o", "cv_out.txt", \%args),
						   );
}
else
{
  print "Usage: collect_feature_learn_cv_results.pl output_directories_prefix \n\n";
  print "      -a < 1=append 0=create new file>: append to existing file (0 or 1, defualt 0=create new file\n";
  print "      -g <cv number>:   number of cross validation groups to collect results (default 5)\n\n";
  print "      -o <out file name>:   out_file name (defualt cv_out.txt)\n\n";
}
