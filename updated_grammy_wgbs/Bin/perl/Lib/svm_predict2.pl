#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

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
my $data = get_arg("i", "", \%args);
my $model = get_arg("m", "", \%args);
my $_v = get_arg("v", "", \%args);
my $binary = get_arg("b", "", \%args);
my $skip = get_arg("skip", 0, \%args);
my $skipc = get_arg("skipc", 0, \%args);

my $tmp_predict="tmp_svm_predict_data_".int(rand(10000000));

if ($model eq "") { die ("model file required!\n") }

open (DATA,$data) or die ("cant open data file $data\n");
open (TMP,">$tmp_predict");
print TMP "\@examples\nformat x\n";

my @header_cols;
for (my $i=0;$i<$skip;$i++){ <DATA> }

my $j=0;
while(my $data_line=<DATA>){
  chomp $data_line;
  my @data_vector=split /\t/,$data_line;
  for (my $i=0;$i<$skipc;$i++){ $header_cols[$j][$i]=shift @data_vector }
  print TMP join("\t",@data_vector),"\n";
  $j++;
}

close (DATA);
close(TMP);

my $tmp_model="tmp_svm_model_".int(rand(10000000));
my $tmp_params="tmp_svm_params_".int(rand(10000000));
open(INMOD,$model);
open(PARAM,">$tmp_params");
open(MODEL,">$tmp_model");
my $in_model=0;
while(my $line=<INMOD>){
  if($line=~/svm example set/){$in_model=1};
  if($in_model==1){
    print MODEL $line;
  }
  else{
    print PARAM $line;
  }
}
close(INMOD);
close(PARAM);
close(MODEL);

my $svm_out = `$ENV{GENIE_HOME}/Bin/mySVM/bin/Linux/predict $tmp_params $tmp_model $tmp_predict`;
if ($_v){print STDERR $svm_out;}


open (TMP,"$tmp_predict.pred");
<TMP>;
$j=0;
while(my $p=<TMP>){
  chomp $p;
  if($binary ne "" and $p>=$binary){$p=1}
  elsif($binary ne "" and $p<$binary){$p=-1}
  for (my $i=0;$i<$skipc;$i++){ print $header_cols[$j][$i],"\t" }
  print $p,"\n";
  $j++;
}
close(TMP);

`rm $tmp_predict $tmp_params $tmp_model $tmp_predict.pred`;



__DATA__

svm_predict2.pl

Use a SVM model (trained by svm_train2.pl) to perform predictions. Input file
should contain data instances as row vectors.
This script is a wrapper for mySVM.

  parameters:

  -v           verbosity on (otherwise silent)
  -i <str>     input file containing data instances
  -m <str>     input file containing SVM model
  -b <real>    binary label output using value as threshold
  -skip <num>  number of header rows to skip in data file (default 0)
  -skipc <num> number of header columns to skip in data file (default 0)

