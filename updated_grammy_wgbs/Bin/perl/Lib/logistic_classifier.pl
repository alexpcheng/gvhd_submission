#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $positive_features_file = get_arg("p", "", \%args);
my $negative_features_file = get_arg("n", "", \%args);
my $num_cross_validation_folds = get_arg("f", 5, \%args);
my $model_file_output = get_arg("m", "", \%args);

my %feature2id;
my @id2feature;
my $num_features = 1;

my $r = int(rand(100000));
open(OUTFILE, ">tmp_$r");
&WriteTrainFile($positive_features_file, 1);
&WriteTrainFile($negative_features_file, -1);
close(OUTFILE);

system("rm -f tmp_${r}_full_res;");
if (length($model_file_output) > 0)
{
    system("rm -f $model_file_output;");

    open(MODEL_OUTFILE, ">tmp_${r}_model_outfile");
}

if ($num_cross_validation_folds > 1)
{
  `make_cross_validation_sets.pl tmp_$r -g $num_cross_validation_folds;`;

  for (my $i = 1; $i <= $num_cross_validation_folds; $i++)
  {
    my $exec_str = "cut -f2- tmp_${r}_train_$i > tmp_${r}_train; ";
    $exec_str   .= "cut -f2- tmp_${r}_test_$i > tmp_${r}_test; ";

    &Train($exec_str, "tmp_${r}_test_$i", $i);
  }
}
elsif ($num_cross_validation_folds == 1)
{
  my $exec_str = "cut -f2- tmp_${r} > tmp_${r}_train; ";
  $exec_str   .= "cut -f2- tmp_${r} > tmp_${r}_test; ";
  $exec_str   .= "cat      tmp_${r} > tmp_${r}_test_1; ";

  &Train($exec_str, "tmp_${r}_test_1", 1);
}
elsif ($num_cross_validation_folds == -1)
{
  my $num_lines = `wc -l tmp_$r | cut -f 1 -d ' '`;
  chomp $num_lines;

  print STDERR "Leave one out cross validation for $num_lines instances\n";

  for (my $i = 1; $i <= $num_lines; $i++)
  {
    my $before_test = $i - 1;
    my $after_test = $i + 1;
    my $exec_str = "cut -f2- tmp_${r} | body.pl 1           $before_test > tmp_${r}_train; ";
    $exec_str   .= "cut -f2- tmp_${r} | body.pl $after_test -1           >> tmp_${r}_train; ";
    $exec_str   .= "cut -f2- tmp_${r} | body.pl $i          $i           > tmp_${r}_test; ";
    $exec_str   .= "cat      tmp_${r} | body.pl $i          $i           > tmp_${r}_test_$i; ";

    &Train($exec_str, "tmp_${r}_test_$i", $i);
  }
}

if (length($model_file_output) > 0)
{
    close(MODEL_OUTFILE);

    system("list2tab.pl tmp_${r}_model_outfile -V 2 > $model_file_output;");
}

my $num_correct = 0;
my $num_incorrect = 0;
open(FILE, "<tmp_${r}_full_res");
while(<FILE>)
{
    my @row = split(/\t/);

    if ($row[4] == 1) { $num_correct++; }
    else { $num_incorrect++; }
}
close(FILE);
print STDERR "Right\t$num_correct\t" . &format_number($num_correct / ($num_correct + $num_incorrect), 3) . "\n";
print STDERR "Wrong\t$num_incorrect\t" . &format_number($num_incorrect / ($num_correct + $num_incorrect), 3) . "\n";

print "Right\t$num_correct\t" . &format_number($num_correct / ($num_correct + $num_incorrect), 3) . "\n";
print "Wrong\t$num_incorrect\t" . &format_number($num_incorrect / ($num_correct + $num_incorrect), 3) . "\n";
system("cat tmp_${r}_full_res");
#system("rm tmp_$r*");

