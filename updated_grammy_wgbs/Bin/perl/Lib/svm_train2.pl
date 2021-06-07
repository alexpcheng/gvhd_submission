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
my $data = get_arg("id", "", \%args);
my $labels = get_arg("il", "", \%args);
my $outfile = get_arg("o", "", \%args);
my $_z = get_arg("z", "c", \%args);
my $_t = get_arg("t", 0, \%args);
my $_d = get_arg("d", 3, \%args);
my $_g = get_arg("g", 1, \%args);
my $_s = get_arg("s", 1, \%args);
my $_r = get_arg("r", 1, \%args);
my $_v = get_arg("v", 1, \%args);
my $_c = get_arg("c", "", \%args);
my $_e = get_arg("e", "", \%args);
my $_scale = get_arg("scale", 0, \%args);

if ($_t==0){$_d=1;$_t=1}
$_v++;

my $tmp_train="tmp_svm_train_data_".int(rand(10000000));

if ($outfile eq ""){die ("output file not specified\n")}

open (IL,$labels) or die ("cant open label file $labels\n");
open (ID,$data) or die ("cant open data file $data\n");
open (TMP,">$tmp_train");
while(my $data_line=<ID>){
  my $label_line = <IL>;
  chomp $label_line;
  chomp $data_line;
  print TMP "$label_line\t$data_line\n";
}
close (IL);
close (ID);
close(TMP);

my $tmp_params="tmp_svm_params_".int(rand(10000000));
my $params="";

$params.="\@parameters\n";
if ($_z eq "r"){$params.="regression\n"}else{$params.="pattern\n"}
if($_c ne ""){$params.="C $_c\n";}
if ($_scale){$params.="scale\n"}else{$params.="no_scale\n"}
$params.= "verbosity $_v\n";
if($_e ne ""){$params.= "epsilon $_e\n";}
$params.="\@kernel\ntype ";
if($_t==1){
  $params.="polynomial\n";
  $params.="degree $_d\n";
}
elsif($_t==2){
  $params.="radial\n";
  $params.="gamma $_g\n";
}
elsif($_t==3){
  $params.="neural\n";
  $params.="a $_s\nb $_r\n";
}
my $tmp_params="tmp_svm_params_".int(rand(10000000));
open (TMP,">$tmp_params");
print TMP $params;
close(TMP);


my $svm_run = "$ENV{GENIE_HOME}/Bin/mySVM/bin/Linux/mysvm $tmp_params $tmp_train";
if ($_v>0) {print STDERR "running: $svm_run\n" }
my $svm_out = `$svm_run`;
print STDERR $svm_out;

`cat $tmp_params $tmp_train.svm > $outfile`;

`rm $tmp_train $tmp_params $tmp_train.svm`;

__DATA__

svm_train2.pl

Train a SVM on a set of labeled vectors. Label files should be a column of
labels ({1,-1} for classification). Data file should consist of row vectors.
This script is a wrapper for mySVM.

  parameters:

  -v <int>     verbosity (to STDERR) (0-3, 1 default)
  -id <str>    input file containing training data instances
  -il <str>    input file containing training labels
  -o <str>     output file for SVM model
  -z <c,r>   select between classification (c) and regression (r) (default c)
  -c <real>    regularization parameter (default 1)
  -t <0,1,2,3> type of kernel function:
                 0: linear (default)
                 1: polynomial (a*b)^d
                 2: radial basis function exp(-gamma ||x-b||^2)
                 3: sigmoid tanh(s a*b+c)
  -d <int>     parameter d in polynomial kernel (default 3)
  -g <float>   parameter gamma in rbf kernel (default 1)
  -s <float>   parameter s in sigmoid kernel (default 1)
  -r <float>   parameter c in sigmoid kernel (default 1)
  -scale       scale data to mean 0 and variance 1 (recommended)
  -e <real>    insensitivity constant. No loss if prediction lies this close
               to true value


