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

my $tmpfile="tmp_svm_train_data_".int(rand(10000000));

if ($outfile eq ""){die ("output file not specified\n")}

open (IL,$labels) or die ("cant open label file $labels\n");
open (ID,$data) or die ("cant open data file $data\n");
open (TMP,">$tmpfile");
while(my $data_line=<ID>){
  my $label_line = <IL>;
  chomp $label_line;
  chomp $data_line;
  print TMP "$label_line";
  my @data_vector=split /\t/,$data_line;
  for (my $i=0;$i<scalar(@data_vector);$i++){
    print TMP " ",$i+1,":",$data_vector[$i];
  }
  print TMP "\n";
}
close (IL);
close (ID);
close(TMP);

if ($_c ne ""){$_c="-c ".$_c}

my $svm_run = "$ENV{GENIE_HOME}/Bin/SVM_light/svm_learn -z $_z -t $_t -d $_d -g $_g -s $_s -r $_r -v $_v $_c $tmpfile $outfile";
if ($_v>0) {print STDERR "running: $svm_run\n" }
my $svm_out = `$svm_run`;
print STDERR $svm_out;

unlink $tmpfile;

__DATA__

svm_train.pl

Train a SVM on a set of labeled vectors. Label files should be a column of
labels ({1,-1} for classification). Data file should consist of row vectors.
This script is a wrapper for SVM-light.

  parameters:

  -v <int>     verbosity (to STDERR) (0-3, 1 default)
  -id <str>    input file containing training data instances
  -il <str>    input file containing training labels
  -o <str>     output file for SVM model
  -z <c,r,p>   select between classification (c), regression (r),
               and preference ranking (p) (default c)
  -c <real>    regularization parameter (default [avg. x*x]^-1)
  -t <0,1,2,3> type of kernel function:
                 0: linear (default)
                 1: polynomial (s a*b+c)^d
                 2: radial basis function exp(-gamma ||x-b||^2)
                 3: sigmoid tanh(s a*b + c)
  -d <int>     parameter d in polynomial kernel (default 3)
  -g <float>   parameter gamma in rbf kernel (default 1)
  -s <float>   parameter s in sigmoid/poly kernel (default 1)
  -r <float>   parameter c in sigmoid/poly kernel (default 1)