#-----------------------------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------------------------
sub Train ()
{
  my ($exec_str, $test_file, $train_iteration) = @_;

  $exec_str   .= "$ENV{BIN_HOME}/LogisticRegression/bin/BBRtrain ";
  $exec_str   .= "-p 1 ";
  $exec_str   .= "-t 1 ";
  $exec_str   .= "tmp_${r}_train tmp_${r}_model >& /dev/null; ";

  $exec_str   .= "$ENV{BIN_HOME}/LogisticRegression/bin/BBRclassify ";
  $exec_str   .= "-r tmp_${r}_res ";
  $exec_str   .= "tmp_${r}_test tmp_${r}_model >& /dev/null; ";

  $exec_str   .= "cut -f 1 -d ' ' $test_file ";
  $exec_str   .= "| paste - tmp_${r}_res ";
  $exec_str   .= "| sed 's/ /	/g' ";
  $exec_str   .= "| cut.pl -f 1,2,4,3 ";
  $exec_str   .= "| perl -e 'while(<STDIN>){chop;\@r=split(/\t/);\$p=\$r[1]==\$r[2]?1:0;print\"\$_\t\$p\n\";}' ";
  $exec_str   .= ">> tmp_${r}_full_res; ";

  print STDERR "Training model $train_iteration...\n";
  #print STDERR "$exec_str\n";
  `$exec_str`;

  if (length($model_file_output) > 0)
  {
    &ProcessModelOutput("tmp_${r}_model", $train_iteration);
  }
}

#-----------------------------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------------------------
sub WriteTrainFile
{
    my ($file, $label) = @_;

    open(FILE, "<$file") or die "Could not open label $label file $file\n";

    my $header_str = <FILE>;
    chomp $header_str;
    my @header = split(/\t/, $header_str);
    for (my $i = 1; $i < @header; $i++)
    {
	if (length($feature2id{$header[$i]}) == 0)
	{
	    $feature2id{$header[$i]} = $num_features;
	    $id2feature[$num_features] = $header[$i];
	    $num_features++;
	}
    }

    while(<FILE>)
    {
	chop;
	
	my @row = split(/\t/);

	print OUTFILE "$row[0]\t$label";

	for (my $i = 1; $i < @row; $i++)
	{
	    if (length($row[$i]) > 0)
	    {
		print OUTFILE " $feature2id{$header[$i]}:$row[$i]";
	    }
	}

	print OUTFILE "\n";
    }

    close(FILE);
}

#-----------------------------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------------------------
sub ProcessModelOutput
{
    my ($file, $model_id) = @_;

    my @used_features;

    open(MODEL, "<$file");
    while(<MODEL>)
    {
	chop;

	if (/^topicFeats/)
	{
	    my @row = split(/ /);

	    for (my $i = 1; $i < @row; $i++)
	    {
	      $used_features[$i] = $id2feature[$row[$i]];
	      #print STDERR "F=$row[$i] [$id2feature[$row[$i]]]\n";
	    }
	}
	elsif (/^beta/)
	{
	    my @row = split(/ /);

	    for (my $i = 1; $i < @row; $i++)
	    {
		my $num = 0 + $row[$i];

		if ($num != 0)
		{
		  print MODEL_OUTFILE "$used_features[$i]\tModel$model_id\t" . &format_number($num, 3) , "\n";
		  #print STDERR "R=$row[$i]\n";
		}
	    }
	}
	elsif (/^threshold ([^ ]+)/)
	{
	  print MODEL_OUTFILE "threshold\tModel$model_id\t" . &format_number($1, 3) , "\n";
	}
    }
}

__DATA__

logistic_classifier.pl

   Takes in two tab delimited files containing sets of features
   where one file is the positive examples and the other is for the 
   negative examples.

   -p <str>: Positive features file (format: tab-delimited, one header column and row)
   -n <str>: Negative features file (format: tab-delimited, one header column and row)

   -f <num>: Number of folds for the cross validation (default: 5)
             Note: Use "-1" for leave one out, "1" for doing only training (test on training data)

   -m <str>: Model file output

