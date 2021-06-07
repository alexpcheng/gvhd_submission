#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA>;
   exit;
}

my %args = load_args(\@ARGV);
my $column = get_arg("c", 0, \%args);

my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";

my $matlabPath = "matlab";
my $tmpname = "tmp_fft_".int(rand(1000000000));

open(TMP,">$tmpname.tab");
while(<STDIN>){
  chomp;
  my @line=split /\t/;
  print TMP $line[$column],"\n";
}
close (TMP);

my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev');x=load('$tmpname.tab');y=fft(x);n=length(y);y(1)=[];p=abs(y(1:n/2).^2);f=(1:n/2)/n;matrix2tab([f' p],'$tmpname.out');exit;\" > /dev/null";


while(system($command) != 0)  { sleep(10) }


print `sort.pl -c0 0 -n0 < $tmpname.out`;

unlink "$tmpname.out";
unlink "$tmpname.tab";


__DATA__

fft.pl

Fast Fourier Transform (Matlab wrapper).
Output:  1st column - frequency
         2nd column - power


 -c <num>         column number (default 0)


