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
my $_v = get_arg("v", 1, \%args);
my $binary = get_arg("b", "", \%args);
my $skip = get_arg("skip", 0, \%args);
my $skipc = get_arg("skipc", 0, \%args);

my $tmpfile="tmp_svm_predict_data_".int(rand(10000000));
my $tmpfile2="tmp_svm_predict_output_".int(rand(10000000));

if ($model eq "") { die ("model file required!\n") }

open (DATA,$data) or die ("cant open data file $data\n");
open (TMP,">$tmpfile");

my @header_cols;
for (my $i=0;$i<$skip;$i++){ <DATA> }

my $j=0;
while(my $data_line=<DATA>){
  chomp $data_line;
  my @data_vector=split /\t/,$data_line;
  for (my $i=0;$i<$skipc;$i++){ $header_cols[$j][$i]=$data_vector[$i] }
  print TMP "0";
  for (my $i=$skipc;$i<scalar(@data_vector);$i++){
    print TMP " ",$i-$skipc+1,":",$data_vector[$i];
  }
  print TMP "\n";
  $j++;
}

close (DATA);
close(TMP);

my $svm_out = `$ENV{GENIE_HOME}/Bin/SVM_light/svm_classify -v $_v $tmpfile $model $tmpfile2`;
print STDERR $svm_out;

unlink $tmpfile;

open (TMP,"$tmpfile2");
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

unlink $tmpfile2;

__DATA__

svm_predict.pl

Use a SVM model (trained by svm_train.pl) to perform predictions. Input file
should contain data instances as row vectors.
This script is a wrapper for SVM-light.

  parameters:

  -v <int>     verbosity (to STDERR) (0-3, 1 default)
  -i <str>     input file containing data instances
  -m <str>     input file containing SVM model
  -b <real>    binary label output using value as threshold
  -skip <num>  number of header rows to skip in data file (default 0)
  -skipc <num> number of header columns to skip in data file (default 0)

