#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $data_col = get_arg("c", 0, \%args);
my $freq_col = get_arg("f", "", \%args);
my $distribution = get_arg("t", "Normal", \%args);
my $trials = get_arg("n", "", \%args);
my $debug = get_arg("debug", "", \%args);

my $tmp_file = "tmp_fit_distribution_".int(rand(100000000)).".tab";

open(TMP,">$tmp_file");
while(<STDIN>){
  chomp;
  my @a=split /\t/;
  print TMP $a[$data_col];
  if ($freq_col ne "") { print TMP "\t",$a[$freq_col]; }
  print TMP "\n";
}
close (TMP);

my $command = "d=load('$tmp_file'); params=mle(d(:,1), 'distribution', '$distribution'";
if ($freq_col ne "") { $command .= ", 'frequency', d(:,2)" }
if ($trials ne "" and $distribution eq "bionmial") { $command .= ", 'ntrials', $trials" }
$command .= ");save('$tmp_file.results', 'params', '-ascii', '-double', '-tabs' );";

my $matlabPath = "matlab";
my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";

my $debug_output = `$matlabPath -nodesktop -nojvm -nodisplay -nosplash -r \"path(path,'$matlabDev');$command exit;\"`;
if($debug ne ""){print STDERR "$debug_output\n"}

unlink $tmp_file;

open(TMP,"$tmp_file.results");
while(<TMP>){
  chomp;
  my @a=split /\s+/;
  shift @a;
  print join("\t",@a),"\n";
}
close(TMP);

unlink "$tmp_file.results";

__DATA__


fit_distribution.pl

Given a file containing data (indices+frequencies or data instances), fits a
specified distribution to the data using maximum likelihood estimation.
returns parameters for fitted distribution
Wrapper for matlab mle().

  -c <int>       column containing data instances/indices (default: 0)
  -f <int>       column of frequencies for the indices (default: off, use data instances)
  -t <str>       distribution type (Beta/Bernoulli/Binomial/Discrete uniform/Exponential/
    	         Extreme value/Gamma/Geometric/Log normal/Negative binomial/Normal/
		 Poisson/Rayleigh/Uniform/Weibull) (default: Normal)
  -n <int>       number of trials (for binomial distribution only)

  -debug         show matlab session output


